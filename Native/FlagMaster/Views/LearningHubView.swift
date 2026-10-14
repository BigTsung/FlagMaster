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
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: geometry.size.height < 720 ? 10 : 14) {
                    Eyebrow(text: "WORLD TOUR / SELECT STAGE", color: Atlas.mint)
                    Text(en ? "Choose your arena" : "選擇你的挑戰區域").font(.system(.title2, design: .rounded).weight(.black))
                    RegionMap(selected: $selected, language: settings.language)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(StudyRegion.allCases) { region in
                            let members = region.countries(in: countries)
                            let explored = members.filter { stats.stats[$0.abb2] != nil }.count
                            Button { select(region) } label: {
                                HStack(spacing: 6) {
                                    Text(region.title(settings.language)).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.72)
                                    Spacer(minLength: 0)
                                    Text("\(explored)/\(members.count)").font(.caption2.monospacedDigit()).foregroundStyle(Atlas.muted)
                                    if selected == region { Image(systemName: "checkmark.circle.fill").foregroundStyle(Atlas.mint) }
                                }.padding(12).frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                                    .modifier(GamePanel(tint: selected == region ? Atlas.mint : Atlas.violet, radius: 16))
                            }.buttonStyle(AtlasPressStyle(sound: nil)).accessibilityAddTraits(selected == region ? .isSelected : [])
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selected.title(settings.language)).font(.headline)
                        HStack {
                            Metric(value: "\(min(10, pool.count))", label: en ? "Flags this trip" : "本趟題數")
                            Metric(value: "\(pool.filter { stats.stats[$0.abb2]?.isMastered == true }.count)", label: en ? "Familiar flags" : "熟悉國旗", color: Atlas.gold)
                        }
                        Button { start(.region(selected)) } label: {
                            Label(en ? "ENTER STAGE" : "進入關卡", systemImage: "play.fill")
                        }.buttonStyle(AtlasButtonStyle(filled: true)).disabled(pool.count < 4)
                    }.modifier(AtlasCard(tint: Atlas.mint))
                }.padding(.horizontal, 20).padding(.vertical, 10).frame(maxWidth: 760, maxHeight: .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .navigationTitle(en ? "Regional journeys" : "地圖分區旅程").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }
        .tint(Atlas.mint)
        .modifier(GameScreen(title: en ? "WORLD TOUR" : "世界闖關", symbol: "globe.asia.australia.fill", tint: Atlas.mint))
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
        }.padding(10).background(Atlas.panel, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Atlas.blue.opacity(0.15)))
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
    @State private var page = 0
    private let countries = ((try? CountryRepository.load()) ?? []).sorted { $0.en < $1.en }
    private var en: Bool { settings.language == .english }

    private var filteredCountries: [Country] {
        countries.filter { country in
            let isInRegion = region.map { $0.codes.contains(country.abb2) } ?? true
            let terms = [country.cn, country.en, country.full, country.abb2, country.abb3]
            return isInRegion && (query.isEmpty || terms.contains { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    @State private var pageSize = 6
    private var pageCount: Int { max(1, Int(ceil(Double(filteredCountries.count) / Double(pageSize)))) }
    private var pageCountries: [Country] {
        let safePage = min(page, pageCount - 1), start = safePage * pageSize
        return Array(filteredCountries.dropFirst(start).prefix(pageSize))
    }

    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: geometry.size.height < 720 ? 10 : 14) {
                    Eyebrow(text: "FLAG COLLECTION", color: Atlas.blue)
                    HStack {
                        Text(en ? "Your world of flags" : "世界國旗圖鑑").font(.system(.title2, design: .rounded).weight(.black))
                        Spacer()
                        regionFilter
                    }
                    HStack {
                        Text(en ? "\(filteredCountries.count) flags" : "\(filteredCountries.count) 面國旗")
                            .font(.subheadline.bold())
                        Spacer()
                        if !query.isEmpty || region != nil {
                            Button(en ? "Clear" : "清除篩選") { query = ""; region = nil; page = 0 }
                                .font(.caption.bold()).foregroundStyle(Atlas.mint)
                        }
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Atlas.blue)
                        TextField(en ? "Country or code" : "搜尋國名或代碼", text: $query)
                            .font(.subheadline).autocorrectionDisabled().submitLabel(.search)
                        if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel(en ? "Clear search" : "清除搜尋") }
                    }.padding(12).modifier(GamePanel(tint: Atlas.blue, radius: 14))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(pageCountries) { country in
                            Button { selectedCountry = country } label: {
                                FlagLibraryCard(country: country, language: settings.language)
                            }
                            .buttonStyle(AtlasPressStyle(sound: nil))
                        }
                    }
                    Spacer(minLength: 0)
                    HStack {
                        Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 40) }
                            .buttonStyle(AtlasPressStyle(sound: nil)).disabled(page == 0)
                        Spacer()
                        Text("\(min(page + 1, pageCount)) / \(pageCount)").font(.caption.monospacedDigit()).foregroundStyle(Atlas.muted)
                        Spacer()
                        Button { page = min(pageCount - 1, page + 1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 40) }
                            .buttonStyle(AtlasPressStyle(sound: nil)).disabled(page >= pageCount - 1)
                    }.padding(.horizontal, 8).background(Atlas.panel, in: Capsule())
                    if filteredCountries.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                }.padding(.horizontal, 20).padding(.vertical, 10).frame(maxWidth: 760, maxHeight: .infinity).frame(maxWidth: .infinity)
                    .onChange(of: geometry.size.height, initial: true) { _, height in
                        let nextSize = height < 480 ? 2 : height < 650 ? 4 : 6
                        if pageSize != nextSize { pageSize = nextSize; page = 0 }
                    }
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(en ? "All flags" : "所有國旗").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }
        .fullScreenCover(item: $selectedCountry) { country in
            FlagDetailView(country: country).environment(\.gameDismiss, nil)
        }
        .onChange(of: query) { _, _ in page = 0 }
        .onChange(of: region) { _, _ in page = 0 }
        .tint(Atlas.mint)
        .modifier(GameScreen(title: en ? "COLLECTION" : "國旗收藏室", symbol: "square.stack.3d.up.fill", tint: Atlas.blue))
    }

    private var regionFilter: some View {
        Menu {
            Button(en ? "All regions" : "全部地區") { region = nil }
            ForEach(StudyRegion.allCases) { item in
                Button(item.title(settings.language)) { region = item }
            }
        } label: {
            Label(region?.title(settings.language) ?? (en ? "All" : "全部"), systemImage: "line.3.horizontal.decrease.circle")
                .font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 9)
                .background(Atlas.panel, in: Capsule())
        }
    }
}

