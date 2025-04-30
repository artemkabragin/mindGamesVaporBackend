import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

public func configure(_ app: Application) async throws {
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "artembragin",
        password: Environment.get("DATABASE_PASSWORD") ?? "1337",
        database: Environment.get("DATABASE_NAME") ?? "auth_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)
    
    app.jwt.signers.use(.hs256(key: Environment.get("JWT_SECRET") ?? "super-secret"))

    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())
    app.migrations.add(AddAveragesToUsers())
    app.migrations.add(CreateReactionAttempts())
    app.migrations.add(RemoveReactionFieldsFromUsers())
    app.migrations.add(CreateCardFlipAttempts())
    app.migrations.add(AddDateChangedToUserAchievements())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(AddOnboardingToUser())

    try await app.autoMigrate().get()

    // register routes
    try routes(app)
}
