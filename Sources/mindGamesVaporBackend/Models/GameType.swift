import Vapor

enum GameType: String, Content, Codable {
    case reaction
    case cardFlip
    case colorMatch
}