private struct FlagLibraryCard: View {
    let country: Country
    let language: AppLanguage
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(country.abb3).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(Atlas.blue)
                Spacer()
                Image(systemName: "sparkle").font(.system(size: 9)).foregroundStyle(Atlas.gold)
            }
            FlagImage(code: country.abb2).frame(maxWidth: .infinity).frame(height: 55)
                .shadow(color: .black.opacity(0.3), radius: 5, y: 4)
            Text(country.name(for: language)).font(.system(size: 13, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.65)
            Label(language == .english ? "Locate" : "查看位置", systemImage: "mappin.and.ellipse")
                .font(.system(size: 9, weight: .semibold)).foregroundStyle(Atlas.muted)
        }
        .padding(10).frame(maxWidth: .infinity, minHeight: 125, alignment: .leading)
        .modifier(GamePanel(tint: Atlas.blue, radius: 18))
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
                VStack(spacing: 16) {
                    Eyebrow(text: "WORLD COLLECTION / " + country.abb3, color: Atlas.gold)
                    FlagImage(code: country.abb2).frame(maxWidth: 300, maxHeight: 150).aspectRatio(3 / 2, contentMode: .fit)
                    VStack(spacing: 7) {
                        Text(country.name(for: settings.language)).font(.title.bold()).multilineTextAlignment(.center)
                        if !en { Text(country.en).foregroundStyle(Atlas.muted) }
                        Text("\(country.abb2)  ·  \(country.abb3)  ·  \(country.code)")
                            .font(.system(.subheadline, design: .monospaced)).foregroundStyle(Atlas.gold)
                    }
                    CountryLocationMap(country: country)
                        .frame(maxWidth: 430).aspectRatio(2.35, contentMode: .fit)
                    Label(en ? "Highlighted on the world map" : "在世界地圖上的位置", systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(Atlas.muted)
                    Spacer()
                }.padding(24)
            }
            .foregroundStyle(.white).navigationTitle(en ? "Flag details" : "國旗資訊").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }
            .modifier(GameScreen(title: en ? "FLAG DISCOVERY" : "國旗探索", symbol: "mappin.and.ellipse", tint: Atlas.blue))
        }.tint(Atlas.mint)
    }
}

