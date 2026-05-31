import Foundation
import Observation
import SwiftUI

@Observable
final class FIREViewModel {
    var currentAge: Int = 34
    var fireAge: Int = 40
    var assets: [Asset] = FIREConstants.defaultAssets()
    var incomeLines: [IncomeLineItem] = FIREConstants.defaultIncomeLines()
    var scenarioConfigurations: [ScenarioConfiguration] = FIREConstants.defaultScenarioConfigurations()

    var currentAgeText: String {
        get { String(currentAge) }
        set {
            let sanitized = FIREFormatting.sanitizeInteger(newValue)
            currentAge = Int(sanitized) ?? 0
        }
    }

    var fireAgeText: String {
        get { String(fireAge) }
        set {
            let sanitized = FIREFormatting.sanitizeInteger(newValue)
            fireAge = Int(sanitized) ?? 0
        }
    }

    var validationErrors: [String] {
        FIRECalculator.validationErrors(
            currentAge: currentAge,
            fireAge: fireAge,
            assets: assets,
            incomeLines: incomeLines,
            scenarioConfigurations: scenarioConfigurations
        )
    }

    var portfolioSummary: CurrencySummary {
        FIRECalculator.portfolioSummary(assets: assets)
    }

    var incomeSummary: CurrencySummary {
        FIRECalculator.expectedIncomeSummary(incomeLines: incomeLines)
    }

    var scenarioResults: [ScenarioResult] {
        guard validationErrors.isEmpty else { return [] }
        return FIRECalculator.scenarios(
            currentAge: currentAge,
            fireAge: fireAge,
            assets: assets,
            incomeLines: incomeLines,
            scenarioConfigurations: scenarioConfigurations
        )
    }

    func amountText(for asset: Asset) -> String {
        formatAmount(asset.amount)
    }

    func setAmountText(_ text: String, for assetKey: AssetKey) {
        guard let index = assets.firstIndex(where: { $0.key == assetKey }) else { return }
        let sanitized = FIREFormatting.sanitizeDecimal(text)
        assets[index].amount = sanitized.isEmpty ? 0 : Double(sanitized) ?? 0
    }

    func setCurrency(_ currency: Currency, for assetKey: AssetKey) {
        guard let index = assets.firstIndex(where: { $0.key == assetKey }) else { return }
        assets[index].currency = currency
    }

    func amountText(for incomeLine: IncomeLineItem) -> String {
        formatAmount(incomeLine.amount)
    }

    func setAmountText(_ text: String, for incomeKey: IncomeInputKey) {
        guard let index = incomeLines.firstIndex(where: { $0.key == incomeKey }) else { return }
        let sanitized = FIREFormatting.sanitizeDecimal(text)
        incomeLines[index].amount = sanitized.isEmpty ? 0 : Double(sanitized) ?? 0
    }

    func setCurrency(_ currency: Currency, for incomeKey: IncomeInputKey) {
        guard let index = incomeLines.firstIndex(where: { $0.key == incomeKey }) else { return }
        incomeLines[index].currency = currency
    }

    func amountBinding(for assetKey: AssetKey) -> Binding<String> {
        Binding(
            get: {
                guard let asset = self.assets.first(where: { $0.key == assetKey }) else { return "" }
                return self.formatAmount(asset.amount)
            },
            set: { self.setAmountText($0, for: assetKey) }
        )
    }

    func currencyBinding(for assetKey: AssetKey) -> Binding<Currency> {
        Binding(
            get: {
                self.assets.first(where: { $0.key == assetKey })?.currency ?? .CHF
            },
            set: { self.setCurrency($0, for: assetKey) }
        )
    }

    func amountBinding(for incomeKey: IncomeInputKey) -> Binding<String> {
        Binding(
            get: {
                guard let item = self.incomeLines.first(where: { $0.key == incomeKey }) else { return "" }
                return self.formatAmount(item.amount)
            },
            set: { self.setAmountText($0, for: incomeKey) }
        )
    }

    func currencyBinding(for incomeKey: IncomeInputKey) -> Binding<Currency> {
        Binding(
            get: {
                self.incomeLines.first(where: { $0.key == incomeKey })?.currency ?? .CHF
            },
            set: { self.setCurrency($0, for: incomeKey) }
        )
    }

    func growthRateBinding(scenario: ScenarioKey, asset: AssetKey) -> Binding<String> {
        Binding(
            get: {
                guard let configuration = self.scenarioConfigurations.first(where: { $0.key == scenario }) else {
                    return ""
                }
                return FIREFormatting.formatPercentInput(configuration.growth[asset])
            },
            set: { self.setGrowthRateText($0, scenario: scenario, asset: asset) }
        )
    }

    func setGrowthRateText(_ text: String, scenario: ScenarioKey, asset: AssetKey) {
        guard let index = scenarioConfigurations.firstIndex(where: { $0.key == scenario }) else { return }
        let sanitized = FIREFormatting.sanitizeDecimal(text)
        scenarioConfigurations[index].growth[asset] = FIREFormatting.parsePercentInput(sanitized)
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount == floor(amount) && amount < 1_000_000_000 {
            return String(format: "%.0f", amount)
        }
        return String(amount)
    }
}
