import Foundation

enum FIRECalculator {
    static func validationErrors(
        currentAge: Int,
        fireAge: Int,
        assets: [Asset],
        incomeLines: [IncomeLineItem],
        scenarioConfigurations: [ScenarioConfiguration]
    ) -> [String] {
        var errors: [String] = []

        if currentAge < 0 {
            errors.append("Current age must be a valid non-negative integer.")
        }
        if fireAge < 0 {
            errors.append("FIRE age must be a valid non-negative integer.")
        }
        if fireAge < currentAge {
            errors.append("FIRE age must be greater than or equal to current age.")
        }

        for asset in assets where !asset.amount.isFinite || asset.amount < 0 {
            errors.append("\(asset.label) must be a valid non-negative number.")
        }

        for item in incomeLines where !item.amount.isFinite || item.amount < 0 {
            errors.append("\(item.label) must be a valid non-negative number.")
        }

        for configuration in scenarioConfigurations {
            for assetKey in AssetKey.allCases {
                let rate = configuration.growth[assetKey]
                if !rate.isFinite || rate < 0 {
                    errors.append("\(configuration.name) \(assetKey.label) growth rate must be a valid non-negative number.")
                } else if rate > 1 {
                    errors.append("\(configuration.name) \(assetKey.label) growth rate must be at most 100%.")
                }
            }
        }

        return errors
    }

    static func portfolioSummary(assets: [Asset]) -> CurrencySummary {
        var byCurrency = Dictionary(uniqueKeysWithValues: Currency.allCases.map { ($0, 0.0) })
        var totalUsd = 0.0

        for asset in assets {
            byCurrency[asset.currency, default: 0] += asset.amount
            totalUsd += asset.amount * FIREConstants.fxToUSD[asset.currency, default: 1]
        }

        return CurrencySummary(byCurrency: byCurrency, totalUsd: totalUsd)
    }

    static func expectedIncomeSummary(incomeLines: [IncomeLineItem]) -> CurrencySummary {
        var byCurrency = Dictionary(uniqueKeysWithValues: Currency.allCases.map { ($0, 0.0) })
        var totalUsd = 0.0

        for item in incomeLines {
            let signedAmount = item.amount * Double(item.sign)
            byCurrency[item.currency, default: 0] += signedAmount
            totalUsd += signedAmount * FIREConstants.fxToUSD[item.currency, default: 1]
        }

        return CurrencySummary(byCurrency: byCurrency, totalUsd: totalUsd)
    }

    static func scenarios(
        currentAge: Int,
        fireAge: Int,
        assets: [Asset],
        incomeLines: [IncomeLineItem],
        scenarioConfigurations: [ScenarioConfiguration]
    ) -> [ScenarioResult] {
        let yearsToFire = max(fireAge - currentAge, 0)
        let netAnnualIncomeUSD = expectedIncomeSummary(incomeLines: incomeLines).totalUsd
        let futureYearsTotalIncomeUSD = netAnnualIncomeUSD * Double(yearsToFire)

        return scenarioConfigurations.map { configuration in
            var projectedAssetsUSD = 0.0
            let growthRatesSummary = assets
                .map { "\($0.label): \(FIREFormatting.formatPercent(configuration.growth[$0.key]))" }
                .joined(separator: ", ")

            let projectedAssetsSummary = assets.map { asset in
                let growthRate = configuration.growth[asset.key]
                let projected = asset.amount * pow(1 + growthRate, Double(yearsToFire))
                let projectedUSD = projected * FIREConstants.fxToUSD[asset.currency, default: 1]
                projectedAssetsUSD += projectedUSD
                return "\(asset.label): \(FIREFormatting.formatCurrency(projectedUSD, currency: .USD))"
            }.joined(separator: ", ")

            let fireTotalUSD = projectedAssetsUSD + futureYearsTotalIncomeUSD
            let annualIncomeUSD = fireTotalUSD * FIREConstants.withdrawalRate
            let monthlyIncomeUSD = annualIncomeUSD / 12

            return ScenarioResult(
                name: configuration.name,
                calculationDetail: "Growth rates -> \(growthRatesSummary)",
                projectedAssetsDetail: "Projected Assets -> \(projectedAssetsSummary)",
                projectedAssetsUSD: projectedAssetsUSD,
                fireTotalUSD: fireTotalUSD,
                annualIncomeUSD: annualIncomeUSD,
                monthlyIncomeUSD: monthlyIncomeUSD
            )
        }
    }
}

enum FIREFormatting {
    static func formatCurrency(_ amount: Double, code: String) -> String {
        if code == "USD" {
            return "$" + amount.formatted(.number.precision(.fractionLength(2)).grouping(.automatic))
        }
        let formatted = amount.formatted(.currency(code: code).precision(.fractionLength(2)))
        return formatted.replacingOccurrences(of: "US$", with: "$")
    }

    static func formatCurrency(_ amount: Double, currency: Currency) -> String {
        formatCurrency(amount, code: currency.rawValue)
    }

    static func formatPercent(_ value: Double) -> String {
        String(format: "%.2f%%", value * 100)
    }

    static func fxInfoText() -> String {
        let rates = FIREConstants.fxToUSD
        return "FX to USD: 1 USD=\(String(format: "%.2f", rates[.USD]!)), 1 CHF=\(String(format: "%.2f", rates[.CHF]!)), 1 EUR=\(String(format: "%.2f", rates[.EUR]!)), 1 RMB=\(String(format: "%.2f", rates[.RMB]!))"
    }

    static func formatPercentInput(_ decimalRate: Double) -> String {
        let percent = decimalRate * 100
        if percent == floor(percent) && abs(percent) < 1_000_000_000 {
            return String(format: "%.0f", percent)
        }
        return String(format: "%.2f", percent)
    }

    static func parsePercentInput(_ text: String) -> Double {
        let sanitized = sanitizeDecimal(text)
        guard !sanitized.isEmpty, let percent = Double(sanitized) else { return 0 }
        return percent / 100
    }

    static func sanitizeDecimal(_ raw: String) -> String {
        let filtered = raw.filter { $0.isNumber || $0 == "." }
        let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count > 1 else { return filtered }
        return parts[0] + "." + parts.dropFirst().joined()
    }

    static func sanitizeInteger(_ raw: String) -> String {
        String(raw.filter(\.isNumber))
    }
}
