import SwiftUI

enum FIRETheme {
    static let accent = Color(red: 0.086, green: 0.639, blue: 0.290)
    static let moduleTitle = Color(red: 0.114, green: 0.306, blue: 0.847)
    static let validation = Color.red
    static let currencyIconName = "coloncurrencysign.circle"
}

struct CurrencyIcon: View {
    var systemName: String = FIRETheme.currencyIconName

    var body: some View {
        Image(systemName: systemName)
            .imageScale(.medium)
            .foregroundStyle(FIRETheme.accent)
            .accessibilityLabel("Currency")
    }
}

struct CurrencyPickerField: View {
    @Binding var selection: Currency
    var showsLeadingIcon = true

    var body: some View {
        HStack(spacing: 4) {
            if showsLeadingIcon {
                CurrencyIcon()
            }

            Picker(selection: $selection) {
                ForEach(Currency.allCases) { code in
                    Label {
                        Text(code.rawValue)
                    } icon: {
                        Image(systemName: code.iconName)
                    }
                    .tag(code)
                }
            } label: {
                EmptyView()
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .accessibilityLabel("Currency")
    }
}

struct CurrencySummarySection: View {
    let title: String
    let summary: CurrencySummary
    var showFxNote = true

    var body: some View {
        Section(title) {
            if showFxNote {
                Text(FIREFormatting.fxInfoText())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Currency.allCases) { currency in
                LabeledContent {
                    Text(FIREFormatting.formatCurrency(
                        summary.byCurrency[currency, default: 0],
                        currency: currency
                    ))
                    .foregroundStyle(.secondary)
                } label: {
                    Label(currency.rawValue, systemImage: currency.iconName)
                }
            }

            LabeledContent {
                Text(FIREFormatting.formatCurrency(summary.totalUsd, currency: .USD))
                    .fontWeight(.semibold)
            } label: {
                Text("Total in USD")
                    .fontWeight(.semibold)
            }
        }
    }
}

struct AssetModuleRow: View {
    let title: String
    @Binding var amountText: String
    @Binding var currency: Currency
    var titleWidth: CGFloat = 92

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(FIRETheme.moduleTitle)
                .frame(minWidth: titleWidth, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                CurrencyPickerField(selection: $currency, showsLeadingIcon: false)
                    .fixedSize()

                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 72, maxWidth: 108)
            }
        }
    }
}

struct GrowthRateRow: View {
    let title: String
    @Binding var rateText: String
    var titleWidth: CGFloat = 92

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(FIRETheme.moduleTitle)
                .frame(width: titleWidth, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            TextField("0", text: $rateText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)

            Text("%")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
        }
    }
}

struct ScenarioSettingsSection: View {
    @Bindable var viewModel: FIREViewModel

    var body: some View {
        ForEach(viewModel.scenarioConfigurations) { configuration in
            Section(configuration.name) {
                ForEach(AssetKey.allCases, id: \.self) { assetKey in
                    GrowthRateRow(
                        title: assetKey.label,
                        rateText: viewModel.growthRateBinding(
                            scenario: configuration.key,
                            asset: assetKey
                        )
                    )
                }
            }
        }
    }
}

struct ScenarioResultSection: View {
    let result: ScenarioResult

    var body: some View {
        Section(result.name) {
            scenarioDetailText(result.calculationDetail)
            scenarioDetailText(result.projectedAssetsDetail)

            resultRow("FIRE Total", FIREFormatting.formatCurrency(result.fireTotalUSD, currency: .USD))
            resultRow("Annual Income (3%)", FIREFormatting.formatCurrency(result.annualIncomeUSD, currency: .USD))
            resultRow("Monthly Income", FIREFormatting.formatCurrency(result.monthlyIncomeUSD, currency: .USD))
        }
    }

    private func scenarioDetailText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(FIRETheme.accent)
        }
    }
}
