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
    private var activityStartedAt: Date?
    // iOS가 8시간 지난 Live Activity는 강제로 끝내버려서, 그 전에 미리 끝내고 새로 시작해
    // 시계를 리셋한다.
    private static let maxActivityDuration: TimeInterval = 7 * 60 * 60

    private init() {
        // 예전 프로세스가 띄워둔 Live Activity가 남아있을 수 있는데, 그 사이 앱/위젯이 새로
        // 빌드되면서 ContentState 구조가 바뀌었을 수도 있어서 그대로 이어받지 않고 정리한다.
        // 아직 그 장소에 머물러 있다면 LocationManager가 앱 시작 직후 지오펜스 상태를 다시
        // 조회해서(didDetermineState) 곧바로 새 Live Activity를 깨끗한 상태로 다시 띄워준다.
        for stale in Activity<PlaceActivityAttributes>.activities {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }
    }

    func update(place: Place, label: String, icon: PlaceIcon? = nil) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activity가 비활성화되어 있습니다. (설정 > 여기냥 앱 > Live Activities 확인 필요)")
            return
        }

        if let startedAt = activityStartedAt, Date().timeIntervalSince(startedAt) > Self.maxActivityDuration {
            restart(place: place, label: label, icon: icon)
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
                activityStartedAt = Date()
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
        activityStartedAt = nil
    }

    // 짧은 시간에 갱신을 여러 번 연달아 보내면, 그 activity 인스턴스의 시스템 쪽 렌더링이
    // 캐시에 낀 채로 다시 안 풀리는 경우가 있다. 그럴 때 기존 걸 완전히 끝내고 새 activity를
    // 처음부터 다시 만들어서 우회한다.
    func restart(place: Place, label: String, icon: PlaceIcon? = nil) {
        activityStartedAt = nil
        guard let activity else {
            update(place: place, label: label, icon: icon)
            return
        }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
            update(place: place, label: label, icon: icon)
        }
    }
}
