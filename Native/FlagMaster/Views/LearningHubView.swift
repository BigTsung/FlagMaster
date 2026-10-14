import SwiftUI

struct JourneyPickerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected: StudyRegion = .asia
    private let countries = (try? CountryRepository.load()) ?? []
    let start: (PracticePlan) -> Void
    private var en: Bool { settings.language == .english }
    private var pool: [Country] { selected.countries(in: countries) }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Eyebrow(text: en ? "ONE REGION AT A TIME" : "一站一站，認識世界")
                    Text(en ? "Where shall we go?" : "這次，想去哪裡？").font(.largeTitle.bold())
                    Text(en ? "Tap a map pin or choose a region below. Each journey has up to 10 flags, with new discoveries first." : "點選地圖上的區域，或從下方選擇。每趟最多 10 面國旗，優先探索還不熟悉的地方。")
                        .font(.subheadline).foregroundStyle(Atlas.muted)
                    RegionMap(selected: $selected, language: settings.language)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(StudyRegion.allCases) { region in
                            let members = region.countries(in: countries)
                            let explored = members.filter { stats.stats[$0.abb2] != nil }.count
                            Button { select(region) } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(region.title(settings.language)).font(.headline)
                                        Spacer(minLength: 0)
                                        if selected == region { Image(systemName: "checkmark.circle.fill").foregroundStyle(Atlas.mint) }
                                    }
                                    Text(en ? "\(explored)/\(members.count) explored" : "已探索 \(explored)/\(members.count)")
                                        .font(.caption).foregroundStyle(Atlas.muted)
                                    ProgressView(value: Double(explored), total: Double(max(1, members.count))).tint(Atlas.mint)
                                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(selected == region ? Atlas.mint.opacity(0.12) : Atlas.panel, in: RoundedRectangle(cornerRadius: 20))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected == region ? Atlas.mint : .clear))
                            }.buttonStyle(AtlasPressStyle(sound: nil)).accessibilityAddTraits(selected == region ? .isSelected : [])
                        }
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Text(selected.title(settings.language)).font(.title2.bold())
                        HStack {
                            Metric(value: "\(min(10, pool.count))", label: en ? "Flags this trip" : "本趟題數")
                            Metric(value: "\(pool.filter { stats.stats[$0.abb2]?.isMastered == true }.count)", label: en ? "Familiar flags" : "熟悉國旗", color: Atlas.gold)
                        }
                        Text(en ? "Untimed · No repeats · Your progress is saved after every answer." : "不計時・本趟不重複・每次作答都儲存探索進度")
                            .font(.caption).foregroundStyle(Atlas.muted)
                        Button { start(.region(selected)) } label: {
                            Label(en ? "Start this journey" : "出發探索這一區", systemImage: "location.north.fill")
                        }.buttonStyle(AtlasButtonStyle(filled: true)).disabled(pool.count < 4)
                    }.modifier(AtlasCard(tint: Atlas.mint))
                    Text(en ? "Study regions are geographic groups. North America includes Central America and the Caribbean. The EU flag remains in free exploration." : "按地理分組學習；北美洲包含中美洲與加勒比海。歐盟旗幟保留在自由探索中。")
                        .font(.caption).foregroundStyle(Atlas.muted)
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .navigationTitle(en ? "Regional journeys" : "地圖分區旅程").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }
        .tint(Atlas.mint)
    }

    private func select(_ region: StudyRegion) {
        selected = region
        AudioManager.shared.play(.tap)
    }
}

