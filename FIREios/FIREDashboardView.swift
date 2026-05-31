import SwiftUI

struct FIREDashboardView: View {
    @State private var viewModel = FIREViewModel()

    var body: some View {
        TabView {
            AssetsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Assets", systemImage: "briefcase.fill")
                }

            IncomeTabView(viewModel: viewModel)
                .tabItem {
                    Label("Projected Income", systemImage: "banknote.fill")
                }

            ScenariosTabView(viewModel: viewModel)
                .tabItem {
                    Label("FIRE Plan", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(FIRETheme.accent)
    }
}

struct AssetsTabView: View {
    @Bindable var viewModel: FIREViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Assets") {
                    ForEach(viewModel.assets) { asset in
                        AssetModuleRow(
                            title: asset.label,
                            amountText: viewModel.amountBinding(for: asset.key),
                            currency: viewModel.currencyBinding(for: asset.key)
                        )
                    }
                }

                CurrencySummarySection(
                    title: "Portfolio Summary",
                    summary: viewModel.portfolioSummary
                )
            }
            .navigationTitle("Assets")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

struct IncomeTabView: View {
    @Bindable var viewModel: FIREViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Expected Annual Income") {
                    ForEach(viewModel.incomeLines) { line in
                        AssetModuleRow(
                            title: line.label,
                            amountText: viewModel.amountBinding(for: line.key),
                            currency: viewModel.currencyBinding(for: line.key),
                            titleWidth: 112
                        )
                    }
                }

                CurrencySummarySection(
                    title: "Income Summary",
                    summary: viewModel.incomeSummary,
                    showFxNote: false
                )
            }
            .navigationTitle("Projected Income")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

struct ScenariosTabView: View {
    @Bindable var viewModel: FIREViewModel

    var body: some View {
        NavigationStack {
            Form {
                if !viewModel.validationErrors.isEmpty {
                    Section {
                        ForEach(viewModel.validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(FIRETheme.validation)
                        }
                    } header: {
                        Text("Issues")
                    }
                }

                if viewModel.validationErrors.isEmpty {
                    ForEach(viewModel.scenarioResults) { result in
                        ScenarioResultSection(result: result)
                    }
                } else {
                    Section("FIRE Scenarios") {
                        Text("Fix validation issues to calculate scenarios.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("FIRE Plan")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

struct SettingsTabView: View {
    @Bindable var viewModel: FIREViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Timeline") {
                    LabeledContent("Current Age") {
                        TextField("34", text: $viewModel.currentAgeText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("FIRE Age") {
                        TextField("40", text: $viewModel.fireAgeText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if viewModel.fireAge >= viewModel.currentAge {
                        LabeledContent("Years to FIRE") {
                            Text("\(max(viewModel.fireAge - viewModel.currentAge, 0))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ScenarioSettingsSection(viewModel: viewModel)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    FIREDashboardView()
}
