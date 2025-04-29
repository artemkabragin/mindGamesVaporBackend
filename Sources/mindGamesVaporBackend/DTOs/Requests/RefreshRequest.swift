import Vapor

struct RefreshRequest: Content {
    let refreshToken: String
}
