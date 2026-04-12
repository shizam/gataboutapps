struct Trait: Codable, Hashable {
    let name: String
    let tier: TraitTier
    enum TraitTier: String, Codable { case normal = "NORMAL"; case prominent = "PROMINENT" }
}
