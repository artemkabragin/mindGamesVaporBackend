enum AchievementType: String, Codable {
    case dailyStreak
    case highScore
    case totalPlays
    case perfectScore
    case timeBased
}

//extension AchievementType {
//    func getTitle(by gameType: GameType) -> String {
//        switch self {
//            
//        case .dailyStreak:
//            switch gameType {
//            case .cardFlip:
//                "Мастер карт"
//            case .reaction:
//                "Быстрая реакция"
//            case .colorMatch:
//                "Цветной мастер"
//            }
//            
//        case .highScore:
//            switch gameType {
//            case .cardFlip:
//                ""
//            case .reaction:
//                "Молниеносно"
//            case .colorMatch:
//                ""
//            }
//            
//        case .totalPlays:
//            switch gameType {
//            case .cardFlip:
//                "Любитель карт"
//            case .reaction:
//                "Эксперт реакции"
//            case .colorMatch:
//                "Любитель соответствия цвета"
//            }
//            
//        case .perfectScore:
//            "Идеальное прохождение"
//            
//        case .timeBased:
//            ""
//        }
//    }
//    
//    func getDescription(by gameType: GameType) -> String {
//        switch self {
//            
//        case .dailyStreak:
//            switch gameType {
//            case .cardFlip:
//                "Играли в Переворот карточек 7 дней подряд"
//            case .reaction:
//                "Играли в Круг реакции 10 дней подряд!"
//            case .colorMatch:
//                "Играли в Цветные слова 5 дней подряд"
//            }
//            
//        case .highScore:
//            switch gameType {
//            case .cardFlip:
//                ""
//            case .reaction:
//                "Время реакции менее 0,5 секунды!"
//            case .colorMatch:
//                ""
//            }
//            
//        case .totalPlays:
//            switch gameType {
//            case .cardFlip:
//                "Сыграли в Переворот карточек 50 раз!"
//            case .reaction:
//                "Сыграли в Круг реакции 100 раз!"
//            case .colorMatch:
//                "Сыграли в Цветные слова 75 раз!"
//            }
//            
//        case .perfectScore:
//            "Завершили \(gameType.name) без ошибок!"
//            
//        case .timeBased:
//            ""
//        }
//    }
//}