private struct RegionMap: View {
    @Binding var selected: StudyRegion
    let language: AppLanguage
    private let regions: [StudyRegion] = [.northAmerica, .southAmerica, .europe, .africa, .asia, .oceania]
    private let pins: [WorldCoordinate] = [
        .init(longitude: -107, latitude: 46), .init(longitude: -60, latitude: -18),
        .init(longitude: 13, latitude: 54), .init(longitude: 19, latitude: 4),
        .init(longitude: 93, latitude: 43), .init(longitude: 136, latitude: -27)
    ]

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                ZStack {
                    Canvas { context, size in
                        drawGraticule(in: &context, size: size)
                        for country in WorldMapData.countries {
                            let path = mapPath(for: country, size: size)
                            let isSelected = country.region == selected
                            context.fill(
                                path,
                                with: .color(isSelected ? Atlas.mint.opacity(0.55) : fillColor(for: country.region)),
                                style: FillStyle(eoFill: true)
                            )
                            context.stroke(
                                path,
                                with: .color(isSelected ? Atlas.mint.opacity(0.8) : Color.white.opacity(0.22)),
                                lineWidth: isSelected ? 0.65 : 0.35
                            )
                        }
                    }.accessibilityHidden(true)
                    ForEach(Array(regions.enumerated()), id: \.element) { index, region in
                        Button { select(region) } label: {
                            Group {
                                if geometry.size.width < 430 {
                                    Image(systemName: selected == region ? "mappin.circle.fill" : "mappin.circle")
                                } else {
                                    Label(region.title(language), systemImage: selected == region ? "mappin.circle.fill" : "mappin.circle")
                                        .labelStyle(CompactMapLabelStyle())
                                }
                            }
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(selected == region ? Atlas.ink : .white)
                                .padding(.horizontal, 6).padding(.vertical, 4)
                                .background(selected == region ? Atlas.mint : Atlas.ink.opacity(0.88), in: Capsule())
                                .overlay(Capsule().stroke(.white.opacity(selected == region ? 0 : 0.18)))
                                .frame(minWidth: 44, minHeight: 44)
                        }.buttonStyle(.plain)
                            .accessibilityLabel(region.title(language)).accessibilityAddTraits(selected == region ? .isSelected : [])
                            .position(project(pins[index], size: geometry.size))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            // The cropped Plate Carree map covers 360 degrees of longitude and
            // 141 degrees of latitude. Keeping that ratio prevents compact
            // screens from squeezing the continents horizontally.
            .aspectRatio(360.0 / 141.0, contentMode: .fit)
            VStack(spacing: 2) {
                Text(language == .english ? "DETAILED WORLD MAP · TAP A REGION" : "世界國界圖・點選區域開始探索")
                    .font(.system(.caption2, design: .monospaced)).foregroundStyle(Atlas.muted)
                Text("Natural Earth 1:110m · Public domain")
                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(Atlas.muted.opacity(0.75))
            }
        }.modifier(AtlasCard(tint: Atlas.blue))
    }

    private func select(_ region: StudyRegion) {
        selected = region
        AudioManager.shared.play(.tap)
    }

    private func project(_ coordinate: WorldCoordinate, size: CGSize) -> CGPoint {
        let latitudeTop = 83.0, latitudeBottom = -58.0
        return CGPoint(
            x: (coordinate.longitude + 180) / 360 * size.width,
            y: (latitudeTop - coordinate.latitude) / (latitudeTop - latitudeBottom) * size.height
        )
    }

    private func mapPath(for country: WorldMapCountry, size: CGSize) -> Path {
        var path = Path()
        for polygon in country.polygons {
            for ring in polygon {
                var previous: CGPoint?
                var open = false
                for coordinate in ring {
                    let point = project(coordinate, size: size)
                    if let previous, abs(point.x - previous.x) > size.width * 0.5 {
                        if open { path.closeSubpath() }
                        path.move(to: point)
                    } else if open {
                        path.addLine(to: point)
                    } else {
                        path.move(to: point)
                    }
                    previous = point
                    open = true
                }
                if open { path.closeSubpath() }
            }
        }
        return path
    }

