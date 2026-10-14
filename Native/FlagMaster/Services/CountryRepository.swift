import Foundation

enum CountryRepositoryError: LocalizedError {
    case missingData
    case invalidData

    var errorDescription: String? { "countries.json could not be loaded." }
}

enum CountryRepository {
    static func load() throws -> [Country] {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json") else {
            throw CountryRepositoryError.missingData
        }
        let countries = try JSONDecoder().decode([Country].self, from: Data(contentsOf: url))
        guard countries.count >= 4, Set(countries.map(\.abb2)).count == countries.count else {
            throw CountryRepositoryError.invalidData
        }
        return countries
    }
}
