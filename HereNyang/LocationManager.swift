//
//  LocationManager.swift
//  HereNyang
//
//  저장된 장소(최대 5개)의 좌표를 지오펜스(반경 진입·이탈)로 감시해서 도착/출발을 감지한다.
//  GPS를 계속 추적하는 게 아니라 iOS가 배터리 효율적으로 관리하는 region monitoring에
//  의존하기 때문에, 앱이 백그라운드거나 종료된 상태에서도 진입/이탈 시점에만 깨어난다.
//

import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let regionRadius: CLLocationDistance = 150

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentPlace: Place = .unknown
    @Published private(set) var currentLabel: String = Place.unknown.displayName
    // 다른 장소와 너무 가까워서 저장을 거부했을 때 사용자에게 보여줄 메시지.
    @Published var locationConflictMessage: String?

    private let manager = CLLocationManager()
    // "현재 위치로 저장"을 누른 장소의 id. GPS 결과가 오면 이 장소의 좌표를 갱신한다.
    private var pendingLocationSaveID: UUID?
    // 진입 이벤트가 반복해서 들어올 때 같은 장소로의 재알림을 막기 위한 현재 위치 region 식별자.
    private var currentRegionID: String?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        refreshRegions()
    }

    // MARK: - 권한

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermissionIfNeeded() {
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    // MARK: - 장소 위치 저장 / 삭제

    func saveCurrentLocation(for placeID: UUID) {
        pendingLocationSaveID = placeID
        manager.requestLocation()
    }

    // 지도에서 직접 고른 좌표를 저장할 때도 GPS로 저장할 때와 동일한 근접 검사를 거친다.
    func saveLocation(_ coordinate: CLLocationCoordinate2D, for placeID: UUID) {
        trySaveLocation(coordinate, for: placeID)
    }

    func removePlace(id: UUID) {
        PlaceStore.shared.remove(id: id)
        refreshRegions()
    }

    // 서로 다른 두 장소가 반경(150m) 이상 겹치면 두 지오펜스가 동시에 걸쳐 있는 지점이 생겨서,
    // 그 지점에 들어갈 때 두 region의 진입 이벤트가 번갈아 발생해 알림/Live Activity가
    // 여러 번 울리는 문제가 생긴다. 그래서 두 반경이 절대 겹치지 않는 거리(반경의 2배)보다
    // 가까우면 저장을 거부한다.
    private func trySaveLocation(_ coordinate: CLLocationCoordinate2D, for placeID: UUID) {
        let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let conflict = PlaceStore.shared.places.first(where: { other in
            guard other.id != placeID, let otherCoordinate = other.coordinate else { return false }
            let otherLocation = CLLocation(latitude: otherCoordinate.latitude, longitude: otherCoordinate.longitude)
            return newLocation.distance(from: otherLocation) < Self.regionRadius * 2
        }) {
            locationConflictMessage = "\"\(conflict.name)\"과(와) 너무 가까워요. 다른 위치를 골라주세요."
            return
        }
        PlaceStore.shared.updateLocation(id: placeID, coordinate: coordinate)
        refreshRegions()
    }

    // MARK: - 지오펜스

    private func refreshRegions() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        for place in PlaceStore.shared.places {
            guard let coordinate = place.coordinate else { continue }
            let region = makeRegion(center: coordinate, identifier: place.regionIdentifier)
            manager.startMonitoring(for: region)
            manager.requestState(for: region)
        }
    }

    private func makeRegion(center: CLLocationCoordinate2D, identifier: String) -> CLCircularRegion {
        let region = CLCircularRegion(center: center, radius: Self.regionRadius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let placeID = pendingLocationSaveID, let location = locations.last else { return }
        pendingLocationSaveID = nil
        trySaveLocation(location.coordinate, for: placeID)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 조회 실패: \(error)")
        pendingLocationSaveID = nil
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        handleEnter(region: region)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        handleExit(region: region)
    }

    // startMonitoring(for:) 직후 requestState(for:)로 즉시 조회했을 때 결과가 오는 곳.
    // 등록 시점에 이미 그 영역 안에 있으면 didEnterRegion이 따로 안 불리기 때문에 여기서 대신 처리.
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            handleEnter(region: region)
        case .outside:
            handleExit(region: region)
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("지오펜스 모니터링 실패 (\(region?.identifier ?? "unknown")): \(error)")
    }

    private func handleEnter(region: CLRegion) {
        // GPS가 반경 경계 근처에서 흔들리면 진입 이벤트가 반복해서 들어올 수 있어서,
        // 이미 같은 장소(같은 region)로 인식된 상태면 알림/Live Activity를 다시 갱신하지 않는다.
        guard currentRegionID != region.identifier else { return }
        guard let place = PlaceStore.shared.place(withRegionIdentifier: region.identifier) else { return }
        currentRegionID = region.identifier
        currentPlace = .saved
        currentLabel = place.name
        NotificationManager.shared.sendArrivalNotification(label: place.name, icon: place.icon)
        LiveActivityController.shared.update(place: .saved, label: place.name, icon: place.icon)
    }

    private func handleExit(region: CLRegion) {
        guard PlaceStore.shared.place(withRegionIdentifier: region.identifier) != nil else { return }
        guard currentPlace != .away else { return }
        currentRegionID = nil
        currentPlace = .away
        currentLabel = Place.away.displayName
        LiveActivityController.shared.update(place: .away, label: Place.away.displayName)
    }
}
