//
//  TriviaSettingsView.swift
//  HereNyang
//
//  "알림냥" 탭. 상식/유머 알림을 켜고 끈다. 시간은 취침시간(23시~8시)을 뺀 나머지
//  시간대에 1~4시간 랜덤 간격으로 자동으로 잡힌다(TriviaNotificationScheduler).
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
                    Toggle("상식/유머 알림", isOn: Binding(
                        get: { store.isEnabled },
                        set: { store.isEnabled = $0 }
                    ))
                } header: {
                    Text("상식/유머")
                } footer: {
                    // SwiftUI Text(String)는 마크다운으로 파싱돼서, "~"가 두 번 들어간 문장은
                    // 그 사이 구간이 취소선(GFM 문법)으로 잘못 렌더링된다. Text(verbatim:)로 우회.
                    Text(verbatim: store.isEnabled ? "상식과 유머를 내마음대로 말한다냥." : "꺼두면 조용히 있는다냥.")
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

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.body = TriviaCatalog.facts.randomElement() ?? "상식을 준비하지 못했다냥."
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
