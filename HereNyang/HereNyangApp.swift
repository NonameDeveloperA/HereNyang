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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
