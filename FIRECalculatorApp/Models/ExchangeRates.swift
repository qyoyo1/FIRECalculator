import Foundation

struct ExchangeRates: Codable {
    private let usdPerCurrency: [CurrencyCode: Double]

    init(usdPerCurrency: [CurrencyCode: Double]) {
        self.usdPerCurrency = usdPerCurrency
    }

    func usdRate(for currency: CurrencyCode) -> Double {
        usdPerCurrency[currency] ?? 1.0
    }

    static let fixedDefaults = ExchangeRates(
        usdPerCurrency: [
            .usd: 1.00,
            .chf: 1.12,
            .eur: 1.09,
            .rmb: 0.14
        ]
    )
}
