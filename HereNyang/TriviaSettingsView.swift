//
//  TriviaSettingsView.swift
//  HereNyang
//
//  "알림냥" 탭. 아침/점심/저녁 상식 알림을 켜고 끄고 시간을 정한다.
//

import SwiftUI
import UserNotifications

struct TriviaSettingsView: View {
    @ObservedObject private var store = TriviaSettingsStore.shared
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                Section("알림 권한") {
                    LabeledContent("알림 권한", value: authorizationStatusText)
                    if authorizationStatus == .notDetermined {
                        Button("알림 권한 요청") {
                            NotificationManager.shared.requestAuthorization()
                            refreshAuthorizationStatus()
                        }
                    } else if authorizationStatus == .denied {
                        Button("설정 앱에서 허용하기") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                Section {
                    ForEach(TriviaSlot.allCases) { slot in
                        let setting = store.setting(for: slot)
                        HStack {
                            // 라벨 폭을 고정해서 "아침/점심/저녁" 글자폭이 달라도 시간 버튼이
                            // 항상 같은 x 위치에서 시작하도록 정렬한다.
                            Text(slot.displayName)
                                .frame(width: 44, alignment: .leading)
                            if setting.isEnabled {
                                DatePicker(
                                    "시간",
                                    selection: timeBinding(for: slot),
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { setting.isEnabled },
                                set: { store.setEnabled($0, for: slot) }
                            ))
                            .labelsHidden()
                            .scaleEffect(0.8)
                        }
                    }
                } header: {
                    Text("상식 알림 (최대 \(TriviaSlot.allCases.count)회/일)")
                } footer: {
                    Text("설정한 시간에 짧은 상식 한 줄을 알림으로 보내드려요. 앞으로 7일치를 미리 예약해두고, 앱을 열 때마다 자동으로 채워 넣어요.")
                }

                Section {
                    Button("지금 알림 테스트 보내기") {
                        sendTestNotification()
                    }
                }
            }
            .navigationTitle("알림냥")
        }
        .task {
            refreshAuthorizationStatus()
        }
        .onChange(of: authorizationStatus) { _, _ in
            TriviaNotificationScheduler.reschedule()
        }
    }

    private func timeBinding(for slot: TriviaSlot) -> Binding<Date> {
        Binding(
            get: {
                let setting = store.setting(for: slot)
                var comps = DateComponents()
                comps.hour = setting.hour
                comps.minute = setting.minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                store.setTime(hour: comps.hour ?? 0, minute: comps.minute ?? 0, for: slot)
            }
        )
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "상식 알림 미리보기"
        content.body = TriviaCatalog.facts.randomElement() ?? "상식을 준비하지 못했어요."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "trivia-preview-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                authorizationStatus = settings.authorizationStatus
            }
        }
    }

    private var authorizationStatusText: String {
        switch authorizationStatus {
        case .notDetermined: return "요청 전"
        case .denied: return "거부됨"
        case .authorized: return "허용됨"
        case .provisional: return "임시 허용"
        case .ephemeral: return "일회성 허용"
        @unknown default: return "알 수 없음"
        }
    }
}

#Preview {
    TriviaSettingsView()
}
