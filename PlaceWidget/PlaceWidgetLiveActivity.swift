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

private func imageName(for place: Place) -> String? {
    switch place {
    case .home: return "home"
    case .work: return "work"
    case .away, .unknown: return nil
    }
}

private func symbolName(for place: Place) -> String {
    switch place {
    case .home: return "house.fill"
    case .work: return "building.2.fill"
    case .away: return "figure.walk"
    case .unknown: return "questionmark.circle.fill"
    }
}

// 잠금화면/확장 영역처럼 공간이 넉넉한 곳에서 쓰는 실제 일러스트.
// 원본이 가로로 넓은 장면 그림(1672x941)이라 아주 작은 영역에서는 캐릭터가 안 보일 수 있음.
private struct PlaceImage: View {
    let place: Place

    var body: some View {
        if let imageName = imageName(for: place) {
            Image(imageName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: symbolName(for: place))
                .foregroundStyle(Color.white)
        }
    }
}

struct PlaceWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PlaceActivityAttributes.self) { context in
            HStack(spacing: 12) {
                PlaceImage(place: context.state.place)
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
                    PlaceImage(place: context.state.place)
                        .frame(width: 32, height: 32)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.label)
                        .font(.headline)
                }
            } compactLeading: {
                PlaceImage(place: context.state.place)
                    .frame(width: 22, height: 22)
            } compactTrailing: {
                Text(context.state.label)
                    .font(.caption2)
            } minimal: {
                PlaceImage(place: context.state.place)
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
        PlaceActivityAttributes.ContentState(place: .home, label: "집", updatedAt: .now)
    }

    fileprivate static var work: PlaceActivityAttributes.ContentState {
        PlaceActivityAttributes.ContentState(place: .work, label: "회사", updatedAt: .now)
    }
}

#Preview("Notification", as: .content, using: PlaceActivityAttributes.preview) {
    PlaceWidgetLiveActivity()
} contentStates: {
    PlaceActivityAttributes.ContentState.home
    PlaceActivityAttributes.ContentState.work
}
