enum AchievementType: String, Codable {
    case dailyStreak // х дней подряд
    case highScore // реакция меньше х
    case totalPlays // всего 100 раз сыграли
    case perfectScore // без ошибок
}
