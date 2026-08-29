//
//  RootTabView.swift
//  HereNyang
//
//  화면 하단 탭바(독바 스타일)로 "여기냥"(장소/위치)과 "알림냥"(상식 알림 설정)을 오간다.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("여기냥", systemImage: "location.fill")
                }

            TriviaSettingsView()
                .tabItem {
                    Label("알림냥", systemImage: "bell.fill")
                }
        }
    }
}

#Preview {
    RootTabView()
}
