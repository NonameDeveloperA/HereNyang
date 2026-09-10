//
//  PlaceWidgetLiveActivity.swift
//  PlaceWidget
//
//  Created by 이 진실 on 8/24/26.
//
//  PlaceActivityAttributes는 HereNyang 앱 타겟에 있는 걸 그대로 씀.
//  (Xcode에서 그 파일의 Target Membership에 PlaceWidgetExtension도 체크해둬야 컴파일됨)
//

import ActivityKit
import WidgetKit
import SwiftUI

// 저장된 장소(.saved)는 항상 state.icon이 채워져서 온다(장소를 만들 때 기본 아이콘이 붙으므로).
// "이동 중"은 resolvedImageName에서 walk 일러스트로 처리되므로 여기까지 오지 않고,
// 남는 건 사실상 "알 수 없음"뿐이라 물음표 심볼로 대체 표시한다.
private func fallbackSymbolName(for place: Place) -> String {
    switch place {
    case .saved: return "mappin.circle.fill"
    case .away, .unknown: return "questionmark.circle.fill"
    }
}

private func resolvedImageName(for state: PlaceActivityAttributes.ContentState) -> String? {
    if let icon = state.icon, icon.kind == .image { return icon.name }
    // "이동 중"은 특정 장소가 아니라 icon이 nil로 오지만, 산책하는 고양이 일러스트로 표시한다.
    if state.place == .away { return "walk" }
    return nil
}

private func resolvedSymbolName(for state: PlaceActivityAttributes.ContentState) -> String {
    if let icon = state.icon, icon.kind == .symbol {
        return icon.name
    }
    return fallbackSymbolName(for: state.place)
}

// 잠금화면/확장 영역처럼 공간이 넉넉한 곳에서 쓰는 실제 일러스트.
// 일러스트 에셋은 투명 배경(흰 채움 + 검은 외곽선) 라인아트라, 어두운 배경에서는 흰 고양이로,
// 밝은 배경에서는 외곽선 그림으로 읽힌다. 위젯 영역은 항상 어두운 배경이라 흰 고양이로 보인다.
private struct PlaceImage: View {
    let state: PlaceActivityAttributes.ContentState

    var body: some View {
        if let imageName = resolvedImageName(for: state) {
            Image(imageName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: resolvedSymbolName(for: state))
                .foregroundStyle(Color.white)
        }
    }
}

struct PlaceWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PlaceActivityAttributes.self) { context in
            HStack(spacing: 12) {
                PlaceImage(state: context.state)
                    .frame(width: 46, height: 46)
                Text(context.state.label)
                    .font(.headline)
                Spacer()
            }
            .padding()

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PlaceImage(state: context.state)
                        .frame(width: 46, height: 46)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.label)
                        .font(.headline)
                }
            } compactLeading: {
                PlaceImage(state: context.state)
                    .frame(width: 30, height: 30) // 알약 높이 36.67pt 기준 실질 최대치(그 이상은 상하 잘림)
            } compactTrailing: {
                Text(context.state.label)
                    .font(.caption2)
            } minimal: {
                PlaceImage(state: context.state)
                    .frame(width: 30, height: 30) // 알약 높이 36.67pt 기준 실질 최대치(그 이상은 상하 잘림)
            }
        }
    }
}

extension PlaceActivityAttributes {
    fileprivate static var preview: PlaceActivityAttributes {
        PlaceActivityAttributes()
    }
}

extension PlaceActivityAttributes.ContentState {
    fileprivate static var home: PlaceActivityAttributes.ContentState {
        PlaceActivityAttributes.ContentState(
            place: .saved,
            label: "집",
            icon: PlaceIcon(name: "home", kind: .image),
            updatedAt: .now
        )
    }

    fileprivate static var cafe: PlaceActivityAttributes.ContentState {
        PlaceActivityAttributes.ContentState(
            place: .saved,
            label: "카페",
            icon: PlaceIcon(name: "cup.and.saucer.fill", kind: .symbol),
            updatedAt: .now
        )
    }

    fileprivate static var away: PlaceActivityAttributes.ContentState {
        PlaceActivityAttributes.ContentState(place: .away, label: "이동 중", icon: nil, updatedAt: .now)
    }
}

#Preview("Notification", as: .content, using: PlaceActivityAttributes.preview) {
    PlaceWidgetLiveActivity()
} contentStates: {
    PlaceActivityAttributes.ContentState.home
    PlaceActivityAttributes.ContentState.cafe
    PlaceActivityAttributes.ContentState.away
}
