import Foundation

enum Currency: String, CaseIterable, Identifiable, Codable {
    case USD, CHF, EUR, RMB

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .USD: "dollarsign.circle"
        case .CHF: "francsign.circle"
        case .EUR: "eurosign.circle"
        case .RMB: "yensign.circle"
        }
    }
}

enum AssetKey: String, CaseIterable, Codable {
    case cash, equity, realEstate, pension

    var label: String {
        switch self {
        case .cash: "Cash"
        case .equity: "Equity"
        case .realEstate: "Real Estate"
        case .pension: "Pension"
        }
    }
}

enum IncomeInputKey: String, CaseIterable, Codable {
    case expectedAnnualIncome
    case realEstateIncome
    case rentExpenses
    case sharedExpenses

    var label: String {
        switch self {
        case .expectedAnnualIncome: "Annual Income"
        case .realEstateIncome: "RealEstate Income"
        case .rentExpenses: "Rent Expenses"
        case .sharedExpenses: "Shared Expenses"
        }
    }

    var sign: Int {
        switch self {
        case .expectedAnnualIncome, .realEstateIncome: 1
        case .rentExpenses, .sharedExpenses: -1
        }
    }
}

struct Asset: Identifiable, Equatable {
    let key: AssetKey
    var amount: Double
    var currency: Currency

    var id: AssetKey { key }
    var label: String { key.label }
}

struct IncomeLineItem: Identifiable, Equatable {
    let key: IncomeInputKey
    var amount: Double
    var currency: Currency

    var id: IncomeInputKey { key }
    var label: String { key.label }
    var sign: Int { key.sign }
}

struct GrowthRates: Equatable {
    var cash: Double
    var equity: Double
    var realEstate: Double
    var pension: Double

    subscript(key: AssetKey) -> Double {
        get {
            switch key {
            case .cash: cash
            case .equity: equity
            case .realEstate: realEstate
            case .pension: pension
            }
        }
        set {
            switch key {
            case .cash: cash = newValue
            case .equity: equity = newValue
            case .realEstate: realEstate = newValue
            case .pension: pension = newValue
            }
        }
    }
}

enum ScenarioKey: String, CaseIterable, Identifiable, Codable {
    case conservative, base, aggressive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .conservative: "Conservative Growth Rate"
        case .base: "Base Growth Rate"
        case .aggressive: "Aggressive Growth Rate"
        }
    }
}

struct ScenarioConfiguration: Identifiable, Equatable {
    let key: ScenarioKey
    var growth: GrowthRates

    var id: ScenarioKey { key }
    var name: String { key.displayName }
}

struct FIREScenario: Identifiable {
    let name: String
    let description: String
    let growth: GrowthRates

    var id: String { name }
}

struct CurrencySummary: Equatable {
    var byCurrency: [Currency: Double]
    var totalUsd: Double
}

struct ScenarioResult: Identifiable {
    let name: String
    let calculationDetail: String
    let projectedAssetsDetail: String
    let projectedAssetsUSD: Double
    let fireTotalUSD: Double
    let annualIncomeUSD: Double
    let monthlyIncomeUSD: Double

    var id: String { name }
}

enum FIREConstants {
    static let currencies: [Currency] = Currency.allCases

    static let fxToUSD: [Currency: Double] = [
        .USD: 1.0,
        .CHF: 1.12,
        .EUR: 1.09,
        .RMB: 0.14,
    ]

    static let withdrawalRate = 0.03

    static let scenarios: [FIREScenario] = [
        FIREScenario(
            name: "Conservative",
            description: "Lower growth assumptions focused on stability and downside protection.",
            growth: GrowthRates(cash: 0.015, equity: 0.05, realEstate: 0.03, pension: 0.02)
        ),
        FIREScenario(
            name: "Base",
            description: "Balanced assumptions representing a moderate long-term outcome.",
            growth: GrowthRates(cash: 0.025, equity: 0.07, realEstate: 0.045, pension: 0.03)
        ),
        FIREScenario(
            name: "Aggressive",
            description: "Higher growth assumptions with greater risk and volatility.",
            growth: GrowthRates(cash: 0.035, equity: 0.09, realEstate: 0.06, pension: 0.04)
        ),
    ]

    static func defaultScenarioConfigurations() -> [ScenarioConfiguration] {
        [
            ScenarioConfiguration(
                key: .conservative,
                growth: GrowthRates(cash: 0.015, equity: 0.05, realEstate: 0.03, pension: 0.02)
            ),
            ScenarioConfiguration(
                key: .base,
                growth: GrowthRates(cash: 0.025, equity: 0.07, realEstate: 0.045, pension: 0.03)
            ),
            ScenarioConfiguration(
                key: .aggressive,
                growth: GrowthRates(cash: 0.035, equity: 0.09, realEstate: 0.06, pension: 0.04)
            ),
        ]
    }

    static func defaultAssets() -> [Asset] {
        [
            Asset(key: .cash, amount: 8_000, currency: .CHF),
            Asset(key: .equity, amount: 316_000, currency: .CHF),
            Asset(key: .realEstate, amount: 0, currency: .CHF),
            Asset(key: .pension, amount: 173_000, currency: .CHF),
        ]
    }

    static func defaultIncomeLines() -> [IncomeLineItem] {
        [
            IncomeLineItem(key: .expectedAnnualIncome, amount: 300_000, currency: .CHF),
            IncomeLineItem(key: .realEstateIncome, amount: 0, currency: .CHF),
            IncomeLineItem(key: .rentExpenses, amount: 24_000, currency: .CHF),
            IncomeLineItem(key: .sharedExpenses, amount: 36_000, currency: .CHF),
        ]
    }
}
