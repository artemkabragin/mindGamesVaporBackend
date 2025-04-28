import Vapor

enum GameType: String, Content, Codable {
    case reaction
    case cardFlip
    case colorMatch
    
//    var name: String {
//        switch self {
//        case .cardFlip:
//            "Переворот карт"
//        case .reaction:
//            "Круг реакции"
//        case .colorMatch:
//            "Цветные слова"
//        }
//    }
//    
//    var description: String {
//        switch self {
//        case .cardFlip:
//            "Соедините пары карточек одного цвета"
//        case .reaction:
//            "Нажимайте на зеленый круг как можно быстрее"
//        case .colorMatch:
//            "Выберите цвет, которым изображено слово"
//        }
//    }
}
