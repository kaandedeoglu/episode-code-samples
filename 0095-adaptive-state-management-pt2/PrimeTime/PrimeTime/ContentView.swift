import CasePaths
import Combine
import ComposableArchitecture
import Counter
import FavoritePrimes
import PrimeAlert
import ActivityFeed
import SwiftUI

struct AppState: Equatable {
  var count = 0
  var favoritePrimes: [Int] = []
  var activityFeed: [Activity] = []
  var alertNthPrime: PrimeAlert? = nil
  var isNthPrimeRequestInFlight: Bool = false
  var isPrimeModalShown: Bool = false
}

enum AppAction: Equatable {
  case counterView(CounterFeatureAction)
  case offlineCounterView(CounterFeatureAction)
  case favoritePrimes(FavoritePrimesAction)
  case activityFeed(ActivityFeedAction)
}

extension AppState {
  var favoritePrimesState: FavoritePrimesState {
    get {
      (self.isNthPrimeRequestInFlight, self.alertNthPrime, self.favoritePrimes)
    }
    set {
      (self.isNthPrimeRequestInFlight, self.alertNthPrime, self.favoritePrimes) = newValue
    }
  }

  var counterFeatureState: CounterFeatureState {
    get {
      CounterFeatureState(
        alertNthPrime: self.alertNthPrime,
        count: self.count,
        favoritePrimes: self.favoritePrimes,
        isNthPrimeRequestInFlight: self.isNthPrimeRequestInFlight,
        isPrimeModalShown: self.isPrimeModalShown
      )
    }
    set {
      self.alertNthPrime = newValue.alertNthPrime
      self.count = newValue.count
      self.favoritePrimes = newValue.favoritePrimes
      self.isNthPrimeRequestInFlight = newValue.isNthPrimeRequestInFlight
      self.isPrimeModalShown = newValue.isPrimeModalShown
    }
  }
  
  var activityFeedState: ActivityFeedState {
    get { self.activityFeed }
    set { self.activityFeed = newValue }
  }
}

class AppEnvironment {
  lazy var fileClient: FileClient = FileClient.live
  lazy var wolframNthPrime: (Int) -> Effect<Int?> = Counter.nthPrime
  lazy var offlineNthPrime: (Int) -> Effect<Int?> = Counter.offlineNthPrime
}

extension AppEnvironment {
  var favoritePrimes: FavoritePrimesEnvironment {
    FavoritePrimesEnvironment(fileClient: fileClient, nthPrime: wolframNthPrime)
  }
  
  var counterWolfram: CounterEnvironment {
    CounterEnvironment(nthPrime: wolframNthPrime)
  }
  
  var counterOffline: CounterEnvironment {
    CounterEnvironment(nthPrime: offlineNthPrime)
  }
  
  var empty: Void { () }
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
  pullback(
    counterViewReducer,
    value: \AppState.counterFeatureState,
    action: /AppAction.counterView,
    environment: \AppEnvironment.counterWolfram
  ),
  pullback(
    counterViewReducer,
    value: \AppState.counterFeatureState,
    action: /AppAction.offlineCounterView,
    environment: \AppEnvironment.counterOffline
  ),
  pullback(
    favoritePrimesReducer,
    value: \AppState.favoritePrimesState,
    action: /AppAction.favoritePrimes,
    environment: \AppEnvironment.favoritePrimes
  ),
  pullback(
    activityFeedReducer,
    value: \AppState.activityFeedState,
    action: /AppAction.activityFeed,
    environment: \.empty
  )
)

func activityFeed(
  _ reducer: @escaping Reducer<AppState, AppAction, AppEnvironment>
) -> Reducer<AppState, AppAction, AppEnvironment> {

  return { state, action, environment in
    switch action {
    case .counterView(.counter),
         .offlineCounterView(.counter),
         .favoritePrimes(.loadedFavoritePrimes),
         .favoritePrimes(.loadButtonTapped),
         .favoritePrimes(.saveButtonTapped),
         .favoritePrimes(.primeButtonTapped),
         .favoritePrimes(.nthPrimeResponse),
         .favoritePrimes(.alertDismissButtonTapped),
         .activityFeed:
      break
    case .counterView(.primeModal(.removeFavoritePrimeTapped)),
         .offlineCounterView(.primeModal(.removeFavoritePrimeTapped)):
      state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))

    case .counterView(.primeModal(.saveFavoritePrimeTapped)),
         .offlineCounterView(.primeModal(.saveFavoritePrimeTapped)):
      state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))

    case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
      for index in indexSet {
        state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.favoritePrimes[index])))
      }
    }

    return reducer(&state, action, environment)
  }
}

let isInExperiment = false //Bool.random()

struct ContentView: View {
  let store: Store<AppState, AppAction>
//  @ObservedObject var viewStore: ViewStore<???>
  
  init(store: Store<AppState, AppAction>) {
    print("ContentView.init")
    self.store = store
  }

  var body: some View {
    print("ContentView.body")
    return NavigationView {
      List {
        if !isInExperiment {
          NavigationLink(
            "Counter demo",
            destination: CounterView(
              store: store.scope(
                value: \.counterFeatureState,
                action: AppAction.counterView
              )
            )
          )
        } else {
          NavigationLink(
            "Offline counter demo",
            destination: CounterView(
              store: store.scope(
                value: \.counterFeatureState,
                action: AppAction.offlineCounterView
              )
            )
          )
        }
        NavigationLink(
          "Favorite primes",
          destination: FavoritePrimesView(
            store: store.scope(
              value: \.favoritePrimesState,
              action: AppAction.favoritePrimes
            )
          )
        )

        NavigationLink(
          "Activity Feed",
          destination: ActivityFeedView(
            store: store.scope(
              value: \.activityFeedState,
              action: AppAction.activityFeed
            )
          )
        )
      }
      .navigationBarTitle("State management")
    }
  }
}
