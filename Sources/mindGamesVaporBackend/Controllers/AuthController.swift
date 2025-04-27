import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authRoutes = routes.grouped("auth")
        authRoutes.post("register", use: register)
        authRoutes.post("login", use: login)
    }
    
    func register(req: Request) async throws -> Token {
        let create = try req.content.decode(User.Create.self)
        
        // Проверка, существует ли уже пользователь с таким именем
        if try await User.query(on: req.db)
            .filter(\.$username == create.username)
            .first() != nil {
            throw Abort(.conflict, reason: "User with this username already exists")
        }
        

        let passwordHash = try Bcrypt.hash(create.password)
        let user = User(username: create.username, passwordHash: passwordHash)
        
        
        try await user.save(on: req.db)
        
        
        
//        return user.asPublic()
        
        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        return token
//        return User
//            .Authenticated(
//                user: user,
//                token: token
//            )
    }
    
    func login(req: Request) async throws -> Token {
        let userDTO = try req.content.decode(User.Login.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == userDTO.username)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Такого пользователя нет или пароль неверный")
        }

        let isPasswordCorrect = try Bcrypt.verify(userDTO.password, created: user.passwordHash)
        
        guard isPasswordCorrect else {
            throw Abort(.unauthorized, reason: "Такого пользователя нет или пароль неверный")
        }

        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        return token
    }
}
