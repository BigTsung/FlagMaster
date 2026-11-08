import Foundation

// Geographic study groups based on UN M49. North America includes Central America
// and the Caribbean. TW and XK follow the app's existing catalogue; EU is not a country.
enum StudyRegion: String, CaseIterable, Identifiable, Sendable {
    case asia, europe, africa, northAmerica, southAmerica, oceania
    var id: String { rawValue }
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .asia: return language.text("Asia", "亞洲", ja: "アジア", ko: "아시아")
        case .europe: return language.text("Europe", "歐洲", ja: "ヨーロッパ", ko: "유럽")
        case .africa: return language.text("Africa", "非洲", ja: "アフリカ", ko: "아프리카")
        case .northAmerica: return language.text("North America", "北美洲", ja: "北アメリカ", ko: "북아메리카")
        case .southAmerica: return language.text("South America", "南美洲", ja: "南アメリカ", ko: "남아메리카")
        case .oceania: return language.text("Oceania", "大洋洲", ja: "オセアニア", ko: "오세아니아")
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
    let clueJA: String
    let clueKO: String
    var codes: Set<String> { [first, second] }
    func clue(_ language: AppLanguage) -> String { language.text(clueEN, clueCN, ja: clueJA, ko: clueKO) }
    static let all: [FlagComparison] = [
        .init(id: "IE-CI", first: "IE", second: "CI",
              clueCN: "從旗桿側（畫面左邊）開始看：愛爾蘭是綠、白、橙；象牙海岸是橙、白、綠。記住色帶的順序。",
              clueEN: "Read from the hoist (left): Ireland is green–white–orange. Côte d’Ivoire is orange–white–green. Watch the order.",
              clueJA: "旗竿側（左）から見よう。アイルランドは緑・白・オレンジ、コートジボワールはオレンジ・白・緑。色の順番がポイントです。",
              clueKO: "깃대 쪽(왼쪽)부터 보세요. 아일랜드는 초록·흰색·주황, 코트디부아르는 주황·흰색·초록이에요. 색 순서가 중요해요."),
        .init(id: "PL-ID", first: "PL", second: "ID",
              clueCN: "看最上面的色帶：波蘭是白色在上、紅色在下；印尼剛好相反，紅色在上、白色在下。",
              clueEN: "Check the top stripe: Poland has white above red. Indonesia has red above white.",
              clueJA: "上の帯に注目。ポーランドは上が白、下が赤。インドネシアは上が赤、下が白です。",
              clueKO: "맨 위 띠를 보세요. 폴란드는 위가 흰색, 아래가 빨간색이에요. 인도네시아는 위가 빨간색, 아래가 흰색이에요."),
        .init(id: "AU-NZ", first: "AU", second: "NZ",
              clueCN: "看星星：澳洲是白色星星，左下還有一顆大星；紐西蘭是四顆紅色、白邊星星。",
              clueEN: "Look at the stars: Australia has white stars, including a large one at lower left. New Zealand has four red stars edged in white.",
              clueJA: "星に注目。オーストラリアは白い星で、左下にも大きな星があります。ニュージーランドは白縁の赤い星が 4 つです。",
              clueKO: "별을 보세요. 호주는 흰 별을 쓰고 왼쪽 아래에도 큰 별이 있어요. 뉴질랜드는 흰 테두리를 두른 빨간 별이 네 개예요."),
        .init(id: "RO-MD", first: "RO", second: "MD",
              clueCN: "兩面都是藍、黃、紅直條。看中央黃色色帶：摩爾多瓦有國徽，羅馬尼亞沒有。",
              clueEN: "Both have blue–yellow–red vertical stripes. Moldova has a coat of arms on the yellow band; Romania does not.",
              clueJA: "どちらも青・黄・赤の縦縞です。中央の黄色い帯に国章があるのがモルドバ、ないのがルーマニアです。",
              clueKO: "두 국기 모두 파랑·노랑·빨강 세로 띠예요. 몰도바는 가운데 노란 띠에 국장이 있고 루마니아에는 없어요.")
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
        case .region(let region): return region.title(language) + (language.text(" journey", "探索旅程", ja: "の旅", ko: " 탐험"))
        case .comparison: return language.text("Spot the difference", "相似國旗辨識", ja: "国旗の違いを見分けよう", ko: "비슷한 국기 구별하기")
        }
    }
}
