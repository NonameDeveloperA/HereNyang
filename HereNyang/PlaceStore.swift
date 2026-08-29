//
//  PlaceStore.swift
//  HereNyang
//
//  이름/아이콘/위치를 전부 사용자가 정할 수 있는 장소를 최대 5개까지 저장한다.
//  최초 실행 시에만 집/회사 2개를 기본값으로 미리 채워두지만, 그 이후에는 다른 장소와
//  완전히 동일하게 취급된다(이름·아이콘·위치 전부 수정/삭제 가능).
//

import CoreLocation
import Foundation

struct SavedPlace: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: PlaceIcon
    var latitude: Double?
    var longitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // CLRegion 식별자로 그대로 쓴다. UUID라 다른 장소와 겹칠 일이 없다.
    var regionIdentifier: String { id.uuidString }
}

@MainActor
final class PlaceStore: ObservableObject {
    static let shared = PlaceStore()
    static let maxCount = 5
    static let maxNameLength = 6

    @Published private(set) var places: [SavedPlace] = []

    private static let defaultsKey = "savedPlaces"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey) {
            places = (try? JSONDecoder().decode([SavedPlace].self, from: data)) ?? []
        } else {
            // 데이터가 아예 없는 최초 실행(진짜 첫 설치)일 때만 집/회사를 기본값으로 심어둔다.
            // 사용자가 나중에 전부 지워도 이 분기는 다시 타지 않는다(빈 배열도 저장돼 있으므로).
            places = [
                SavedPlace(id: UUID(), name: "집", icon: PlaceIcon(name: "home", kind: .image), latitude: nil, longitude: nil),
                SavedPlace(id: UUID(), name: "회사", icon: PlaceIcon(name: "work", kind: .image), latitude: nil, longitude: nil)
            ]
            save()
        }
    }

    var canAddMore: Bool { places.count < Self.maxCount }

    @discardableResult
    func add() -> SavedPlace? {
        guard canAddMore else { return nil }
        let place = SavedPlace(id: UUID(), name: "새 장소", icon: PlaceIconCatalog.defaultIcon, latitude: nil, longitude: nil)
        places.append(place)
        save()
        return place
    }

    func remove(id: UUID) {
        places.removeAll { $0.id == id }
        save()
    }

    func updateIcon(id: UUID, icon: PlaceIcon) {
        guard let index = places.firstIndex(where: { $0.id == id }) else { return }
        places[index].icon = icon
        save()
    }

    func updateName(id: UUID, name: String) {
        guard let index = places.firstIndex(where: { $0.id == id }) else { return }
        places[index].name = String(name.prefix(Self.maxNameLength))
        save()
    }

    func updateLocation(id: UUID, coordinate: CLLocationCoordinate2D) {
        guard let index = places.firstIndex(where: { $0.id == id }) else { return }
        places[index].latitude = coordinate.latitude
        places[index].longitude = coordinate.longitude
        save()
    }

    // 장소는 그대로 두고 좌표만 지운다. (장소 자체를 지우는 remove(id:)와는 다름)
    func clearLocation(id: UUID) {
        guard let index = places.firstIndex(where: { $0.id == id }) else { return }
        places[index].latitude = nil
        places[index].longitude = nil
        save()
    }

    func place(withRegionIdentifier identifier: String) -> SavedPlace? {
        places.first { $0.regionIdentifier == identifier }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(places) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
