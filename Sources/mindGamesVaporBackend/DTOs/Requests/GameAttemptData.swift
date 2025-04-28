import Vapor

struct GameAttemptData: Content {
    let gameType: GameType
    let attempt: Double
}
