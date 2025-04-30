import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authRoutes = routes.grouped("auth")
        authRoutes.post("register", use: register)
        authRoutes.post("login", use: login)
        authRoutes.post("refresh", use: refresh)
    }
    
    func register(req: Request) async throws -> AuthResponse {
        let create = try req.content.decode(User.Create.self)
        
        if try await User.query(on: req.db)
            .filter(\.$username == create.username)
            .first() != nil {
            throw Abort(.conflict, reason: "Пользователь с таким логином уже существует")
        }
        
        let passwordHash = try Bcrypt.hash(create.password)
        let user = User(
            username: create.username,
            passwordHash: passwordHash
        )
        
        try await user.save(on: req.db)
        
        let token = try await generateToken(
            for: user,
            on: req
        )
        
        return AuthResponse(
            token: token,
            user: user.toPublic()
        )
    }
    
    func login(req: Request) async throws -> AuthResponse {
        let userDTO = try req.content.decode(User.Login.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == userDTO.username)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Такого пользователя нет")
        }

        let isPasswordCorrect = try Bcrypt.verify(
            userDTO.password,
            created: user.passwordHash
        )
        
        guard isPasswordCorrect else {
            throw Abort(.unauthorized, reason: "Пароль неверный")
        }

        let token = try await generateToken(
            for: user,
            on: req
        )
        
        return AuthResponse(
            token: token,
            user: user.toPublic()
        )
    }
    
    func refresh(req: Request) async throws -> AuthResponse {
        let body = try req.content.decode(RefreshRequest.self)
        
        guard
            let token = try await RefreshToken.query(on: req.db)
                .filter(\.$value == body.refreshToken)
                .with(\.$user)
                .first(),
            token.expiresAt > Date()
        else {
            throw Abort(.unauthorized)
        }
        
        let user = token.user
        let accessToken = try req.jwt.sign(UserPayload(user: user))
        let tokenResponse = TokenResponse(
            accessToken: accessToken,
            refreshToken: token.value
        )
        
        return AuthResponse(
            token: tokenResponse,
            user: user.toPublic()
        )
    }
}

// MARK: - Private Methods

private extension AuthController {
    func generateToken(
        for user: User,
        on req: Request
    ) async throws -> TokenResponse {
        let accessToken = try req.jwt.sign(UserPayload(user: user))
        let refreshToken = try RefreshToken.generate(for: user)
        try await refreshToken.save(on: req.db)
        
        return TokenResponse(
            accessToken: accessToken,
            refreshToken: refreshToken.value
        )
    }
}
