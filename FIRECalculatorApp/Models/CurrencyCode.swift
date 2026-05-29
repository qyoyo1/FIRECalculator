import Foundation

enum CurrencyCode: String, CaseIterable, Identifiable, Codable {
    case usd = "USD"
    case chf = "CHF"
    case eur = "EUR"
    case rmb = "RMB"

    var id: String { rawValue }

    var displayName: String { rawValue }
}
