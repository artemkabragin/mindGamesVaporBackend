import Fluent

struct CreateTodo: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("todos")
            .id()
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("todos").delete()
    }
}

struct CreateReactionAttempts: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("reaction_attempts")
            .id()
            .field("initial_average", .double, .required)
            .field("current_average", .double, .required)
            .field("attempts", .array(of: .double), .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("reaction_attempts").delete()
    }
}

import Fluent

import Fluent

struct RemoveReactionFieldsFromUsers: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .deleteField("initial_average")
            .deleteField("current_average")
            .deleteField("attempts")
            .update()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("initial_average", .double)
            .field("current_average", .double)
            .field("attempts", .array(of: .double))
            .update()
    }
}
