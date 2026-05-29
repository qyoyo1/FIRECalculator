import Foundation

struct AssetField: Identifiable {
    let id: UUID
    let type: AssetType
    var amountText: String
    var currency: CurrencyCode
}

@MainActor
final class FireViewModel: ObservableObject {
    @Published var currentAgeText: String
    @Published var fireAgeText: String
    @Published var assetFields: [AssetField]

    private let scenarios: [Scenario]
    private let exchangeRates: ExchangeRates
    private let calculator: ProjectionCalculator

    init(
        scenarios: [Scenario] = .fixedDefaults,
        exchangeRates: ExchangeRates = .fixedDefaults,
        calculator: ProjectionCalculator = ProjectionCalculator()
    ) {
        self.scenarios = scenarios
        self.exchangeRates = exchangeRates
        self.calculator = calculator

        let defaults = FireInputs.default
        currentAgeText = String(defaults.currentAge)
        fireAgeText = String(defaults.fireAge)
        assetFields = defaults.assets.map {
            AssetField(
                id: $0.id,
                type: $0.type,
                amountText: FireViewModel.decimalString(from: $0.amount),
                currency: $0.currency
            )
        }
    }

    var validationMessages: [String] {
        var messages: [String] = []

        guard let currentAge = Int(currentAgeText) else {
            messages.append("Current age must be a valid number.")
            return messages
        }

        guard let fireAge = Int(fireAgeText) else {
            messages.append("FIRE age must be a valid number.")
            return messages
        }

        if fireAge < currentAge {
            messages.append("FIRE age must be greater than or equal to current age.")
        }

        for asset in assetFields {
            guard let value = Double(asset.amountText) else {
                messages.append("\(asset.type.title) must be a valid number.")
                continue
            }
            if value < 0 {
                messages.append("\(asset.type.title) cannot be negative.")
            }
        }

        return messages
    }

    var canCalculate: Bool {
        validationMessages.isEmpty && validatedInputs != nil
    }

    var scenarioResults: [ScenarioProjection] {
        guard let inputs = validatedInputs else { return [] }
        return calculator.calculate(
            inputs: inputs,
            scenarios: scenarios,
            exchangeRates: exchangeRates
        )
    }

    var currentPortfolioByCurrency: [(currency: CurrencyCode, amount: Double)] {
        guard let inputs = validatedInputs else { return [] }
        let grouped = calculator.currentPortfolioByCurrency(inputs: inputs)
        return CurrencyCode.allCases.compactMap { code in
            guard let amount = grouped[code], amount > 0 else { return nil }
            return (code, amount)
        }
    }

    var currentPortfolioUSD: Double {
        guard let inputs = validatedInputs else { return 0 }
        return calculator.currentPortfolioTotalUSD(inputs: inputs, exchangeRates: exchangeRates)
    }

    func sanitizeCurrentAge() {
        currentAgeText = sanitizedInteger(currentAgeText)
    }

    func sanitizeFireAge() {
        fireAgeText = sanitizedInteger(fireAgeText)
    }

    func sanitizeAmount(assetId: UUID) {
        guard let index = assetFields.firstIndex(where: { $0.id == assetId }) else { return }
        assetFields[index].amountText = sanitizedDecimal(assetFields[index].amountText)
    }

    func updateCurrency(assetId: UUID, currency: CurrencyCode) {
        guard let index = assetFields.firstIndex(where: { $0.id == assetId }) else { return }
        assetFields[index].currency = currency
    }

    func updateAmount(assetId: UUID, text: String) {
        guard let index = assetFields.firstIndex(where: { $0.id == assetId }) else { return }
        assetFields[index].amountText = text
    }

    private var validatedInputs: FireInputs? {
        guard let currentAge = Int(currentAgeText),
              let fireAge = Int(fireAgeText)
        else { return nil }

        var allocations: [AssetAllocation] = []
        for field in assetFields {
            guard let amount = Double(field.amountText), amount >= 0 else { return nil }
            allocations.append(
                AssetAllocation(
                    id: field.id,
                    type: field.type,
                    amount: amount,
                    currency: field.currency
                )
            )
        }

        return FireInputs(
            currentAge: currentAge,
            fireAge: fireAge,
            assets: allocations
        )
    }

    private func sanitizedInteger(_ input: String) -> String {
        String(input.filter(\.isWholeNumber))
    }

    private func sanitizedDecimal(_ input: String) -> String {
        var output = ""
        var hasDot = false

        for char in input {
            if char.isWholeNumber {
                output.append(char)
            } else if char == "." && !hasDot {
                hasDot = true
                output.append(char)
            }
        }

        return output
    }

    private static func decimalString(from value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }
}
