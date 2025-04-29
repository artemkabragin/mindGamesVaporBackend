import JWT

struct UserPayload: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

extension UserPayload {
    init(user: User) throws {
        let userID = try user.requireID().uuidString
        self.subject = .init(value: userID)
        self.expiration = .init(value: .init(timeIntervalSinceNow: 60 * 15)) // 15 min sek
    }
}
