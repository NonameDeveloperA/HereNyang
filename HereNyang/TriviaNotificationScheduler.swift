//
//  TriviaNotificationScheduler.swift
//  HereNyang
//
//  TriviaSettingsStore의 on/off 설정대로 로컬 알림을 예약한다. 로컬 알림은 예약 시점에
//  내용이 고정되기 때문에("매번 다른 상식/유머"를 실시간으로 만들 수 없기 때문에),
//  앞으로 여러 개를 미리 예약해두고 앱이 켜질 때마다 다시 채워 넣는(top-up) 방식을 쓴다.
//  취침시간(23시~8시)은 건너뛰고, 그 사이 시간대는 1~4시간 랜덤 간격으로 울린다.
//

import Foundation
import UserNotifications

@MainActor
enum TriviaNotificationScheduler {
    // iOS는 앱당 대기 중인 로컬 알림을 최대 64개까지만 허용해서, 여유 있게 60개까지만 예약한다.
    private static let maxScheduled = 60
    // 위 개수 제한에 안 걸리는 드문 경우(간격이 계속 4시간에 가깝게만 나오는 등)를 대비한 안전판.
    private static let maxDaysAhead = 30
    private static let wakeHour = 8
    private static let sleepHour = 23
    private static let identifierPrefix = "trivia-"

    static func reschedule() {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            let staleIDs = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)

            guard TriviaSettingsStore.shared.isEnabled, !TriviaCatalog.facts.isEmpty else { return }

            let calendar = Calendar.current
            let now = Date()
            guard let horizon = calendar.date(byAdding: .day, value: maxDaysAhead, to: now) else { return }

            var factIndex = Int.random(in: 0..<TriviaCatalog.facts.count)
            let firstGap = TimeInterval(Int.random(in: 1...4) * 3600)
            var fireDate = nextWakingDate(after: now.addingTimeInterval(firstGap), calendar: calendar)
            var scheduledCount = 0

            while scheduledCount < maxScheduled, fireDate < horizon {
                let content = UNMutableNotificationContent()
                content.body = TriviaCatalog.facts[factIndex % TriviaCatalog.facts.count]
                content.sound = .default
                factIndex += 1

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate),
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: "\(identifierPrefix)\(scheduledCount)",
                    content: content,
                    trigger: trigger
                )
                center.add(request) { error in
                    if let error {
                        print("상식/유머 알림 예약 실패: \(error)")
                    }
                }
                scheduledCount += 1

                let gap = TimeInterval(Int.random(in: 1...4) * 3600)
                fireDate = nextWakingDate(after: fireDate.addingTimeInterval(gap), calendar: calendar)
            }
        }
    }

    // 취침시간(23시~8시) 안에 걸리면, 그날 남은 취침시간이면 당일 기상 시각으로,
    // 이미 그날 취침시간에 들어섰으면(23시 이후) 다음날 기상 시각으로 민다.
    private static func nextWakingDate(after date: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: date)
        guard hour < wakeHour || hour >= sleepHour else { return date }

        let baseDay = hour >= sleepHour
            ? (calendar.date(byAdding: .day, value: 1, to: date) ?? date)
            : date
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDay)
        comps.hour = wakeHour
        comps.minute = Int.random(in: 0..<60)
        comps.second = 0
        return calendar.date(from: comps) ?? date
    }
}
