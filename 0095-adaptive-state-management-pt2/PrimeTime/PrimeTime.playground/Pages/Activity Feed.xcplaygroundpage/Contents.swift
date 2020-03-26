import PlaygroundSupport
import ComposableArchitecture
import ActivityFeed
import SwiftUI


var activities = [
  Activity(timestamp: Date(), type: .addedFavoritePrime(5)),
  Activity(timestamp: Date().addingTimeInterval(-10), type: .addedFavoritePrime(5)),
  Activity(timestamp: Date().addingTimeInterval(-20), type: .addedFavoritePrime(5)),
  Activity(timestamp: Date().addingTimeInterval(-30), type: .addedFavoritePrime(5)),
  ]

PlaygroundPage.current.liveView = UIHostingController(
  rootView: NavigationView {
    ActivityFeedView(
      store: Store(
        initialValue: activities,
        reducer: activityFeedReducer,
        environment: ()
        )
    )
  }
)
