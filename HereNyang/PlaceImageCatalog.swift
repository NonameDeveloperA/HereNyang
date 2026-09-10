//
//  PlaceImageCatalog.swift
//  HereNyang
//
//  추가 장소 아이콘 선택창의 "이미지" 탭에 보여줄 번들 일러스트 목록.
//  집/회사(home/work), 산책(walk), 운전(drive) 고양이 일러스트가 들어있고,
//  나중에 구매한 아이콘을 여기에 추가한다.
//  이름은 PlaceWidget/HereNyang 양쪽 Assets.xcassets에 같은 이름으로 들어있는
//  이미지셋(투명 배경 라인아트 한 벌)을 그대로 가리킨다.
//  ("이동 중" 상태에서 위젯이 쓰는 walk 일러스트는 PlaceWidgetLiveActivity에서 직접 참조한다.)
//

import Foundation

enum PlaceImageCatalog {
    struct Entry: Identifiable, Hashable {
        var id: String { assetName }
        let assetName: String
        let displayName: String
    }

    static let entries: [Entry] = [
        Entry(assetName: "home", displayName: "쉬는 냥이"),
        Entry(assetName: "work", displayName: "일하는 냥이"),
        Entry(assetName: "walk", displayName: "산책 냥이"),
        Entry(assetName: "drive", displayName: "운전 냥이")
    ]
}
