//
//  HereNyangApp.swift
//  HereNyang
//
//  Created by 임태준 on 8/24/26.
//

import SwiftUI

@main
struct HereNyangApp: App {
    // 지오펜스/유의미한 위치 변화로 앱이 백그라운드에서 깨어나는 경우에도 위치 델리게이트가
    // 곧바로 살아있도록, UI와 무관하게 앱 시작 시점에 LocationManager를 만든다.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

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
                .onChange(of: scenePhase) { _, phase in
                    // 앱을 다시 열었을 때 region 이벤트를 기다리지 않고 현재 위치로 즉시 맞춘다.
                    if phase == .active {
                        LocationManager.shared.refreshOnForeground()
                    }
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 백그라운드 위치 이벤트로 깨어난 경우 UI가 그려지지 않으므로, 여기서 미리 생성해
        // CLLocationManager 델리게이트가 이벤트를 받을 준비를 끝내둔다.
        MainActor.assumeIsolated {
            _ = LocationManager.shared
        }
        return true
    }
}
