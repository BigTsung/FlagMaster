import Foundation
import Testing
@testable import FlagMasterCore

struct CountryInformationTests {
    private var resources: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FlagMaster/Resources")
    }

    private func information() throws -> [String: CountryInformation] {
        try CountryInformationRepository.decode(Data(contentsOf: resources.appendingPathComponent("country-info.json")))
    }

    @Test func everyCatalogueCardHasOfflineBilingualInformation() throws {
        let countries = try JSONDecoder().decode([Country].self, from: Data(contentsOf: resources.appendingPathComponent("countries.json")))
        let facts = try information()
        #expect(Set(facts.keys) == Set(countries.map(\.abb2)))
        for (code, info) in facts {
            for text in [info.capital.en, info.capital.zhHant, info.flagDescription.en, info.flagDescription.zhHant] {
                #expect(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Missing text: \(code)")
                #expect(!text.contains("<br") && !text.contains("<strong>"), "HTML leaked into \(code)")
            }
            #expect(!info.sources.isEmpty, "Missing source: \(code)")
            #expect(info.sources.allSatisfy { $0.url.scheme == "https" && $0.url.host != nil })
            #expect(info.collectedOn == "2026-11-08")
            #expect(info.capital.localized(.traditionalChinese) == info.capital.zhHant)
            #expect(info.flagDescription.localized(.japanese) == info.flagDescription.en)
        }
    }

    @Test func undocumentedFlowersAreNotPresentedAsNoNationalFlower() throws {
        let facts = try information()
        for info in facts.values {
            #expect((info.flowerStatus == .documented) == (info.flower != nil))
            if let flower = info.flower {
                #expect(!flower.en.isEmpty && !flower.zhHant.isEmpty)
                #expect(info.sources.contains { $0.title == "National flower reference" })
            } else if info.flowerStatus == .notCollected {
                #expect(info.flowerDescription(.traditionalChinese) == "尚未收錄可查證的國花資料")
            }
        }
        #expect(facts["TW"]?.flowerDescription(.traditionalChinese) == "梅花")
        #expect(facts["EU"]?.flowerStatus == .notApplicable)
    }

    @Test func specialCasesRetainContext() throws {
        let facts = try information()
        #expect(facts["AF"]?.historicalFlag == true)
        #expect(facts.values.filter(\.historicalFlag).count == 1)
        #expect(facts["NR"]?.capital.zhHant.contains("無正式首都") == true)
        #expect(facts["ZA"]?.capital.zhHant.contains("司法") == true)
        #expect(facts["EU"]?.capital.zhHant.contains("無單一首都") == true)
        #expect(facts["GQ"]?.capital.en == "Ciudad de la Paz")
        #expect(facts["CR"]?.flagDescription.en.contains("without a coat of arms") == true)
        #expect(facts["VE"]?.flagDescription.en.contains("without a coat of arms") == true)
        #expect(facts["PS"]?.capital.zhHant.contains("主張首都") == true)
    }
}
