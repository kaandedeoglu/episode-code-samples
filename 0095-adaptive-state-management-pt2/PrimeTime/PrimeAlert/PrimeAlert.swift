public struct PrimeAlert: Equatable, Identifiable {
  public let n: Int
  public let prime: Int
  public var id: Int { self.prime }
  
  public init(n: Int, prime: Int) {
    self.n = n
    self.prime = prime
  }
  
  public var title: String {
    return "The \(ordinal(self.n)) prime is \(decimal(self.prime))"
  }
}

public func ordinal(_ n: Int) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter.string(for: n) ?? ""
}

private func decimal(_ n: Int) -> String {
  return NumberFormatter.localizedString(from: .init(value: n), number: .decimal)
}
