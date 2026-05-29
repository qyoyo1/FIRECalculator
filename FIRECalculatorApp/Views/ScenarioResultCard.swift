import SwiftUI

struct ScenarioResultCard: View {
    let projection: ScenarioProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(projection.scenarioName)
                .font(.headline)

            row(title: "FIRE Total (USD)", value: projection.fireTotalUSD)
            row(title: "Annual Income (3%)", value: projection.annualIncomeUSD)
            row(title: "Monthly Income", value: projection.monthlyIncomeUSD)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func row(title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value, format: .currency(code: CurrencyCode.usd.rawValue))
                .fontWeight(.semibold)
        }
    }
}
