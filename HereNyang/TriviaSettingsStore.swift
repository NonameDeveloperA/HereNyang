//
//  TriviaSettingsStore.swift
//  HereNyang
//
//  "알림냥" 탭에서 아침/점심/저녁 상식 알림을 켜고 끄고 시간을 정하는 설정 저장소.
//

import Foundation

enum TriviaSlot: String, CaseIterable, Codable, Identifiable {
    case morning
    case lunch
    case evening

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "아침"
        case .lunch: return "점심"
        case .evening: return "저녁"
        }
    }

    var defaultHour: Int {
        switch self {
        case .morning: return 8
        case .lunch: return 12
        case .evening: return 19
        }
    }

    var defaultMinute: Int {
        switch self {
        case .morning: return 0
        case .lunch: return 30
        case .evening: return 0
        }
    }
}

struct TriviaSlotSetting: Codable, Equatable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int

    static func `default`(for slot: TriviaSlot) -> TriviaSlotSetting {
        // 처음 켜는 사람이 부담 없이 시작하도록, 아침/저녁은 기본 켜두고 점심은 꺼둔다.
        TriviaSlotSetting(
            isEnabled: slot != .lunch,
            hour: slot.defaultHour,
            minute: slot.defaultMinute
        )
    }
}

@MainActor
final class TriviaSettingsStore: ObservableObject {
    static let shared = TriviaSettingsStore()

    @Published var settings: [TriviaSlot: TriviaSlotSetting] {
        didSet {
            save()
            TriviaNotificationScheduler.reschedule()
        }
    }

    private static let defaultsKey = "triviaSettings"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([TriviaSlot: TriviaSlotSetting].self, from: data) {
            settings = decoded
        } else {
            settings = Dictionary(uniqueKeysWithValues: TriviaSlot.allCases.map { ($0, .default(for: $0)) })
        }
    }

    func setting(for slot: TriviaSlot) -> TriviaSlotSetting {
        settings[slot] ?? .default(for: slot)
    }

    func setEnabled(_ isEnabled: Bool, for slot: TriviaSlot) {
        var current = setting(for: slot)
        current.isEnabled = isEnabled
        settings[slot] = current
    }

    func setTime(hour: Int, minute: Int, for slot: TriviaSlot) {
        var current = setting(for: slot)
        current.hour = hour
        current.minute = minute
        settings[slot] = current
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
