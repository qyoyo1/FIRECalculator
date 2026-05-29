import Foundation

struct Scenario: Identifiable, Codable {
    let id: UUID
    let name: String
    let growthRatesByAsset: [AssetType: Double]

    init(id: UUID = UUID(), name: String, growthRatesByAsset: [AssetType: Double]) {
        self.id = id
        self.name = name
        self.growthRatesByAsset = growthRatesByAsset
    }

    func growthRate(for assetType: AssetType) -> Double {
        growthRatesByAsset[assetType] ?? 0
    }
}

extension Scenario {
    static let fixedDefaults: [Scenario] = [
        Scenario(
            name: "Conservative",
            growthRatesByAsset: [
                .cash: 0.015,
                .equity: 0.05,
                .realEstate: 0.03,
                .pension: 0.02
            ]
        ),
        Scenario(
            name: "Base",
            growthRatesByAsset: [
                .cash: 0.025,
                .equity: 0.07,
                .realEstate: 0.045,
                .pension: 0.03
            ]
        ),
        Scenario(
            name: "Aggressive",
            growthRatesByAsset: [
                .cash: 0.035,
                .equity: 0.09,
                .realEstate: 0.06,
                .pension: 0.04
            ]
        )
    ]
}
