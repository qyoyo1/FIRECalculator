import Foundation

enum AssetType: String, CaseIterable, Identifiable, Codable {
    case cash
    case equity
    case realEstate
    case pension

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash:
            return "Cash"
        case .equity:
            return "Equity"
        case .realEstate:
            return "Real Estate"
        case .pension:
            return "Pension"
        }
    }
}

struct AssetAllocation: Identifiable, Codable {
    let id: UUID
    let type: AssetType
    var amount: Double
    var currency: CurrencyCode

    init(id: UUID = UUID(), type: AssetType, amount: Double, currency: CurrencyCode) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currency = currency
    }
}

struct FireInputs: Codable {
    var currentAge: Int
    var fireAge: Int
    var assets: [AssetAllocation]

    static let `default` = FireInputs(
        currentAge: 34,
        fireAge: 40,
        assets: [
            AssetAllocation(type: .cash, amount: 100_000, currency: .usd),
            AssetAllocation(type: .equity, amount: 250_000, currency: .usd),
            AssetAllocation(type: .realEstate, amount: 300_000, currency: .chf),
            AssetAllocation(type: .pension, amount: 50_000, currency: .eur)
        ]
    )
}
