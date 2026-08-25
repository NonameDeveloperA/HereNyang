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
        // 집/회사는 nil로 두면 위젯이 기본 아이콘(집/회사 일러스트, SF Symbol)을 쓰고,
        // 커스텀 장소는 사용자가 고른 아이콘을 여기 담아 위젯에 그대로 전달한다.
        var icon: PlaceIcon?
        var updatedAt: Date
    }
}

// 장소 아이콘은 SF Symbol(icon 탭)이나 번들 일러스트(image 탭, PlaceWidget/HereNyang 양쪽
// Assets.xcassets에 같은 이름으로 들어있는 "home"/"work" 이미지) 둘 중 하나를 가리킬 수 있다.
enum PlaceIconKind: String, Codable, Hashable {
    case symbol
    case image
}

struct PlaceIcon: Codable, Hashable {
    var name: String
    var kind: PlaceIconKind
}

enum Place: String, Codable, Hashable {
    // 저장된 장소(최대 5개) 중 하나에 있음. 실제 이름/아이콘은 ContentState.label/icon에 담긴다.
    case saved
    case away
    case unknown

    var displayName: String {
        switch self {
        case .saved: return "장소"
        case .away: return "이동 중"
        case .unknown: return "알 수 없음"
        }
    }
}
