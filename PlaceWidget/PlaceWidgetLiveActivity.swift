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
// 이동중/알 수 없음처럼 특정 장소가 아닌 상태만 고정 심볼로 대체 표시한다.
private func fallbackSymbolName(for place: Place) -> String {
    switch place {
    case .saved: return "mappin.circle.fill"
    case .away: return "figure.walk"
    case .unknown: return "questionmark.circle.fill"
    }
}

private func resolvedImageName(for state: PlaceActivityAttributes.ContentState) -> String? {
    guard let icon = state.icon, icon.kind == .image else { return nil }
    return icon.name
}

private func resolvedSymbolName(for state: PlaceActivityAttributes.ContentState) -> String {
    if let icon = state.icon, icon.kind == .symbol {
        return icon.name
    }
    return fallbackSymbolName(for: state.place)
}

// 잠금화면/확장 영역처럼 공간이 넉넉한 곳에서 쓰는 실제 일러스트.
// 원본이 가로로 넓은 장면 그림(1672x941)이라 아주 작은 영역에서는 캐릭터가 안 보일 수 있음.
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
                    .frame(width: 44, height: 44)
                Text(context.state.label)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PlaceImage(state: context.state)
                        .frame(width: 32, height: 32)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.label)
                        .font(.headline)
                }
            } compactLeading: {
                PlaceImage(state: context.state)
                    .frame(width: 22, height: 22)
            } compactTrailing: {
                Text(context.state.label)
                    .font(.caption2)
            } minimal: {
                PlaceImage(state: context.state)
                    .frame(width: 22, height: 22)
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
