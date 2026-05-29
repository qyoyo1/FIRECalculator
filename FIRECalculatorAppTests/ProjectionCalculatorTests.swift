import XCTest
@testable import FIRECalculatorApp

final class ProjectionCalculatorTests: XCTestCase {
    func testProjectionAndWithdrawalsInUSD() {
        let calculator = ProjectionCalculator()
        let scenarios = [
            Scenario(
                name: "Test",
                growthRatesByAsset: [
                    .cash: 0.0,
                    .equity: 0.0,
                    .realEstate: 0.0,
                    .pension: 0.0
                ]
            )
        ]
        let exchangeRates = ExchangeRates(
            usdPerCurrency: [
                .usd: 1.0,
                .chf: 2.0,
                .eur: 1.0,
                .rmb: 1.0
            ]
        )

        let inputs = FireInputs(
            currentAge: 34,
            fireAge: 40,
            assets: [
                AssetAllocation(type: .cash, amount: 100, currency: .usd),
                AssetAllocation(type: .equity, amount: 50, currency: .chf)
            ]
        )

        let result = calculator.calculate(
            inputs: inputs,
            scenarios: scenarios,
            exchangeRates: exchangeRates
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].fireTotalUSD, 200, accuracy: 0.0001)
        XCTAssertEqual(result[0].annualIncomeUSD, 6, accuracy: 0.0001)
        XCTAssertEqual(result[0].monthlyIncomeUSD, 0.5, accuracy: 0.0001)
    }

    func testCompoundingUsesYearsToFire() {
        let calculator = ProjectionCalculator()
        let scenarios = [
            Scenario(
                name: "Growth",
                growthRatesByAsset: [
                    .cash: 0.10,
                    .equity: 0.0,
                    .realEstate: 0.0,
                    .pension: 0.0
                ]
            )
        ]

        let inputs = FireInputs(
            currentAge: 34,
            fireAge: 36,
            assets: [AssetAllocation(type: .cash, amount: 100, currency: .usd)]
        )

        let result = calculator.calculate(
            inputs: inputs,
            scenarios: scenarios,
            exchangeRates: .fixedDefaults
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].fireTotalUSD, 121, accuracy: 0.0001)
    }
}