    private func drawGraticule(in context: inout GraphicsContext, size: CGSize) {
        let color = Color.white.opacity(0.07)
        for longitude in stride(from: -120.0, through: 120.0, by: 60) {
            var path = Path()
            path.move(to: project(.init(longitude: longitude, latitude: 83), size: size))
            path.addLine(to: project(.init(longitude: longitude, latitude: -58), size: size))
            context.stroke(path, with: .color(color), lineWidth: 0.5)
        }
        for latitude in stride(from: -30.0, through: 60.0, by: 30) {
            var path = Path()
            path.move(to: project(.init(longitude: -180, latitude: latitude), size: size))
            path.addLine(to: project(.init(longitude: 180, latitude: latitude), size: size))
            context.stroke(path, with: .color(color), lineWidth: 0.5)
        }
    }

    private func fillColor(for region: StudyRegion?) -> Color {
        switch region {
        case .asia: return Atlas.blue.opacity(0.24)
        case .europe: return Atlas.gold.opacity(0.2)
        case .africa: return Color.orange.opacity(0.18)
        case .northAmerica: return Color.cyan.opacity(0.18)
        case .southAmerica: return Color.pink.opacity(0.16)
        case .oceania: return Color.purple.opacity(0.18)
        case nil: return Color.white.opacity(0.08)
        }
    }
}

struct FlagLibraryView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var region: StudyRegion?
    @State private var selectedCountry: Country?
    private let countries = ((try? CountryRepository.load()) ?? []).sorted { $0.en < $1.en }
    private var en: Bool { settings.language == .english }

    private var filteredCountries: [Country] {
        countries.filter { country in
            let isInRegion = region.map { $0.codes.contains(country.abb2) } ?? true
            let terms = [country.cn, country.en, country.full, country.abb2, country.abb3]
            return isInRegion && (query.isEmpty || terms.contains { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 145, maximum: 210), spacing: 14)]
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Eyebrow(text: en ? "THE WORLD, FLAG BY FLAG" : "一面一面，看見世界")
                    Text(en ? "Flag atlas" : "世界國旗圖鑑").font(.largeTitle.bold())
                    Text(en ? "Browse all \(countries.count) flags. Search by country name or code, or narrow the atlas to one region." : "瀏覽全部 \(countries.count) 面國旗；可搜尋國名、國家代碼，或依洲別篩選。")
                        .font(.subheadline).foregroundStyle(Atlas.muted)
                    regionFilters
                    HStack {
                        Text(en ? "\(filteredCountries.count) flags" : "\(filteredCountries.count) 面國旗")
                            .font(.subheadline.bold())
                        Spacer()
                        if !query.isEmpty || region != nil {
                            Button(en ? "Clear" : "清除篩選") { query = ""; region = nil }
                                .font(.caption.bold()).foregroundStyle(Atlas.mint)
                        }
                    }
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filteredCountries) { country in
                            Button { selectedCountry = country } label: {
                                FlagLibraryCard(country: country, language: settings.language)
                            }
                            .buttonStyle(AtlasPressStyle())
                        }
                    }
                    if filteredCountries.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 50)
                    }
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(en ? "All flags" : "所有國旗").navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: en ? "Country or code" : "搜尋國名或代碼")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }
        .sheet(item: $selectedCountry) { country in FlagDetailView(country: country) }
        .tint(Atlas.mint)
    }

    private var regionFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(title: en ? "All" : "全部", value: nil)
                ForEach(StudyRegion.allCases) { item in
                    filterButton(title: item.title(settings.language), value: item)
                }
            }
        }
    }

    private func filterButton(title: String, value: StudyRegion?) -> some View {
        Button {
            region = value
            AudioManager.shared.play(.tap)
        } label: {
            Text(title).font(.caption.bold()).padding(.horizontal, 14).padding(.vertical, 9)
                .foregroundStyle(region == value ? Atlas.ink : .white)
                .background(region == value ? Atlas.mint : Atlas.panel, in: Capsule())
                .overlay(Capsule().stroke(Atlas.mint.opacity(region == value ? 0 : 0.22)))
        }.buttonStyle(AtlasPressStyle(sound: nil))
    }
}

