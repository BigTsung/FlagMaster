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
        if abb2 == "PS" {
            return language.text(en, cn, ja: "パレスチナ", ko: "팔레스타인")
        }
        switch language {
        case .english: return en
        case .traditionalChinese: return cn
        case .japanese, .korean: return language.locale.localizedString(forRegionCode: abb2) ?? en
        }
    }
}
