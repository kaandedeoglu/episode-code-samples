import Combine
import ComposableArchitecture
import PrimeAlert
import SwiftUI

public typealias FavoritePrimesState = (
  isNthPrimeRequestInFlight: Bool,
  alertNthPrime: PrimeAlert?,
  favoritePrimes: [Int]
)

public enum FavoritePrimesAction: Equatable {
  case deleteFavoritePrimes(IndexSet)
  case loadButtonTapped
  case loadedFavoritePrimes([Int])
  case primeButtonTapped(Int)
  case saveButtonTapped
  case nthPrimeResponse(n: Int, prime: Int?)
  case alertDismissButtonTapped
}

public struct FavoritePrimesEnvironment {
  var fileClient: FileClient
  var nthPrime: (Int) -> Effect<Int?>
  
  public init(fileClient: FileClient, nthPrime: @escaping (Int) -> Effect<Int?>) {
    self.fileClient = fileClient
    self.nthPrime = nthPrime
  }
}

public func favoritePrimesReducer(
  state: inout FavoritePrimesState,
  action: FavoritePrimesAction,
  environment: FavoritePrimesEnvironment
) -> [Effect<FavoritePrimesAction>] {
  switch action {
  case let .deleteFavoritePrimes(indexSet):
    for index in indexSet {
      state.favoritePrimes.remove(at: index)
    }
    return []

  case let .loadedFavoritePrimes(favoritePrimes):
    state.favoritePrimes = favoritePrimes
    return []

  case .saveButtonTapped:
    return [
      environment.fileClient
        .save("favorite-primes.json", try! JSONEncoder().encode(state.favoritePrimes))
        .fireAndForget()
    ]

  case .loadButtonTapped:
    return [
      environment.fileClient.load("favorite-primes.json")
        .compactMap { $0 }
        .decode(type: [Int].self, decoder: JSONDecoder())
        .catch { error in Empty(completeImmediately: true) }
        .map(FavoritePrimesAction.loadedFavoritePrimes)
        .eraseToEffect()
    ]

  case let .primeButtonTapped(n):
    state.isNthPrimeRequestInFlight = true
    return [
      environment.nthPrime(n)
        .map { FavoritePrimesAction.nthPrimeResponse(n: n, prime: $0) }
        .receive(on: DispatchQueue.main)
        .eraseToEffect()
    ]

  case .nthPrimeResponse(let n, let prime):
    state.alertNthPrime = prime.map { PrimeAlert(n: n, prime: $0) }
    state.isNthPrimeRequestInFlight = false
    return []

  case .alertDismissButtonTapped:
    state.alertNthPrime = nil
    return []
  }
}

public struct FavoritePrimesView: View {
  private let store: Store<FavoritePrimesState, FavoritePrimesAction>
  @ObservedObject var viewStore: ViewStore<FavoritePrimesState>

  public init(store: Store<FavoritePrimesState, FavoritePrimesAction>) {
    print("FavoritePrimesView.init")
    self.store = store
    self.viewStore = self.store.view(removeDuplicates: ==)
  }

  public var body: some View {
    print("FavoritePrimesView.body")
    return List {
      ForEach(self.viewStore.value.favoritePrimes, id: \.self) { prime in
        Button("\(prime)") {
          self.store.send(.primeButtonTapped(prime))
        }
        .disabled(self.viewStore.value.isNthPrimeRequestInFlight)
      }
      .onDelete { indexSet in
        self.store.send(.deleteFavoritePrimes(indexSet))
      }
    }
    .navigationBarTitle("Favorite primes")
    .navigationBarItems(
      trailing: HStack {
        Button("Save") {
          self.store.send(.saveButtonTapped)
        }
        Button("Load") {
          self.store.send(.loadButtonTapped)
        }
      }
    )
      .alert(item: .constant(self.viewStore.value.alertNthPrime)) { primeAlert in
        Alert(title: Text(primeAlert.title), dismissButton: Alert.Button.default(Text("Ok"), action: {
          self.store.send(.alertDismissButtonTapped)
        }))
    }
  }
}
