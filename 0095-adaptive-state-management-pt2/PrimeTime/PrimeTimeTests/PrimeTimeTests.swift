import ComposableArchitecture
import ComposableArchitectureTestSupport
@testable import Counter
@testable import FavoritePrimes
import PrimeAlert
@testable import PrimeModal
@testable import PrimeTime
import XCTest

extension FileClient {
  static let mock = FileClient(
    load: { _ in Effect<Data?>.sync {
      try! JSONEncoder().encode([2, 31])
      } },
    save: { _, _ in .fireAndForget {} }
  )
}

class PrimeTimeTests: XCTestCase {
  func testIntegration() {
    var fileClient = FileClient.mock
    fileClient.load = { _ in .sync { try! JSONEncoder().encode([2, 31, 7]) } }
    
    let environment = AppEnvironment()
    environment.fileClient = fileClient
    environment.offlineNthPrime = { _ in .sync { 17 }}
    environment.wolframNthPrime = { _ in .sync { 17 }}
    
    assert(
      initialValue: AppState(count: 4),
      reducer: appReducer,
      environment: environment,
      steps:
      Step(.send, .counterView(.counter(.nthPrimeButtonTapped))) {
        $0.isNthPrimeRequestInFlight = true
      },
      Step(.receive, .counterView(.counter(.nthPrimeResponse(n: 4, prime: 17)))) {
        $0.isNthPrimeRequestInFlight = false
        $0.alertNthPrime = PrimeAlert(n: 4, prime: 17)
      },
      Step(.send, .favoritePrimes(.loadButtonTapped)),
      Step(.receive, .favoritePrimes(.loadedFavoritePrimes([2, 31, 7]))) {
        $0.favoritePrimes = [2, 31, 7]
      }
    )
  }
}