private struct FlagLibraryCard: View {
    let country: Country
    let language: AppLanguage
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlagImage(code: country.abb2).frame(maxWidth: .infinity).aspectRatio(3 / 2, contentMode: .fit)
            Text(country.name(for: language)).font(.subheadline.bold()).lineLimit(2)
            Text("\(country.abb2) · \(country.abb3)")
                .font(.system(.caption2, design: .monospaced)).foregroundStyle(Atlas.muted)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Atlas.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
    }
}

private struct FlagDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let country: Country
    private var en: Bool { settings.language == .english }
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 24) {
                    FlagImage(code: country.abb2).frame(maxWidth: 420).aspectRatio(3 / 2, contentMode: .fit)
                    VStack(spacing: 7) {
                        Text(country.name(for: settings.language)).font(.title.bold()).multilineTextAlignment(.center)
                        if !en { Text(country.en).foregroundStyle(Atlas.muted) }
                        Text("\(country.abb2)  ·  \(country.abb3)  ·  \(country.code)")
                            .font(.system(.subheadline, design: .monospaced)).foregroundStyle(Atlas.gold)
                    }
                    Spacer()
                }.padding(24)
            }
            .foregroundStyle(.white).navigationTitle(en ? "Flag details" : "國旗資訊").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }
        }.presentationDetents([.medium, .large]).tint(Atlas.mint)
    }
}

private struct CompactMapLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) { configuration.icon; configuration.title }.fixedSize()
    }
}

struct ComparisonLibraryView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    private let countries = (try? CountryRepository.load()) ?? []
    let start: (PracticePlan) -> Void
    private var en: Bool { settings.language == .english }
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Eyebrow(text: en ? "LOOK AGAIN. SPOT THE CLUE." : "多看一眼，就能找到線索")
                    Text(en ? "Similar, but different." : "很像，卻不一樣。") .font(.largeTitle.bold())
                    Text(en ? "Name both flags before revealing the clue. Then try a two-question practice round." : "先試著說出兩面國旗的名字，再揭曉辨識線索。最後用兩題小練習確認自己記住了。")
                        .font(.subheadline).foregroundStyle(Atlas.muted)
                    ForEach(FlagComparison.all) { pair in
                        if pair.codes.isSubset(of: Set(countries.map(\.abb2))) {
                            ComparisonCard(pair: pair, countries: countries) { start(.comparison(pair)) }
                        }
                    }
                    if countries.isEmpty { Text(en ? "Flag data could not be loaded." : "無法載入國旗資料。") }
                }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .navigationTitle(en ? "Flag comparisons" : "相似國旗對照").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }.tint(Atlas.mint)
    }
}

struct ComparisonCard: View {
    @EnvironmentObject private var settings: AppSettings
    let pair: FlagComparison
    let countries: [Country]
    var initiallyRevealed = false
    var practice: (() -> Void)? = nil
    @State private var revealed = false
    private var show: Bool { initiallyRevealed || revealed }
    private var en: Bool { settings.language == .english }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ForEach([pair.first, pair.second], id: \.self) { code in
                    if let country = countries.first(where: { $0.abb2 == code }) {
                        VStack(spacing: 10) {
                            FlagImage(code: code).frame(height: 84)
                            Text(show ? country.name(for: settings.language) : "?")
                                .font(.subheadline.bold()).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity)
                    }
                }
            }
            if show {
                Label(en ? "The key difference" : "辨識關鍵", systemImage: "eye").font(.headline).foregroundStyle(Atlas.gold)
                Text(pair.clue(settings.language)).font(.subheadline).lineSpacing(4)
                if let practice { Button(en ? "Practice these 2 flags" : "練習這 2 面國旗", action: practice).buttonStyle(AtlasButtonStyle(filled: true)) }
            } else {
                Button(en ? "Reveal names & clue" : "揭曉名稱與辨識線索") { revealed = true }.buttonStyle(AtlasButtonStyle(tint: Atlas.gold))
            }
        }.modifier(AtlasCard(tint: Atlas.gold))
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.arguments.contains("--preview-revealed") { revealed = true } }
        #endif
    }
}
