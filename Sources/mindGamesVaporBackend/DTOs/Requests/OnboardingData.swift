import Vapor

struct OnboardingData: Content {
    let gameType: GameType
    let attempts: [Double]
}
