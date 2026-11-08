import Foundation

struct CountryInformation: Codable, Sendable {
    struct Text: Codable, Sendable {
        let en: String
        let zhHant: String

        func localized(_ language: AppLanguage) -> String {
            language == .traditionalChinese ? zhHant : en
        }
    }

    struct Source: Codable, Sendable {
        let title: String
        let url: URL
    }

    enum FlowerStatus: String, Codable, Sendable {
        case documented, notCollected, notApplicable
    }

    let capital: Text
    let flagDescription: Text
    let flower: Text?
    let flowerStatus: FlowerStatus
    let sources: [Source]
    let collectedOn: String
    let historicalFlag: Bool

    func flowerDescription(_ language: AppLanguage) -> String {
        switch flowerStatus {
        case .documented:
            return flower?.localized(language) ?? Self.missingFlower(language)
        case .notCollected:
            return Self.missingFlower(language)
        case .notApplicable:
            return language.text("Not applicable — a union, not a country", "不適用：歐盟是聯盟，並非國家", ja: "該当なし：国家ではなく連合です", ko: "해당 없음: 국가가 아닌 연합입니다")
        }
    }

    private static func missingFlower(_ language: AppLanguage) -> String {
        language.text("Not yet documented in this collection", "尚未收錄可查證的國花資料", ja: "この図鑑では確認済みの情報を未収録", ko: "이 도감에는 확인된 정보가 아직 없습니다")
    }
}

enum CountryInformationRepository {
    static let all: [String: CountryInformation] = {
        guard let url = Bundle.main.url(forResource: "country-info", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let result = try? decode(data) else { return [:] }
        return result
    }()

    static func decode(_ data: Data) throws -> [String: CountryInformation] {
        try JSONDecoder().decode([String: CountryInformation].self, from: data)
    }
}
