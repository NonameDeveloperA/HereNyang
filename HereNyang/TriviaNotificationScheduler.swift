//
//  TriviaNotificationScheduler.swift
//  HereNyang
//
//  TriviaSettingsStore의 설정대로 로컬 알림을 예약한다. 로컬 알림은 예약 시점에 내용이
//  고정되기 때문에("매번 다른 상식"을 실시간으로 만들 수 없기 때문에), 앞으로 며칠치를
//  미리 예약해두고 앱이 켜질 때마다 모자란 만큼 다시 채워 넣는(top-up) 방식을 쓴다.
//

import Foundation
import UserNotifications

@MainActor
enum TriviaNotificationScheduler {
    // iOS는 앱당 대기 중인 로컬 알림을 최대 64개까지만 허용해서, 여유 있게 7일치만 예약한다.
    private static let daysAhead = 7
    private static let identifierPrefix = "trivia-"

    static func reschedule() {
        let center = UNUserNotificationCenter.current()
        let settings = TriviaSettingsStore.shared.settings

        center.getPendingNotificationRequests { requests in
            let staleIDs = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)

            guard !TriviaCatalog.facts.isEmpty else { return }

            let calendar = Calendar.current
            let now = Date()
            var factIndex = Int.random(in: 0..<TriviaCatalog.facts.count)

            for dayOffset in 0..<daysAhead {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

                for slot in TriviaSlot.allCases {
                    guard let setting = settings[slot], setting.isEnabled else { continue }

                    var comps = calendar.dateComponents([.year, .month, .day], from: day)
                    comps.hour = setting.hour
                    comps.minute = setting.minute
                    comps.second = 0

                    guard let fireDate = calendar.date(from: comps), fireDate > now else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = "\(slot.displayName) 상식"
                    content.body = TriviaCatalog.facts[factIndex % TriviaCatalog.facts.count]
                    content.sound = .default
                    factIndex += 1

                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "\(identifierPrefix)\(slot.rawValue)-\(dayOffset)",
                        content: content,
                        trigger: trigger
                    )
                    center.add(request) { error in
                        if let error {
                            print("상식 알림 예약 실패: \(error)")
                        }
                    }
                }
            }
        }
    }
}
