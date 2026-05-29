import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FireViewModel()

    var body: some View {
        NavigationStack {
            Form {
                InputSectionView(viewModel: viewModel)

                Section("Current Portfolio Summary") {
                    if viewModel.currentPortfolioByCurrency.isEmpty {
                        Text("Enter valid values to see portfolio totals.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.currentPortfolioByCurrency, id: \.currency) { row in
                            HStack {
                                Text(row.currency.rawValue)
                                Spacer()
                                Text(row.amount, format: .currency(code: row.currency.rawValue))
                                    .fontWeight(.semibold)
                            }
                        }

                        HStack {
                            Text("Total in USD")
                            Spacer()
                            Text(viewModel.currentPortfolioUSD, format: .currency(code: CurrencyCode.usd.rawValue))
                                .fontWeight(.bold)
                        }
                    }
                }

                if !viewModel.validationMessages.isEmpty {
                    Section("Validation") {
                        ForEach(viewModel.validationMessages, id: \.self) { message in
                            Text(message)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section("FIRE Scenarios") {
                    if viewModel.canCalculate {
                        ForEach(viewModel.scenarioResults) { result in
                            ScenarioResultCard(projection: result)
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 6)
                        }
                    } else {
                        Text("Fix validation issues to calculate scenario results.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("FIRE Calculator")
        }
    }
}

#Preview {
    ContentView()
}
