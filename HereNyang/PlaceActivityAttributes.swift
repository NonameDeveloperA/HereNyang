//
//  PlaceActivityAttributes.swift
//  HereNyang
//
//  다이나믹 아일랜드/잠금화면에 표시할 Live Activity의 데이터 모델.
//  실제 화면(UI)은 나중에 추가할 Widget Extension 타겟에서 이 타입을 그대로 가져다 씀.
//

import ActivityKit
import Foundation

struct PlaceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var place: Place
        var label: String
        var updatedAt: Date
    }
}

enum Place: String, Codable, Hashable {
    case home
    case work
    case away
    case unknown

    var displayName: String {
        switch self {
        case .home: return "집"
        case .work: return "회사"
        case .away: return "이동 중"
        case .unknown: return "알 수 없음"
        }
    }
}
