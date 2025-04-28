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


import Fluent

struct CreateAchievement1: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("achievements")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("type", .string, .required)
            .field("game_type", .string, .required)
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("achievements").delete()
    }
}

import Fluent

struct CreateUserAchievement: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("user_achievements")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("achievement_id", .uuid, .required, .references("achievements", "id", onDelete: .cascade))
            .field("is_unlocked", .bool, .required)
            .field("progress", .double, .required)
            .field("date_unlocked", .datetime)
            .unique(on: "user_id", "achievement_id") // один пользователь — одно достижение
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("user_achievements").delete()
    }
}

import Fluent
import Vapor



struct AddDateChangedToUserAchievements: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
       database.schema("user_achievements")
            .field("date_changed", .datetime)
            .update()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("user_achievements")
            .deleteField("date_changed")
            .update()
    }
}

//struct SeedAchievements1: Migration {
//    func prepare(on database: any Database) -> EventLoopFuture<Void> {
//        let achievements: [Achievement] = [
//            // CardFlip
//            .init(type: .dailyStreak, gameType: .cardFlip),
//            .init(type: .perfectScore, gameType: .cardFlip),
//            .init(type: .totalPlays, gameType: .cardFlip),
//            // Reaction
//            .init(type: .dailyStreak, gameType: .reaction),
//            .init(type: .highScore, gameType: .reaction),
//            .init(type: .totalPlays, gameType: .reaction),
//            // ColorMatch
//            .init(type: .dailyStreak, gameType: .colorMatch),
//            .init(type: .perfectScore, gameType: .colorMatch),
//            .init(type: .totalPlays, gameType: .colorMatch)
//        ]
//        
//        return achievements.map { $0.create(on: database) }
//                    .flatten(on: database.eventLoop)
//    }
//
//    func revert(on database: any Database) -> EventLoopFuture<Void> {
//        database.query(Achievement.self).delete()
//    }
//}
