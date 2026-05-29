import Foundation

struct ScenarioProjection: Identifiable {
    let id = UUID()
    let scenarioName: String
    let fireTotalUSD: Double
    let annualIncomeUSD: Double
    let monthlyIncomeUSD: Double
}

struct ProjectionCalculator {
    func calculate(
        inputs: FireInputs,
        scenarios: [Scenario],
        exchangeRates: ExchangeRates
    ) -> [ScenarioProjection] {
        let yearsToFire = max(inputs.fireAge - inputs.currentAge, 0)

        return scenarios.map { scenario in
            let fireTotalUSD = inputs.assets.reduce(0.0) { partial, asset in
                let rate = scenario.growthRate(for: asset.type)
                let projected = asset.amount * pow(1 + rate, Double(yearsToFire))
                let projectedUSD = projected * exchangeRates.usdRate(for: asset.currency)
                return partial + projectedUSD
            }

            let annualIncomeUSD = fireTotalUSD * 0.03
            let monthlyIncomeUSD = annualIncomeUSD / 12.0

            return ScenarioProjection(
                scenarioName: scenario.name,
                fireTotalUSD: fireTotalUSD,
                annualIncomeUSD: annualIncomeUSD,
                monthlyIncomeUSD: monthlyIncomeUSD
            )
        }
    }

    func currentPortfolioByCurrency(inputs: FireInputs) -> [CurrencyCode: Double] {
        var result: [CurrencyCode: Double] = [:]
        for asset in inputs.assets {
            result[asset.currency, default: 0] += asset.amount
        }
        return result
    }

    func currentPortfolioTotalUSD(inputs: FireInputs, exchangeRates: ExchangeRates) -> Double {
        inputs.assets.reduce(0.0) { partial, asset in
            partial + (asset.amount * exchangeRates.usdRate(for: asset.currency))
        }
    }
}
