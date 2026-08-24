//
//  ContentView.swift
//  HereNyang
//
//  Created by NonameDeveloper on 8/24/26.
//

import CoreLocation
import SwiftUI

// 시뮬레이터/기기에 실제로 최신 빌드가 설치됐는지 눈으로 바로 확인하기 위한 마커.
// 코드 수정할 때마다 이 문자열을 갱신함.
private let buildMarker = "Build 2026-08-24 21:10"

private enum LabelField: Hashable {
    case home
    case work
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var homeLabel: String = PlaceLabelStore.label(for: .home)
    @State private var workLabel: String = PlaceLabelStore.label(for: .work)
    @FocusState private var focusedField: LabelField?

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                    LabeledContent("집") {
                        TextField("집", text: $homeLabel)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .home)
                            .submitLabel(.done)
                            .onSubmit { commitLabel(&homeLabel, for: .home) }
                    }
                    .id(LabelField.home)

                    LabeledContent("회사") {
                        TextField("회사", text: $workLabel)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .work)
                            .submitLabel(.done)
                            .onSubmit { commitLabel(&workLabel, for: .work) }
                    }
                    .id(LabelField.work)
                }
                .onChange(of: focusedField) { oldField, newField in
                    // 다른 곳을 눌러서 포커스가 빠질 때(Enter 없이)도 저장되도록.
                    switch oldField {
                    case .home: commitLabel(&homeLabel, for: .home)
                    case .work: commitLabel(&workLabel, for: .work)
                    case nil: break
                    }
                    // 키보드가 뜬 다음, 포커스된 입력칸을 화면(키보드 제외) 가운데로 스크롤.
                    if let newField {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation {
                                proxy.scrollTo(newField, anchor: .center)
                            }
                        }
                    }
                }

                Section("현재 상태") {
                    LabeledContent("위치", value: PlaceLabelStore.label(for: locationManager.currentPlace))
                }

                // 리스트 맨 아래 필드도 화면 가운데까지 끌어올릴 수 있도록 스크롤 여유 공간 확보.
                Color.clear
                    .frame(height: 300)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .navigationTitle("여기냥 HereNyang")
            }
        }
    }

    // 한글 조합(IME) 도중에 매 키 입력마다 저장하면 조합 중간값이 저장되는 문제가 있어서,
    // 입력이 끝난 시점(Enter 또는 포커스 이탈)에만 길이 제한 + 저장을 한 번에 처리한다.
    private func commitLabel(_ text: inout String, for place: Place) {
        if text.count > PlaceLabelStore.maxLength {
            text = String(text.prefix(PlaceLabelStore.maxLength))
        }
        PlaceLabelStore.setLabel(text, for: place)
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
