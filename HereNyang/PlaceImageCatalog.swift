//
//  PlaceImageCatalog.swift
//  HereNyang
//
//  추가 장소 아이콘 선택창의 "이미지" 탭에 보여줄 번들 일러스트 목록.
//  지금은 집/회사에도 쓰는 고양이 일러스트 2종뿐이고, 나중에 구매한 아이콘을 여기에 추가한다.
//  이름은 PlaceWidget/HereNyang 양쪽 Assets.xcassets에 같은 이름(home/work)으로 들어있는
//  이미지셋을 그대로 가리킨다.
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
        Entry(assetName: "work", displayName: "일하는 냥이")
    ]
}
