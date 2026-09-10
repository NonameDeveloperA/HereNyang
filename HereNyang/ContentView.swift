//
//  ContentView.swift
//  HereNyang
//
//  Created by NonameDeveloper on 8/24/26.
//

import CoreLocation
import MapKit
import SwiftUI

// 시뮬레이터/기기에 실제로 최신 빌드가 설치됐는지 눈으로 바로 확인하기 위한 마커.
// 코드 수정할 때마다 이 문자열을 갱신함.
private let buildMarker = "Build 2026-09-10"

private enum FocusField: Hashable {
    case place(UUID)
}

struct ContentView: View {
    // 소유는 앱 전역(AppDelegate가 생성). 여기서는 상태 변화만 구독한다.
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var placeStore = PlaceStore.shared
    // 이름은 개수가 가변적이라 id별 임시 입력값을 들고 있다가 제출/포커스 이탈 시점에만
    // 스토어에 반영한다. (한글 조합 중간값 저장 방지)
    @State private var nameDrafts: [UUID: String] = [:]
    @FocusState private var focusedField: FocusField?
    @State private var pendingDelete: SavedPlace?
    @State private var pendingLocationClear: SavedPlace?
    @State private var mapPickerPlace: SavedPlace?

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

                Section("장소 (최대 \(PlaceStore.maxCount)개, 이름 \(PlaceStore.maxNameLength)자)") {
                    ForEach(placeStore.places) { place in
                        HStack {
                            IconPickerButton(selectedIcon: place.icon, onOpen: { focusedField = nil }) { newIcon in
                                placeStore.updateIcon(id: place.id, icon: newIcon)
                            }
                            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                            TextField("장소 이름", text: nameBinding(for: place.id))
                                .focused($focusedField, equals: .place(place.id))
                                .submitLabel(.done)
                                .onSubmit { commitName(for: place.id) }

                            // 아직 위치가 없으면 탭해서 현재 위치로 저장. 이미 설정된 상태면
                            // 실수로 조용히 덮어쓰지 않도록, 탭하면 삭제 확인 팝업을 띄운다
                            // (위치를 바꾸고 싶을 땐 길게 눌러서 "지도에서 선택"으로).
                            Button(place.coordinate == nil ? "위치 설정 안 됨" : "위치 설정됨") {
                                if place.coordinate == nil {
                                    locationManager.saveCurrentLocation(for: place.id)
                                } else {
                                    pendingLocationClear = place
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(place.coordinate == nil ? Color.secondary : Color.green)
                            .buttonStyle(.plain)
                        }
                        .id(FocusField.place(place.id))
                        .contextMenu {
                            Button {
                                focusedField = nil
                                mapPickerPlace = place
                            } label: {
                                Label("지도에서 선택", systemImage: "map")
                            }
                            if place.coordinate != nil {
                                Button(role: .destructive) {
                                    pendingLocationClear = place
                                } label: {
                                    Label("위치 삭제", systemImage: "location.slash")
                                }
                            }
                            Button(role: .destructive) {
                                pendingDelete = place
                            } label: {
                                Label("장소 삭제", systemImage: "trash")
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                pendingDelete = place
                            } label: {
                                Label("삭제", systemImage: "trash")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }

                    if placeStore.canAddMore {
                        Button("새 장소 추가") {
                            placeStore.add()
                        }
                    } else {
                        Text("최대 \(PlaceStore.maxCount)개까지 등록할 수 있어요.")
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: focusedField) { oldField, newField in
                    // 다른 곳을 눌러서 포커스가 빠질 때(Enter 없이)도 저장되도록.
                    if case .place(let id) = oldField {
                        commitName(for: id)
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
                .confirmationDialog(
                    "\"\(pendingDelete?.name ?? "")\" 삭제",
                    isPresented: Binding(
                        get: { pendingDelete != nil },
                        set: { isPresented in if !isPresented { pendingDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("삭제", role: .destructive) {
                        if let place = pendingDelete {
                            nameDrafts[place.id] = nil
                            locationManager.removePlace(id: place.id)
                        }
                        pendingDelete = nil
                    }
                    Button("취소", role: .cancel) { pendingDelete = nil }
                } message: {
                    Text("이 장소를 목록에서 삭제합니다. 되돌릴 수 없어요.")
                }
                .confirmationDialog(
                    "위치를 삭제할까요?",
                    isPresented: Binding(
                        get: { pendingLocationClear != nil },
                        set: { isPresented in if !isPresented { pendingLocationClear = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("위치 삭제", role: .destructive) {
                        if let place = pendingLocationClear {
                            locationManager.clearLocation(for: place.id)
                        }
                        pendingLocationClear = nil
                    }
                    Button("취소", role: .cancel) { pendingLocationClear = nil }
                } message: {
                    Text("\"\(pendingLocationClear?.name ?? "")\"의 저장된 위치만 지워져요. 장소 자체(이름·아이콘)는 남아있어요.")
                }
                .alert(
                    "위치를 저장할 수 없어요",
                    isPresented: Binding(
                        get: { locationManager.locationConflictMessage != nil },
                        set: { isPresented in if !isPresented { locationManager.locationConflictMessage = nil } }
                    ),
                    presenting: locationManager.locationConflictMessage
                ) { _ in
                    Button("확인") { locationManager.locationConflictMessage = nil }
                } message: { message in
                    Text(message)
                }

                Section {
                    LabeledContent("위치", value: locationManager.currentLabel)
                    if locationManager.currentPlace == .saved {
                        Button("Live Activity 다시 시작") {
                            locationManager.restartLiveActivity()
                        }
                    }
                } header: {
                    Text("현재 상태")
                } footer: {
                    if locationManager.currentPlace == .saved {
                        Text("다이나믹 아일랜드/잠금화면이 안 바뀌고 그대로일 때 눌러주세요.")
                    }
                }

                // 리스트 맨 아래 필드도 화면 가운데까지 끌어올릴 수 있도록 스크롤 여유 공간 확보.
                Color.clear
                    .frame(height: 300)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .navigationTitle("여기냥 HereNyang")
            // List는 빈 곳/버튼을 눌러도 키보드가 자동으로 안 닫힌다.
            //  - 스크롤(살짝만 드래그해도) 시 즉시 닫힘
            //  - 키보드 위 "완료" 버튼으로 항상 확실하게 닫을 수 있게
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { focusedField = nil }
                }
            }
            .sheet(item: $mapPickerPlace) { place in
                MapLocationPickerSheet(place: place, locationManager: locationManager) { coordinate in
                    locationManager.saveLocation(coordinate, for: place.id)
                }
            }
            }
        }
    }

    private func nameBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { nameDrafts[id] ?? placeStore.places.first(where: { $0.id == id })?.name ?? "" },
            set: { nameDrafts[id] = $0 }
        )
    }

    // 한글 조합(IME) 도중에 매 키 입력마다 저장하면 조합 중간값이 저장되는 문제가 있어서,
    // 입력이 끝난 시점(Enter 또는 포커스 이탈)에만 길이 제한 + 저장을 한 번에 처리한다.
    private func commitName(for id: UUID) {
        guard var text = nameDrafts[id] else { return }
        if text.count > PlaceStore.maxNameLength {
            text = String(text.prefix(PlaceStore.maxNameLength))
            nameDrafts[id] = text
        }
        placeStore.updateName(id: id, name: text)
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

// 장소 행 컨텍스트 메뉴의 "지도에서 선택"을 누르면 뜨는 화면. 지도를 탭해서 핀을 옮기고
// 저장을 눌러야 실제로 반영된다(취소하면 원래 좌표 그대로).
private struct MapLocationPickerSheet: View {
    let place: SavedPlace
    let locationManager: LocationManager
    let onSave: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pickedCoordinate: CLLocationCoordinate2D
    @State private var cameraPosition: MapCameraPosition

    init(place: SavedPlace, locationManager: LocationManager, onSave: @escaping (CLLocationCoordinate2D) -> Void) {
        self.place = place
        self.locationManager = locationManager
        self.onSave = onSave
        // 저장된 위치가 없으면 GPS로 현재 위치를 받아올 때까지 임시로 서울시청 근방을 보여준다.
        let initialCoordinate = place.coordinate ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        _pickedCoordinate = State(initialValue: initialCoordinate)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(center: initialCoordinate, latitudinalMeters: 800, longitudinalMeters: 800)
        ))
    }

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    Marker(place.name, coordinate: pickedCoordinate)
                    // 실제 지오펜스 반경(regionRadius)을 지도 좌표계에 그려서, 확대/축소해도
                    // 화면 픽셀이 아니라 실제 거리 기준으로 자동으로 크기가 맞춰지게 한다.
                    MapCircle(center: pickedCoordinate, radius: LocationManager.regionRadius)
                        .foregroundStyle(Color.accentColor.opacity(0.15))
                        .stroke(Color.accentColor, lineWidth: 2)
                }
                // onTapGesture 대신 simultaneousGesture를 써야 지도 기본 제스처(핀치 확대/축소,
                // 드래그)를 가로채지 않는다. onTapGesture는 독점 제스처라 지도 내장 제스처와 충돌한다.
                .simultaneousGesture(
                    SpatialTapGesture().onEnded { value in
                        if let coordinate = proxy.convert(value.location, from: .local) {
                            pickedCoordinate = coordinate
                        }
                    }
                )
            }
            .navigationTitle("\(place.name) 위치 선택")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Text("지도를 탭해서 위치를 옮길 수 있어요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(pickedCoordinate)
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 아직 저장된 위치가 없을 때만: 의미 없는 서울시청 기본값 대신 GPS로 받은
                // 현재 위치로 카메라를 옮겨서, 실제로 있는 곳 근처에서 바로 핀을 고를 수 있게 한다.
                guard place.coordinate == nil else { return }
                locationManager.requestCurrentLocationOnce { coordinate in
                    pickedCoordinate = coordinate
                    withAnimation {
                        cameraPosition = .region(
                            MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
