import Vapor
import Fluent

struct CreateUser: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("passwordHash", .string, .required)
            .field("initial_average", .double)
            .field("current_average", .double)
            .field("attempts", .array(of: .double))
            .unique(on: "username")
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

import Vapor
import Fluent

struct AddAveragesToUsers: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("attempts", .array(of: .double))
            .update()  // Обновляем таблицу
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .deleteField("attempts")
            .update()  // Обновляем таблицу
    }
}
