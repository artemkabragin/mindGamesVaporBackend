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
