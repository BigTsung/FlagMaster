import Foundation

// Geographic study groups based on UN M49. North America includes Central America
// and the Caribbean. TW and XK follow the app's existing catalogue; EU is not a country.
enum StudyRegion: String, CaseIterable, Identifiable, Sendable {
    case asia, europe, africa, northAmerica, southAmerica, oceania
    var id: String { rawValue }
    func title(_ language: AppLanguage) -> String {
        let en = language == .english
        switch self {
        case .asia: return en ? "Asia" : "亞洲"
        case .europe: return en ? "Europe" : "歐洲"
        case .africa: return en ? "Africa" : "非洲"
        case .northAmerica: return en ? "North America" : "北美洲"
        case .southAmerica: return en ? "South America" : "南美洲"
        case .oceania: return en ? "Oceania" : "大洋洲"
        }
    }
    var codes: Set<String> {
        let list: String
        switch self {
        case .asia: list = "AF AM AZ BH BD BT BN KH CN CY GE IN ID IR IQ IL JP JO KZ KP KR KW KG LA LB MY MV MN MM NP OM PK PS PH QA SA SG LK SY TW TJ TH TL TR TM AE UZ VN YE"
        case .europe: list = "AL AD AT BY BE BA BG HR CZ DK EE FI FR DE GR VA HU IS IE IT XK LV LI LT LU MT MD MC ME NL MK NO PL PT RO RU SM RS SK SI ES SE CH UA GB"
        case .africa: list = "DZ AO BJ BW BF BI CV CM CF TD KM CG CD CI DJ EG GQ ER SZ ET GA GM GH GN GW KE LS LR LY MG MW ML MR MU MA MZ NA NE NG RW ST SN SC SL SO ZA SS SD TZ TG TN UG ZM ZW"
        case .northAmerica: list = "AG BS BB BZ CA CR CU DM DO SV GD GT HT HN JM MX NI PA KN LC VC TT US"
        case .southAmerica: list = "AR BO BR CL CO EC GY PY PE SR UY VE"
        case .oceania: list = "AU FJ KI MH FM NR NZ PW PG WS SB TO TV VU"
        }
        return Set(list.split(separator: " ").map(String.init))
    }
    func countries(in catalogue: [Country]) -> [Country] { catalogue.filter { codes.contains($0.abb2) } }
}

struct FlagComparison: Identifiable, Hashable, Sendable {
    let id: String
    let first: String
    let second: String
    let clueCN: String
    let clueEN: String
    var codes: Set<String> { [first, second] }
    func clue(_ language: AppLanguage) -> String { language == .english ? clueEN : clueCN }
    static let all: [FlagComparison] = [
        .init(id: "IE-CI", first: "IE", second: "CI",
              clueCN: "從旗桿側（畫面左邊）開始看：愛爾蘭是綠、白、橙；象牙海岸是橙、白、綠。記住色帶的順序。",
              clueEN: "Read from the hoist (left): Ireland is green–white–orange. Côte d’Ivoire is orange–white–green. Watch the order."),
        .init(id: "PL-ID", first: "PL", second: "ID",
              clueCN: "看最上面的色帶：波蘭是白色在上、紅色在下；印尼剛好相反，紅色在上、白色在下。",
              clueEN: "Check the top stripe: Poland has white above red. Indonesia has red above white."),
        .init(id: "AU-NZ", first: "AU", second: "NZ",
              clueCN: "看星星：澳洲是白色星星，左下還有一顆大星；紐西蘭是四顆紅色、白邊星星。",
              clueEN: "Look at the stars: Australia has white stars, including a large one at lower left. New Zealand has four red stars edged in white."),
        .init(id: "RO-MD", first: "RO", second: "MD",
              clueCN: "兩面都是藍、黃、紅直條。看中央黃色色帶：摩爾多瓦有國徽，羅馬尼亞沒有。",
              clueEN: "Both have blue–yellow–red vertical stripes. Moldova has a coat of arms on the yellow band; Romania does not.")
    ]
    static func match(_ first: String, _ second: String) -> FlagComparison? {
        all.first { $0.codes == Set([first, second]) }
    }
}

enum PracticePlan: Equatable, Sendable {
    case region(StudyRegion)
    case comparison(FlagComparison)
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .region(let region): return region.title(language) + (language == .english ? " journey" : "探索旅程")
        case .comparison: return language == .english ? "Spot the difference" : "相似國旗辨識"
        }
    }
}