private struct CountryLocationMap: View {
    let country: Country
    private let latitudeTop = 83.0, latitudeBottom = -58.0

    var body: some View {
        Canvas { context, size in
            let selected = WorldMapData.mapCountry(for: country)
            for mapCountry in WorldMapData.countries {
                let path = path(for: mapCountry, size: size)
                let highlighted = selected.map { $0.name == mapCountry.name } ?? false
                context.fill(path, with: .color(highlighted ? Atlas.mint.opacity(0.9) : Color.white.opacity(0.10)), style: FillStyle(eoFill: true))
                context.stroke(path, with: .color(highlighted ? Atlas.mint : Color.white.opacity(0.18)), lineWidth: highlighted ? 0.8 : 0.3)
            }
            let marker = project(WorldMapData.marker(for: country), size: size)
            let glow = CGRect(x: marker.x - 8, y: marker.y - 8, width: 16, height: 16)
            context.fill(Path(ellipseIn: glow), with: .color(Atlas.gold.opacity(0.25)))
            context.fill(Path(ellipseIn: CGRect(x: marker.x - 3, y: marker.y - 3, width: 6, height: 6)), with: .color(Atlas.gold))
        }
        .padding(8).background(Atlas.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Atlas.mint.opacity(0.18)))
        .accessibilityLabel(country.name(for: .traditionalChinese) + "在世界地圖上的位置")
    }

    private func project(_ coordinate: WorldCoordinate, size: CGSize) -> CGPoint {
        CGPoint(x: (coordinate.longitude + 180) / 360 * size.width,
                y: (latitudeTop - coordinate.latitude) / (latitudeTop - latitudeBottom) * size.height)
    }

    private func path(for country: WorldMapCountry, size: CGSize) -> Path {
        var result = Path()
        for polygon in country.polygons {
            for ring in polygon {
                var previous: CGPoint?
                for (index, coordinate) in ring.enumerated() {
                    let point = project(coordinate, size: size)
                    if index == 0 || (previous.map { abs(point.x - $0.x) > size.width * 0.5 } ?? false) { result.move(to: point) }
                    else { result.addLine(to: point) }
                    previous = point
                }
                result.closeSubpath()
            }
        }
        return result
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
    @State private var page = 0
    let start: (PracticePlan) -> Void
    private var en: Bool { settings.language == .english }
    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow(text: "TRAINING / SPOT THE DIFFERENCE", color: Atlas.coral)
                    Text(en ? "Can you tell them apart?" : "你能看出差別嗎？").font(.system(.title2, design: .rounded).weight(.black))
                    if !FlagComparison.all.isEmpty {
                        let pair = FlagComparison.all[page]
                        ComparisonCard(pair: pair, countries: countries) { start(.comparison(pair)) }.id(pair.first + pair.second)
                        Spacer(minLength: 0)
                        HStack {
                            Button { page = max(0, page - 1) } label: { Label(en ? "Previous" : "上一組", systemImage: "chevron.left") }
                                .buttonStyle(AtlasPressStyle(sound: nil)).disabled(page == 0)
                            Spacer()
                            Text("\(page + 1) / \(FlagComparison.all.count)").font(.caption.monospacedDigit()).foregroundStyle(Atlas.muted)
                            Spacer()
                            Button { page = min(FlagComparison.all.count - 1, page + 1) } label: { Label(en ? "Next" : "下一組", systemImage: "chevron.right") }
                                .labelStyle(.titleAndIcon).buttonStyle(AtlasPressStyle(sound: nil)).disabled(page == FlagComparison.all.count - 1)
                        }.padding(14).background(Atlas.panel, in: Capsule())
                    }
                    if countries.isEmpty { Text(en ? "Flag data could not be loaded." : "無法載入國旗資料。") }
                }.padding(20).frame(maxWidth: 760, maxHeight: .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
        .navigationTitle(en ? "Flag comparisons" : "相似國旗對照").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(en ? "Done" : "完成") { dismiss() } } }.tint(Atlas.mint)
        .modifier(GameScreen(title: en ? "TRAINING ARENA" : "辨識特訓場", symbol: "scope", tint: Atlas.coral))
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
            HStack { Spacer(); Text("VS").font(.system(size: 30, weight: .black, design: .rounded)).italic().foregroundStyle(Atlas.gold); Spacer() }
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
