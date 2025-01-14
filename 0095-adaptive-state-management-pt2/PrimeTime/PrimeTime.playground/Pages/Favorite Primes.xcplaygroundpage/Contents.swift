import ComposableArchitecture
@testable import FavoritePrimes
import PlaygroundSupport
import SwiftUI

extension FileClient {
  static let mock = FileClient(
    load: { _ in Effect<Data?>.sync {
      try! JSONEncoder().encode([2, 31])
      } },
    save: { _, _ in .fireAndForget {} }
  )
}

var environment = FavoritePrimesEnvironment(
  fileClient: .mock,
  nthPrime: { _ in .sync { 17 } }
)

environment.fileClient.load = { _ in
  Effect.sync { try! JSONEncoder().encode(Array(1...10)) }
}

PlaygroundPage.current.liveView = UIHostingController(
  rootView: NavigationView {
    FavoritePrimesView(
      store: Store(
        initialValue: (
          alertNthPrime: nil,
          favoritePrimes: [2, 3, 5, 7, 11]
        ),
        reducer: favoritePrimesReducer,
        environment: environment
      )
    )
  }
)
