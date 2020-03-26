import XCTest
@testable import ActivityFeed
import ComposableArchitectureTestSupport

class ActivityFeedTests: XCTestCase {
  func testDeleteActivity() {
    let now = Date()
    var state = [
      Activity(
        timestamp: now.addingTimeInterval(-30.0),
        type: .addedFavoritePrime(5)
      ),
      Activity(
        timestamp: now.addingTimeInterval(-20.0),
        type: .addedFavoritePrime(7)
      ),
      Activity(
        timestamp: now.addingTimeInterval(-10.0),
        type: .addedFavoritePrime(11)
      ),
      Activity(
        timestamp: now.addingTimeInterval(0.0),
        type: .removedFavoritePrime(7)
      ),
    ]
    
    let effects = activityFeedReducer(state: &state,
                                      action: .deleteActivity(IndexSet(integer: 0)),
                                      environment: ())
    
    XCTAssertEqual(state.count, 3)
    XCTAssertEqual(state[0].timestamp, now.addingTimeInterval(-20.0))
    XCTAssertTrue(effects.isEmpty)
  }
}
