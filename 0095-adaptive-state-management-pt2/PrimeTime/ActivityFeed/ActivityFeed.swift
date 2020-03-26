import CasePaths
import Combine
import ComposableArchitecture
import SwiftUI

public struct Activity: Hashable, Identifiable {
  public enum ActivityType: Hashable {
    case addedFavoritePrime(Int)
    case removedFavoritePrime(Int)
  }
  
  public let timestamp: Date
  public let type: ActivityType
  public let id = UUID().hashValue
  
  public init(timestamp: Date, type: ActivityType) {
    self.timestamp = timestamp
    self.type = type
  }
}

extension Activity {
  var cellTitle: String {
    switch type {
    case let .addedFavoritePrime(prime):
      return "Added prime: \(prime)"
    case let .removedFavoritePrime(prime):
      return "Removed prime: \(prime)"
    }
  }
  
  var cellSubtitle: String {
    DateFormatter.localizedString(
      from: timestamp,
      dateStyle: .medium,
      timeStyle: .medium)
  }
}

public typealias ActivityFeedState = [Activity]

public enum ActivityFeedAction: Equatable {
  case deleteActivity(IndexSet)
}

public func activityFeedReducer(
  state: inout ActivityFeedState,
  action: ActivityFeedAction,
  environment: Void
) -> [Effect<ActivityFeedAction>] {
  switch action {
  case let .deleteActivity(indexSet):
    indexSet.forEach { state.remove(at: $0) }
  }
  return []
}

public struct ActivityFeedView: View {
  let store: Store<ActivityFeedState, ActivityFeedAction>
  @ObservedObject var viewStore: ViewStore<ActivityFeedState>
  
  public init(store: Store<ActivityFeedState, ActivityFeedAction>) {
    self.store = store
    self.viewStore = self.store.view
  }
  
  public var body: some View {
    return List {
      ForEach(self.viewStore.value, id: \.self, content: ActivityCell.init(activity:))
        .onDelete { indexSet in
          self.store.send(.deleteActivity(indexSet))
      }
    }
    .navigationBarTitle("Activity feed")
  }
}

struct ActivityCell: View {
  let activity: Activity
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(activity.cellTitle).font(.body)
      Text(activity.cellSubtitle).font(.subheadline)
    }
  }
}
