//
//  TriviaSettingsStore.swift
//  HereNyang
//
//  "알림냥" 탭에서 상식/유머 알림을 켜고 끄는 설정 저장소. 시간대는 더 이상 사용자가
//  직접 정하지 않고, TriviaNotificationScheduler가 취침시간을 피해 알아서 랜덤하게 잡는다.
//

import Foundation

@MainActor
final class TriviaSettingsStore: ObservableObject {
    static let shared = TriviaSettingsStore()

    @Published var isEnabled: Bool {
        didSet {
            save()
            TriviaNotificationScheduler.reschedule()
        }
    }

    private static let defaultsKey = "triviaEnabled"

    private init() {
        if UserDefaults.standard.object(forKey: Self.defaultsKey) != nil {
            isEnabled = UserDefaults.standard.bool(forKey: Self.defaultsKey)
        } else {
            // 처음 켜는 사람이 부담 없이 시작하도록 기본은 켜둔다.
            isEnabled = true
        }
    }

    private func save() {
        UserDefaults.standard.set(isEnabled, forKey: Self.defaultsKey)
    }
}
