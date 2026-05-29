import SwiftUI

struct InputSectionView: View {
    @ObservedObject var viewModel: FireViewModel

    var body: some View {
        Section("Inputs") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ages")
                    .font(.headline)

                TextField("Current age", text: $viewModel.currentAgeText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.currentAgeText) { _ in
                        viewModel.sanitizeCurrentAge()
                    }

                TextField("FIRE age", text: $viewModel.fireAgeText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.fireAgeText) { _ in
                        viewModel.sanitizeFireAge()
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Assets")
                    .font(.headline)

                ForEach(viewModel.assetFields) { asset in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(asset.type.title)
                            .font(.subheadline.weight(.semibold))

                        TextField(
                            "\(asset.type.title) amount",
                            text: Binding(
                                get: { asset.amountText },
                                set: { viewModel.updateAmount(assetId: asset.id, text: $0) }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: asset.amountText) { _ in
                            viewModel.sanitizeAmount(assetId: asset.id)
                        }

                        Picker(
                            "Currency",
                            selection: Binding(
                                get: { asset.currency },
                                set: { viewModel.updateCurrency(assetId: asset.id, currency: $0) }
                            )
                        ) {
                            ForEach(CurrencyCode.allCases) { currency in
                                Text(currency.displayName).tag(currency)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
