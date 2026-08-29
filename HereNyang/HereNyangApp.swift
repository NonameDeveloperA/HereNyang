//
//  HereNyangApp.swift
//  HereNyang
//
//  Created by 임태준 on 8/24/26.
//

import SwiftUI

@main
struct HereNyangApp: App {
    init() {
        NotificationManager.shared.requestAuthorization()
        // 앱을 열 때마다 상식 알림 예약분(앞으로 7일치)을 모자란 만큼 채워 넣는다.
        Task { @MainActor in
            TriviaNotificationScheduler.reschedule()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
