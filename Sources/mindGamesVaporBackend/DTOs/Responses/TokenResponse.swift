import Vapor

struct TokenResponse: Content {
    let accessToken: String
    let refreshToken: String
}
