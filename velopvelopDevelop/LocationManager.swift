//
//  LocationManager.swift
//  velopvelopDevelop
//
//  집/회사 좌표를 저장해두고, 지오펜스(반경 진입·이탈)로 도착/출발을 감지한다.
//  GPS를 계속 추적하는 게 아니라 iOS가 배터리 효율적으로 관리하는 region monitoring에
//  의존하기 때문에, 앱이 백그라운드거나 종료된 상태에서도 진입/이탈 시점에만 깨어난다.
//

import CoreLocation
import Foundation

enum LocationSlot {
    case home
    case work
}

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let regionRadius: CLLocationDistance = 150

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentPlace: Place = .unknown
    @Published private(set) var homeCoordinate: CLLocationCoordinate2D?
    @Published private(set) var workCoordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private var pendingSaveTarget: LocationSlot?

    private enum DefaultsKey {
        static let homeLatitude = "home.latitude"
        static let homeLongitude = "home.longitude"
        static let workLatitude = "work.latitude"
        static let workLongitude = "work.longitude"
    }

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        loadSavedCoordinates()
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

    // MARK: - 집/회사 저장

    func saveCurrentLocation(as slot: LocationSlot) {
        pendingSaveTarget = slot
        manager.requestLocation()
    }

    private func loadSavedCoordinates() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: DefaultsKey.homeLatitude) != nil {
            homeCoordinate = CLLocationCoordinate2D(
                latitude: defaults.double(forKey: DefaultsKey.homeLatitude),
                longitude: defaults.double(forKey: DefaultsKey.homeLongitude)
            )
        }
        if defaults.object(forKey: DefaultsKey.workLatitude) != nil {
            workCoordinate = CLLocationCoordinate2D(
                latitude: defaults.double(forKey: DefaultsKey.workLatitude),
                longitude: defaults.double(forKey: DefaultsKey.workLongitude)
            )
        }
    }

    private func persist(_ coordinate: CLLocationCoordinate2D, for slot: LocationSlot) {
        let defaults = UserDefaults.standard
        switch slot {
        case .home:
            defaults.set(coordinate.latitude, forKey: DefaultsKey.homeLatitude)
            defaults.set(coordinate.longitude, forKey: DefaultsKey.homeLongitude)
            homeCoordinate = coordinate
        case .work:
            defaults.set(coordinate.latitude, forKey: DefaultsKey.workLatitude)
            defaults.set(coordinate.longitude, forKey: DefaultsKey.workLongitude)
            workCoordinate = coordinate
        }
    }

    // MARK: - 지오펜스

    private func refreshRegions() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        if let homeCoordinate {
            let region = makeRegion(center: homeCoordinate, identifier: "home")
            manager.startMonitoring(for: region)
            manager.requestState(for: region)
        }
        if let workCoordinate {
            let region = makeRegion(center: workCoordinate, identifier: "work")
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
        guard let slot = pendingSaveTarget, let location = locations.last else { return }
        pendingSaveTarget = nil
        persist(location.coordinate, for: slot)
        refreshRegions()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 조회 실패: \(error)")
        pendingSaveTarget = nil
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
        guard let place = place(for: region.identifier) else { return }
        // GPS가 반경 경계 근처에서 흔들리면 진입 이벤트가 반복해서 들어올 수 있어서,
        // 이미 같은 장소로 인식된 상태면 알림/Live Activity를 다시 갱신하지 않는다.
        guard currentPlace != place else { return }
        currentPlace = place
        let label = PlaceLabelStore.label(for: place)
        NotificationManager.shared.sendArrivalNotification(for: place, label: label)
        LiveActivityController.shared.update(place: place, label: label)
    }

    private func handleExit(region: CLRegion) {
        guard place(for: region.identifier) != nil else { return }
        guard currentPlace != .away else { return }
        currentPlace = .away
        LiveActivityController.shared.update(place: .away, label: Place.away.displayName)
    }

    private func place(for regionIdentifier: String) -> Place? {
        switch regionIdentifier {
        case "home": return .home
        case "work": return .work
        default: return nil
        }
    }
}
