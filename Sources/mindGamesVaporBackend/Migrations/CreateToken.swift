import Vapor
import Fluent

struct CreateToken: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("tokens")
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .unique(on: "value")
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("tokens").delete()
    }
}

struct CreateRefreshToken: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("refresh_tokens")
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("expires_at", .datetime, .required)
            .unique(on: "value")
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("refresh_tokens").delete()
    }
}
