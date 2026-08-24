//
//  PlaceLabelStore.swift
//  HereNyang
//
//  다이나믹 아일랜드/알림에 표시할 집·회사 문구를 사용자가 직접 지정할 수 있게 저장한다.
//

import Foundation

enum PlaceLabelStore {
    static let maxLength = 6

    private static let homeKey = "label.home"
    private static let workKey = "label.work"

    static func label(for place: Place) -> String {
        switch place {
        case .home: return stored(homeKey) ?? place.displayName
        case .work: return stored(workKey) ?? place.displayName
        case .away, .unknown: return place.displayName
        }
    }

    static func setLabel(_ text: String, for place: Place) {
        let clamped = String(text.prefix(maxLength))
        switch place {
        case .home: UserDefaults.standard.set(clamped, forKey: homeKey)
        case .work: UserDefaults.standard.set(clamped, forKey: workKey)
        case .away, .unknown: break
        }
    }

    private static func stored(_ key: String) -> String? {
        let value = UserDefaults.standard.string(forKey: key)
        return (value?.isEmpty ?? true) ? nil : value
    }
}
