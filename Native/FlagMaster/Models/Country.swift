import Foundation

struct Country: Codable, Identifiable, Hashable, Sendable {
    let cn: String
    let en: String
    let full: String
    let abb2: String
    let abb3: String
    let code: String

    var id: String { abb2 }

    func name(for language: AppLanguage) -> String {
        language == .english ? en : cn
    }
}
