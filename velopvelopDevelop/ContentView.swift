//
//  ContentView.swift
//  velopvelopDevelop
//
//  Created by NonameDeveloper on 8/24/26.
//

import CoreLocation
import SwiftUI

// 시뮬레이터/기기에 실제로 최신 빌드가 설치됐는지 눈으로 바로 확인하기 위한 마커.
// 코드 수정할 때마다 이 문자열을 갱신함.
private let buildMarker = "Build 2026-08-24 16:15"

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var homeLabel: String = PlaceLabelStore.label(for: .home)
    @State private var workLabel: String = PlaceLabelStore.label(for: .work)

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(buildMarker)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("권한") {
                    LabeledContent("위치 권한", value: authorizationStatusText)
                    if locationManager.authorizationStatus == .notDetermined {
                        Button("위치 권한 요청") {
                            locationManager.requestPermission()
                        }
                    } else if locationManager.authorizationStatus == .authorizedWhenInUse {
                        Button("항상 허용으로 업그레이드") {
                            locationManager.requestAlwaysPermissionIfNeeded()
                        }
                    }
                }

                Section("집 / 회사 설정") {
                    LabeledContent("집") {
                        Text(locationManager.homeCoordinate == nil ? "설정 안 됨" : "설정됨")
                            .foregroundStyle(locationManager.homeCoordinate == nil ? Color.secondary : Color.green)
                    }
                    Button("현재 위치를 집으로 저장") {
                        locationManager.saveCurrentLocation(as: .home)
                    }

                    LabeledContent("회사") {
                        Text(locationManager.workCoordinate == nil ? "설정 안 됨" : "설정됨")
                            .foregroundStyle(locationManager.workCoordinate == nil ? Color.secondary : Color.green)
                    }
                    Button("현재 위치를 회사로 저장") {
                        locationManager.saveCurrentLocation(as: .work)
                    }
                }

                Section("표시 문구 (최대 \(PlaceLabelStore.maxLength)자)") {
                    TextField("집", text: $homeLabel)
                        .onChange(of: homeLabel) { _, newValue in
                            if newValue.count > PlaceLabelStore.maxLength {
                                homeLabel = String(newValue.prefix(PlaceLabelStore.maxLength))
                            }
                            PlaceLabelStore.setLabel(homeLabel, for: .home)
                        }
                    TextField("회사", text: $workLabel)
                        .onChange(of: workLabel) { _, newValue in
                            if newValue.count > PlaceLabelStore.maxLength {
                                workLabel = String(newValue.prefix(PlaceLabelStore.maxLength))
                            }
                            PlaceLabelStore.setLabel(workLabel, for: .work)
                        }
                }

                Section("현재 상태") {
                    LabeledContent("위치", value: PlaceLabelStore.label(for: locationManager.currentPlace))
                }
            }
            .navigationTitle("나는야 임북북")
        }
    }

    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "요청 전"
        case .authorizedWhenInUse: return "사용 중일 때만 허용"
        case .authorizedAlways: return "항상 허용"
        case .denied: return "거부됨"
        case .restricted: return "제한됨"
        @unknown default: return "알 수 없음"
        }
    }
}

#Preview {
    ContentView()
}
