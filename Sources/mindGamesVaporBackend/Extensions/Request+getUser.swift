import Vapor

extension Request {
    func getUser() async throws -> User {
        let payload = try jwt.verify(as: UserPayload.self)
        let userID = UUID(uuidString: payload.subject.value)
        
        guard let id = userID else {
            throw Abort(.unauthorized, reason: "Invalid user ID in token")
        }
        
        return try await User.findOrUnauthorized(
            id,
            on: db
        )
    }
}
