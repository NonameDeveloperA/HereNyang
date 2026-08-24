//
//  NotificationManager.swift
//  HereNyang
//
//  집/회사 도착·이탈을 로컬 알림으로 보여준다. 서버나 APNs 없이 기기에서 바로 처리하는
//  로컬 알림(local notification)이며, 원격 push가 필요해지면 이 부분만 교체하면 됨.
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("알림 권한 요청 실패: \(error)")
            } else {
                print("알림 권한 요청 결과: \(granted)")
            }
        }
    }

    func sendArrivalNotification(for place: Place, label: String) {
        let content = UNMutableNotificationContent()
        content.title = "위치 알림"
        content.body = "\(label)입니다."
        content.sound = .default

        if let attachment = imageAttachment(for: place) {
            content.attachments = [attachment]
        }

        let request = UNNotificationRequest(
            identifier: "arrival-\(place.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("알림 등록 실패: \(error)")
            }
        }
    }

    // 알림 왼쪽의 작은 아이콘은 iOS에서 앱 아이콘으로 고정이라 바꿀 수 없어서,
    // 대신 펼쳤을 때 보이는 큰 이미지를 집/회사별로 다르게 첨부한다.
    private func imageAttachment(for place: Place) -> UNNotificationAttachment? {
        let resourceName: String
        switch place {
        case .home: resourceName = "HomeIcon"
        case .work: resourceName = "WorkIcon"
        case .away, .unknown: return nil
        }

        guard let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: "png") else {
            return nil
        }

        // UNNotificationAttachment는 파일을 시스템 저장소로 옮기기 때문에,
        // 읽기 전용인 앱 번들 리소스를 바로 넘기지 않고 임시 파일로 복사해서 사용한다.
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        do {
            try FileManager.default.copyItem(at: bundleURL, to: tempURL)
            return try UNNotificationAttachment(identifier: resourceName, url: tempURL, options: nil)
        } catch {
            print("알림 이미지 첨부 실패: \(error)")
            return nil
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // 앱이 foreground일 때도 배너/사운드가 뜨도록. (기본값은 foreground에서 조용히 무시됨)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
