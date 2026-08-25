//
//  LiveActivityController.swift
//  HereNyang
//
//  Live Activity(다이나믹 아일랜드/잠금화면 표시)의 시작·갱신·종료만 담당.
//  실제 화면 레이아웃은 Widget Extension 타겟이 추가되기 전까지는 렌더링되지 않지만,
//  이 컨트롤러 코드 자체는 지금 미리 붙여둘 수 있음.
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var activity: Activity<PlaceActivityAttributes>?

    private init() {}

    func update(place: Place, label: String, icon: PlaceIcon? = nil) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activity가 비활성화되어 있습니다. (설정 > 여기냥 앱 > Live Activities 확인 필요)")
            return
        }

        let state = PlaceActivityAttributes.ContentState(place: place, label: label, icon: icon, updatedAt: Date())

        if let activity {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        } else {
            do {
                activity = try Activity.request(
                    attributes: PlaceActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil)
                )
            } catch {
                print("Live Activity 시작 실패: \(error)")
            }
        }
    }

    func end() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
