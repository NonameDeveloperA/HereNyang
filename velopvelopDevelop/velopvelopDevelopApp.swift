//
//  velopvelopDevelopApp.swift
//  velopvelopDevelop
//
//  Created by 이 진실 on 8/24/26.
//

import SwiftUI

@main
struct velopvelopDevelopApp: App {
    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
