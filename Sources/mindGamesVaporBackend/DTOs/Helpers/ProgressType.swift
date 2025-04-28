import Vapor

enum ProgressType: String, Content, Codable {
    case memory
    case attention
}
