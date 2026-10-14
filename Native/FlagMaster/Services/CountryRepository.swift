import Foundation

enum CountryRepositoryError: LocalizedError {
    case missingData

    var errorDescription: String? { "countries.json could not be loaded." }
}

enum CountryRepository {
    static func load() throws -> [Country] {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json") else {
            throw CountryRepositoryError.missingData
        }
        return try JSONDecoder().decode([Country].self, from: Data(contentsOf: url))
    }
}
