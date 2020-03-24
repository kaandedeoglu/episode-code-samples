import CasePaths
import Combine
import ComposableArchitecture
import Counter
import FavoritePrimes
import PrimeAlert
import SwiftUI

struct AppState: Equatable {
  var count = 0
  var favoritePrimes: [Int] = []
  var loggedInUser: User? = nil
  var activityFeed: [Activity] = []
  var alertNthPrime: PrimeAlert? = nil
  var isNthPrimeRequestInFlight: Bool = false
  var isPrimeModalShown: Bool = false

  struct Activity: Equatable {
    let timestamp: Date
    let type: ActivityType

    enum ActivityType: Equatable {
      case addedFavoritePrime(Int)
      case removedFavoritePrime(Int)
    }
  }

  struct User: Equatable {
    let id: Int
    let name: String
    let bio: String
  }
}

enum AppAction: Equatable {
  case counterView(CounterFeatureAction)
  case offlineCounterView(CounterFeatureAction)
  case favoritePrimes(FavoritePrimesAction)
}

extension AppState {
  var favoritePrimesState: FavoritePrimesState {
    get {
      (self.alertNthPrime, self.favoritePrimes)
    }
    set {
      (self.alertNthPrime, self.favoritePrimes) = newValue
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
  
  var counterWolframEnvironment: CounterEnvironment {
    CounterEnvironment(nthPrime: wolframNthPrime)
  }
  var counterOfflineEnvironment: CounterEnvironment {
    CounterEnvironment(nthPrime: offlineNthPrime)
  }
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
  pullback(
    counterViewReducer,
    value: \AppState.counterFeatureState,
    action: /AppAction.counterView,
    environment: \.counterWolframEnvironment
  ),
  pullback(
    counterViewReducer,
    value: \AppState.counterFeatureState,
    action: /AppAction.offlineCounterView,
    environment: \.counterOfflineEnvironment
  ),
  pullback(
    favoritePrimesReducer,
    value: \.favoritePrimesState,
    action: /AppAction.favoritePrimes,
    environment: \.favoritePrimes
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
         .favoritePrimes(.alertDismissButtonTapped):
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
              store: self.store.scope(
                value: { $0.counterFeatureState },
                action: { .counterView($0) }
              )
            )
          )
        } else {
          NavigationLink(
            "Offline counter demo",
            destination: CounterView(
              store: self.store.scope(
                value: { $0.counterFeatureState },
                action: { .offlineCounterView($0) }
              )
            )
          )
        }
        NavigationLink(
          "Favorite primes",
          destination: FavoritePrimesView(
            store: self.store.scope(
              value: { $0.favoritePrimesState },
              action: { .favoritePrimes($0) }
            )
          )
        )

        ForEach(Array(1...500_000), id: \.self) { value in
          Text("\(value)")
        }

      }
      .navigationBarTitle("State management")
    }
  }
}
