import Vapor

struct AuthResponse: Content {
    let token: TokenResponse
    let user: User.Public
}
