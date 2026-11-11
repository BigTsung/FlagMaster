import SwiftUI

struct JourneyPickerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected: StudyRegion = .asia
    private let countries = (try? CountryRepository.load()) ?? []
    let start: (PracticePlan) -> Void
    private var pool: [Country] { selected.countries(in: countries) }

    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: geometry.size.height < 720 ? 10 : 14) {
                    Eyebrow(text: settings.language.text("WORLD TOUR / SELECT STAGE", "世界闖關 / 選擇關卡", ja: "世界ツアー / ステージ選択", ko: "세계 투어 / 스테이지 선택"), color: Atlas.mint)
                    Text(settings.language.text("Choose your arena", "選擇你的挑戰區域", ja: "地域を選ぼう", ko: "도전할 지역을 고르세요")).font(.system(.title2, design: .rounded).weight(.black))
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
                                    .modifier(GamePanel(tint: selected == region ? Atlas.mint : Atlas.accent, radius: 16))
                            }.buttonStyle(AtlasPressStyle(sound: nil)).accessibilityAddTraits(selected == region ? .isSelected : [])
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selected.title(settings.language)).font(.headline)
                        HStack {
                            Metric(value: "\(min(10, pool.count))", label: settings.language.text("Flags this trip", "本趟題數", ja: "今回の問題数", ko: "이번 문제 수"))
                            Metric(value: "\(pool.filter { stats.stats[$0.abb2]?.isMastered == true }.count)", label: settings.language.text("Familiar flags", "熟悉國旗", ja: "覚えた国旗", ko: "익숙한 국기"), color: Atlas.gold)
                        }
                        Button { start(.region(selected)) } label: {
                            Label(settings.language.text("ENTER STAGE", "進入關卡", ja: "ステージ開始", ko: "스테이지 시작"), systemImage: "play.fill")
                        }.buttonStyle(AtlasButtonStyle(filled: true))
                            .modifier(ActionHint())
                            .disabled(pool.count < 4)
                    }.modifier(AtlasCard(tint: Atlas.mint))
                }.padding(.horizontal, 20).padding(.vertical, 10).frame(maxWidth: 760, maxHeight: .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(Atlas.text)
        .navigationTitle(settings.language.text("Regional journeys", "地圖分區旅程", ja: "地域別の旅", ko: "지역별 탐험")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language.text("Done", "完成", ja: "完了", ko: "완료")) { dismiss() } } }
        .tint(Atlas.mint)
        .modifier(GameScreen(title: settings.language.text("WORLD TOUR", "世界闖關", ja: "世界ツアー", ko: "세계 투어"), symbol: "globe.asia.australia.fill", tint: Atlas.mint))
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
                                with: .color(isSelected ? Atlas.mint.opacity(0.8) : Atlas.text.opacity(0.22)),
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
                                .foregroundStyle(selected == region ? Atlas.ink : Atlas.text)
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
        let color = Atlas.text.opacity(0.07)
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
        case .oceania: return Atlas.mint.opacity(0.22)
        case nil: return Atlas.text.opacity(0.08)
        }
    }
}

struct FlagLibraryView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var region: StudyRegion?
    @State private var selectedCountry: Country?
    @State private var showingFlashcards = false
    @State private var page = 0
    private let countries = ((try? CountryRepository.load()) ?? []).sorted { $0.en < $1.en }

    private var filteredCountries: [Country] {
        countries.filter { country in
            let isInRegion = region.map { $0.codes.contains(country.abb2) } ?? true
            guard isInRegion else { return false }
            if query.isEmpty { return true }
            let terms = [country.full, country.abb2, country.abb3] + AppLanguage.allCases.map { country.name(for: $0) }
            return terms.contains { $0.localizedCaseInsensitiveContains(query) }
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
                    HStack {
                        Eyebrow(text: settings.language.text("FLAG COLLECTION", "國旗圖鑑", ja: "国旗図鑑", ko: "국기 도감"), color: Atlas.blue)
                        Spacer()
                        Button { showingFlashcards = true } label: {
                            Label(settings.language.text("Study cards", "圖卡學習", ja: "学習カード", ko: "학습 카드"), systemImage: "rectangle.on.rectangle.angled")
                                .font(.caption.bold()).frame(minHeight: 44)
                        }.disabled(filteredCountries.isEmpty)
                    }
                    HStack {
                        Text(settings.language.text("Your world of flags", "世界國旗圖鑑", ja: "世界の国旗図鑑", ko: "세계 국기 도감")).font(.system(.title2, design: .rounded).weight(.black))
                        Spacer()
                        regionFilter
                    }
                    HStack {
                        Text(settings.language.text("\(filteredCountries.count) flags", "\(filteredCountries.count) 面國旗", ja: "国旗 \(filteredCountries.count) 面", ko: "국기 \(filteredCountries.count)개"))
                            .font(.subheadline.bold())
                        Spacer()
                        if !query.isEmpty || region != nil {
                            Button(settings.language.text("Clear", "清除篩選", ja: "絞り込みを解除", ko: "필터 초기화")) { query = ""; region = nil; page = 0 }
                                .font(.caption.bold()).foregroundStyle(Atlas.mint)
                        }
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Atlas.blue)
                        TextField(settings.language.text("Country or code", "搜尋國名或代碼", ja: "国名またはコード", ko: "나라 이름 또는 코드"), text: $query)
                            .font(.subheadline).autocorrectionDisabled().submitLabel(.search)
                        if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel(settings.language.text("Clear search", "清除搜尋", ja: "検索をクリア", ko: "검색 지우기")) }
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
                            .foregroundStyle(Atlas.text)
                            .frame(maxWidth: .infinity)
                    }
                }.padding(.horizontal, 20).padding(.vertical, 10).frame(maxWidth: 760, maxHeight: .infinity).frame(maxWidth: .infinity)
                    .onChange(of: geometry.size.height, initial: true) { _, height in
                        let nextSize = height < 480 ? 2 : height < 650 ? 4 : 6
                        if pageSize != nextSize { pageSize = nextSize; page = 0 }
                    }
            }
        }
        .foregroundStyle(Atlas.text)
        .navigationTitle(settings.language.text("All flags", "所有國旗", ja: "すべての国旗", ko: "모든 국기")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language.text("Done", "完成", ja: "完了", ko: "완료")) { dismiss() } } }
        .fullScreenCover(isPresented: $showingFlashcards, onDismiss: {
            AudioManager.shared.playMusic(.home)
        }) {
            FlagFlashcardsView(countries: filteredCountries)
                .onAppear { AudioManager.shared.playMusic(.cards) }
        }
        .fullScreenCover(item: $selectedCountry) { country in
            FlagDetailView(country: country).environment(\.gameDismiss, nil)
        }
        #if DEBUG
        .task {
            guard ProcessInfo.processInfo.arguments.contains("--preview-card-lifecycle") else { return }
            do {
                try await Task.sleep(for: .seconds(1))
                let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
                let originalOrientation = scene?.interfaceOrientation
                showingFlashcards = true
                try await Task.sleep(for: .seconds(3))
                assert(scene?.interfaceOrientation.isLandscape == true)
                FileHandle.standardError.write(Data("PASS: study cards entered landscape\n".utf8))
                showingFlashcards = false
                try await Task.sleep(for: .seconds(3))
                assert(scene?.interfaceOrientation == originalOrientation)
                assert(FlagMasterAppDelegate.landscapeScenes.isEmpty)
                FileHandle.standardError.write(Data("PASS: closing study cards restored orientation\n".utf8))
            } catch { return }
        }
        #endif
        .onChange(of: query) { _, _ in page = 0 }
        .onChange(of: region) { _, _ in page = 0 }
        .tint(Atlas.mint)
        .modifier(GameScreen(title: settings.language.text("COLLECTION", "國旗收藏室", ja: "国旗コレクション", ko: "국기 컬렉션"), symbol: "square.stack.3d.up.fill", tint: Atlas.blue))
    }

    private var regionFilter: some View {
        Menu {
            Button(settings.language.text("All regions", "全部地區", ja: "すべての地域", ko: "모든 지역")) { region = nil }
            ForEach(StudyRegion.allCases) { item in
                Button(item.title(settings.language)) { region = item }
            }
        } label: {
            Label(region?.title(settings.language) ?? (settings.language.text("All", "全部", ja: "すべて", ko: "전체")), systemImage: "line.3.horizontal.decrease.circle")
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
            HStack(spacing: 8) {
                FlagImage(code: country.abb2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .shadow(color: .black.opacity(0.3), radius: 5, y: 4)
                CountryLocationMap(country: country, compact: true)
                    .aspectRatio(2.35, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)
            }
            .frame(height: 55)
            Text(country.name(for: language)).font(.system(size: 13, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.65)
            Label(language.text("Locate", "查看位置", ja: "場所を表示", ko: "위치 보기"), systemImage: "mappin.and.ellipse")
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
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 16) {
                    Eyebrow(text: settings.language.text("WORLD COLLECTION / ", "世界圖鑑 / ", ja: "世界の国旗図鑑 / ", ko: "세계 국기 도감 / ") + country.abb3, color: Atlas.gold)
                    FlagImage(code: country.abb2).frame(maxWidth: 300, maxHeight: 150).aspectRatio(3 / 2, contentMode: .fit)
                    VStack(spacing: 7) {
                        Text(country.name(for: settings.language)).font(.title.bold()).multilineTextAlignment(.center)
                        if settings.language != .english { Text(country.en).foregroundStyle(Atlas.muted) }
                        Text("\(country.abb2)  ·  \(country.abb3)  ·  \(country.code)")
                            .font(.system(.subheadline, design: .monospaced)).foregroundStyle(Atlas.gold)
                    }
                    CountryLocationMap(country: country)
                        .frame(maxWidth: 430).aspectRatio(2.35, contentMode: .fit)
                    Label(settings.language.text("Highlighted on the world map", "在世界地圖上的位置", ja: "世界地図上の位置", ko: "세계 지도에서의 위치"), systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(Atlas.muted)
                    Spacer()
                }.padding(24)
            }
            .foregroundStyle(Atlas.text).navigationTitle(settings.language.text("Flag details", "國旗資訊", ja: "国旗の詳細", ko: "국기 정보")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language.text("Done", "完成", ja: "完了", ko: "완료")) { dismiss() } } }
            .modifier(GameScreen(title: settings.language.text("FLAG DISCOVERY", "國旗探索", ja: "国旗を探そう", ko: "국기 탐험"), symbol: "mappin.and.ellipse", tint: Atlas.blue))
        }.tint(Atlas.mint)
    }
}

private struct CountryLocationMap: View {
    @EnvironmentObject private var settings: AppSettings
    let country: Country
    var compact = false
    private let latitudeTop = 83.0, latitudeBottom = -58.0

    var body: some View {
        Canvas { context, size in
            let selected = WorldMapData.mapCountry(for: country)
            for mapCountry in WorldMapData.countries {
                let path = path(for: mapCountry, size: size)
                let highlighted = selected.map { $0.name == mapCountry.name } ?? false
                context.fill(path, with: .color(highlighted ? Atlas.mint.opacity(0.9) : Atlas.text.opacity(0.10)), style: FillStyle(eoFill: true))
                context.stroke(path, with: .color(highlighted ? Atlas.mint : Atlas.text.opacity(0.18)), lineWidth: highlighted ? 0.8 : 0.3)
            }
            let marker = project(WorldMapData.marker(for: country), size: size)
            let radius: CGFloat = compact ? 5 : 8
            let glow = CGRect(x: marker.x - radius, y: marker.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: glow), with: .color(Atlas.gold.opacity(0.25)))
            context.fill(Path(ellipseIn: CGRect(x: marker.x - 3, y: marker.y - 3, width: 6, height: 6)), with: .color(Atlas.gold))
        }
        .padding(compact ? 4 : 8)
        .background(Atlas.panel, in: RoundedRectangle(cornerRadius: compact ? 8 : 18))
        .overlay(RoundedRectangle(cornerRadius: compact ? 8 : 18).stroke(Atlas.mint.opacity(0.18)))
        .accessibilityLabel(country.name(for: settings.language) + " · " + settings.language.text("Location on the world map", "在世界地圖上的位置", ja: "世界地図上の位置", ko: "세계 지도에서의 위치"))
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
    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow(text: settings.language.text("TRAINING / SPOT THE DIFFERENCE", "辨識特訓 / 找出差異", ja: "トレーニング / 違いを見分けよう", ko: "훈련 / 차이점 찾기"), color: Atlas.coral)
                    Text(settings.language.text("Can you tell them apart?", "你能看出差別嗎？", ja: "違いがわかるかな？", ko: "어떤 차이가 있을까요?")).font(.system(.title2, design: .rounded).weight(.black))
                    if !FlagComparison.all.isEmpty {
                        let pair = FlagComparison.all[page]
                        ComparisonCard(pair: pair, countries: countries) { start(.comparison(pair)) }.id(pair.first + pair.second)
                        Spacer(minLength: 0)
                        HStack {
                            Button { page = max(0, page - 1) } label: { Label(settings.language.text("Previous", "上一組", ja: "前の組", ko: "이전 쌍"), systemImage: "chevron.left") }
                                .buttonStyle(AtlasPressStyle(sound: nil)).disabled(page == 0)
                            Spacer()
                            Text("\(page + 1) / \(FlagComparison.all.count)").font(.caption.monospacedDigit()).foregroundStyle(Atlas.muted)
                            Spacer()
                            Button { page = min(FlagComparison.all.count - 1, page + 1) } label: { Label(settings.language.text("Next", "下一組", ja: "次の組", ko: "다음 쌍"), systemImage: "chevron.right") }
                                .labelStyle(.titleAndIcon).buttonStyle(AtlasPressStyle(sound: nil)).disabled(page == FlagComparison.all.count - 1)
                        }.padding(14).background(Atlas.panel, in: Capsule())
                    }
                    if countries.isEmpty { Text(settings.language.text("Flag data could not be loaded.", "無法載入國旗資料。", ja: "国旗データを読み込めませんでした。", ko: "국기 데이터를 불러오지 못했어요.")) }
                }.padding(20).frame(maxWidth: 760, maxHeight: .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(Atlas.text)
        .navigationTitle(settings.language.text("Flag comparisons", "相似國旗對照", ja: "似ている国旗の比較", ko: "비슷한 국기 비교")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.language.text("Done", "完成", ja: "完了", ko: "완료")) { dismiss() } } }.tint(Atlas.mint)
        .modifier(GameScreen(title: settings.language.text("TRAINING ARENA", "辨識特訓場", ja: "国旗トレーニング", ko: "국기 훈련장"), symbol: "scope", tint: Atlas.coral))
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
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Spacer(); Text(settings.language.text("VS", "對照", ja: "比較", ko: "비교")).font(.system(size: 30, weight: .black, design: .rounded)).italic().foregroundStyle(Atlas.gold); Spacer() }
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
                Label(settings.language.text("The key difference", "辨識關鍵", ja: "見分けるポイント", ko: "구별하는 요령"), systemImage: "eye").font(.headline).foregroundStyle(Atlas.gold)
                Text(pair.clue(settings.language)).font(.subheadline).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                if let practice { Button(settings.language.text("Practice these 2 flags", "練習這 2 面國旗", ja: "この 2 面を練習する", ko: "이 국기 2개 연습하기"), action: practice).buttonStyle(AtlasButtonStyle(filled: true)) }
            } else {
                Button(settings.language.text("Reveal names & clue", "揭曉名稱與辨識線索", ja: "名前とヒントを見る", ko: "이름과 힌트 보기")) { revealed = true }.buttonStyle(AtlasButtonStyle(tint: Atlas.gold))
                    .modifier(ActionHint())
            }
        }.modifier(AtlasCard(tint: Atlas.gold))
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.arguments.contains("--preview-revealed") { revealed = true } }
        #endif
    }
}

/// A snapshot of the library's filtered deck, in the same order as the collection.
struct FlagFlashcardsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let countries: [Country]
    @State private var index = 0
    @State private var turn: CardTurn?
    @State private var waitingForLandscape = true
    @State private var informationCountry: Country?
    private let paper = Atlas.panel

    private struct CardTurn {
        static let duration = 0.28
        let previousIndex: Int
        let direction: Double
        let started: Date
    }

    private var turning: Bool { turn != nil }

    private var previousTitle: String { settings.language.text("Previous", "上一張", ja: "前へ", ko: "이전") }
    private var nextTitle: String { settings.language.text("Next", "下一張", ja: "次へ", ko: "다음") }

    var body: some View {
        ZStack {
            AppBackground()
            GeometryReader { geometry in
                let portraitWindow = geometry.size.height > geometry.size.width
                let canvasWidth = max(geometry.size.width, geometry.size.height)
                let canvasHeight = min(geometry.size.width, geometry.size.height)
                VStack(spacing: 8) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(settings.language.text("Close", "關閉", ja: "閉じる", ko: "닫기"))
                        Text(settings.language.text("Study cards", "圖卡學習", ja: "学習カード", ko: "학습 카드")).font(.headline)
                        Spacer()
                        if !countries.isEmpty {
                            Button { showInformation() } label: {
                                Image(systemName: "info.circle").font(.title2).frame(width: 44, height: 44)
                            }
                            .accessibilityLabel(settings.language.text("About this flag", "認識這面國旗", ja: "この国旗について", ko: "이 국기 알아보기"))
                            .disabled(turning)
                            Text("\(index + 1) / \(countries.count)").font(.subheadline.monospacedDigit())
                        }
                    }.foregroundStyle(Atlas.mint)
                    if countries.isEmpty {
                        ContentUnavailableView(settings.language.text("No flags", "沒有可學習的國旗", ja: "国旗がありません", ko: "국기가 없습니다"), systemImage: "flag.slash")
                    } else {
                        let cardWidth = max(1, min(960, canvasWidth - 144, (canvasHeight - 100) * 1.7))
                        HStack(spacing: 16) {
                            navigationButton(-1)
                            Spacer(minLength: 0)
                            deck(height: cardWidth / 1.7).frame(width: cardWidth)
                            Spacer(minLength: 0)
                            navigationButton(1)
                        }.frame(maxHeight: .infinity)
                        Text(settings.language.text("Tap either side of the card or swipe left / right", "點卡片左右兩側，或左右滑動換卡", ja: "カードの左右をタップ、または左右にスワイプ", ko: "카드 양쪽을 탭하거나 좌우로 밀어보세요"))
                            .font(.caption).foregroundStyle(Atlas.muted).lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 8)
                .frame(width: canvasWidth, height: canvasHeight)
                .allowsHitTesting(informationCountry == nil)
                .accessibilityHidden(informationCountry != nil)
                .overlay {
                    if let country = informationCountry {
                        ZStack {
                            Color.black.opacity(0.6).contentShape(Rectangle())
                                .onTapGesture { informationCountry = nil }
                                .accessibilityHidden(true)
                            CountryInformationPanel(country: country, compact: canvasWidth < 560) { informationCountry = nil }
                                .padding(.horizontal, canvasWidth < 560 ? 12 : 28).padding(.vertical, 8)
                        }
                    }
                }
                .rotationEffect(.degrees(portraitWindow ? 90 : 0))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .opacity(portraitWindow && waitingForLandscape ? 0 : 1)
                .allowsHitTesting(!portraitWindow || !waitingForLandscape)
                .accessibilityHidden(portraitWindow && waitingForLandscape)
            }
        }
        .background(FlashcardOrientation().frame(width: 0, height: 0))
        .task {
            // A windowed scene can decline rotation. Reveal its landscape canvas as a fallback.
            do { try await Task.sleep(for: .milliseconds(750)) } catch { return }
            waitingForLandscape = false
        }
        .task(id: turn?.started) {
            guard turn != nil else { return }
            do { try await Task.sleep(for: .seconds(CardTurn.duration)) } catch { return }
            turn = nil
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden()
        .tint(Atlas.mint)
        #if DEBUG
        .task {
            let args = ProcessInfo.processInfo.arguments
            if let position = args.firstIndex(of: "--preview-country"), args.indices.contains(position + 1),
               let target = countries.firstIndex(where: { $0.abb2 == args[position + 1] }) { index = target }
            if args.contains("--preview-info") { showInformation() }
            if args.contains("--preview-info-checks"), countries.count > 1 {
                let original = index
                let direction = original < countries.count - 1 ? 1 : -1
                showInformation()
                move(direction)
                assert(index == original && informationCountry?.id == countries[original].id)
                informationCountry = nil
                move(direction)
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                assert(index == original + direction && !turning)
                showInformation()
                assert(informationCountry?.id == countries[index].id)
                informationCountry = nil
                move(-direction)
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                assert(index == original && !turning)
                showInformation()
                FileHandle.standardError.write(Data("PASS: information blocks navigation, restores deck, and follows the current country\n".utf8))
            }
        }
        #endif
    }

    private func showInformation() {
        guard !turning, informationCountry == nil, countries.indices.contains(index) else { return }
        informationCountry = countries[index]
    }

    private func navigationButton(_ direction: Int) -> some View {
        Button { move(direction) } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.title2.bold()).frame(width: 44, height: 56)
                .background(Atlas.panel, in: Capsule())
        }
        .buttonStyle(.plain).foregroundStyle(Atlas.mint)
        .accessibilityLabel(direction < 0 ? previousTitle : nextTitle)
        .disabled(turning || (direction < 0 ? index == 0 : index == countries.count - 1))
    }

    private func deck(height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26).fill(paper.opacity(0.45))
                .rotationEffect(.degrees(-3)).offset(y: 9)
            RoundedRectangle(cornerRadius: 26).fill(paper.opacity(0.7))
                .rotationEffect(.degrees(2)).offset(y: 5)
            if let turn {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(turn.started)
                    let fraction = min(1, max(0, elapsed / CardTurn.duration))
                    let progress = 1 - pow(1 - fraction, 3)
                    let distance = turn.direction * min(76, height * 0.35)
                    ZStack {
                        card(countries[turn.previousIndex])
                            .rotation3DEffect(.degrees(-12 * turn.direction * progress), axis: (0, 1, 0))
                            .scaleEffect(1 - 0.04 * progress)
                            .opacity(1 - progress)
                            .offset(x: -distance * progress)
                        card(countries[index])
                            .rotation3DEffect(.degrees(12 * turn.direction * (1 - progress)), axis: (0, 1, 0))
                            .scaleEffect(0.96 + 0.04 * progress)
                            .opacity(progress)
                            .offset(x: distance * (1 - progress))
                            .shadow(color: .black.opacity(0.35), radius: 20, y: 14)
                    }
                }
            } else {
                card(countries[index])
                    .shadow(color: .black.opacity(0.35), radius: 20, y: 14)
            }
        }
        .frame(height: height)
        .contentShape(Rectangle())
        .overlay {
            GeometryReader { proxy in
                Color.clear.contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { value in
                        move(value.location.x < proxy.size.width / 2 ? -1 : 1)
                    })
                    .gesture(DragGesture(minimumDistance: 25).onEnded { value in
                        let delta = value.translation
                        guard abs(delta.width) > 45, abs(delta.width) > abs(delta.height) * 1.3 else { return }
                        move(delta.width < 0 ? 1 : -1)
                    })
            }.accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(countries[index].name(for: settings.language) + ", " + countries[index].en)
        .accessibilityValue("\(index + 1) / \(countries.count)")
        .accessibilityAction(named: Text(previousTitle)) { move(-1) }
        .accessibilityAction(named: Text(nextTitle)) { move(1) }
        .accessibilityAction(named: Text(settings.language.text("About this flag", "認識這面國旗", ja: "この国旗について", ko: "이 국기 알아보기"))) { showInformation() }
    }

    private func card(_ country: Country) -> some View {
        VStack(spacing: 8) {
            FlagImage(code: country.abb2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(-1)
            Rectangle().fill(Atlas.line).frame(height: 1)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name(for: settings.language))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.55)
                    if settings.language != .english {
                        Text(country.en).font(.caption).lineLimit(1).minimumScaleFactor(0.65)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(country.abb3).font(.caption.monospaced().bold())
                    if let region = StudyRegion.allCases.first(where: { $0.codes.contains(country.abb2) }) {
                        Text(region.title(settings.language)).font(.caption2).lineLimit(1).minimumScaleFactor(0.65)
                    }
                }
            }.foregroundStyle(Atlas.text)
        }
        .padding(16)
        .background(paper, in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white.opacity(0.8), lineWidth: 2))
    }

    private func move(_ direction: Int) {
        let next = index + direction
        guard !turning, informationCountry == nil, countries.indices.contains(next) else { return }
        if settings.animatedEffects && !reduceMotion {
            turn = CardTurn(previousIndex: index, direction: Double(direction), started: .now)
        }
        index = next
    }
}

private struct CountryInformationPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @AccessibilityFocusState private var headingFocused: Bool
    let country: Country
    let compact: Bool
    let close: () -> Void
    private var information: CountryInformation? { CountryInformationRepository.all[country.abb2] }
    private var language: AppLanguage { settings.language }
    private var title: String {
        country.abb2 == "TW"
            ? language.text("Republic of China (Taiwan)", "中華民國（臺灣）", ja: "中華民国（台湾）", ko: "중화민국(대만)")
            : country.name(for: language)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill").foregroundStyle(Atlas.blue)
                Text(title).font(.title3.bold()).lineLimit(2).minimumScaleFactor(0.75)
                    .accessibilityAddTraits(.isHeader).accessibilityFocused($headingFocused)
                Spacer(minLength: 0)
                Button(action: close) {
                    Label(language.text("Back to card", "返回圖卡", ja: "カードに戻る", ko: "카드로 돌아가기"), systemImage: "xmark")
                        .font(.subheadline.bold()).padding(.horizontal, 12).frame(minHeight: 44)
                        .foregroundStyle(Atlas.mint)
                        .modifier(GamePanel(tint: Atlas.mint, radius: 22))
                }.buttonStyle(.plain)
            }.padding(.horizontal, 20).padding(.vertical, 4)
            Rectangle().fill(Atlas.accent.opacity(0.25)).frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                        : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
                    layout {
                        VStack(alignment: .leading, spacing: 10) {
                            if language != .english {
                                Text(country.abb2 == "TW" ? "Republic of China (Taiwan)" : country.en)
                                    .font(.subheadline).foregroundStyle(Atlas.muted)
                            }
                            fact(language.text("Region", "地區", ja: "地域", ko: "지역"), value: region)
                            if let information {
                                fact(language.text("Capital / seat", "首都／行政中心", ja: "首都・行政中心", ko: "수도·행정 중심"), value: information.capital.localized(language))
                                fact(language.text("National flower", "國花", ja: "国花", ko: "국화"), value: information.flowerDescription(language))
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        VStack(spacing: 6) {
                            CountryLocationMap(country: country)
                                .aspectRatio(2.35, contentMode: .fit)
                            Text(language.text("Location on the world map", "在世界地圖上的位置", ja: "世界地図上の位置", ko: "세계 지도에서의 위치"))
                                .font(.caption2).foregroundStyle(Atlas.muted)
                        }.frame(width: compact ? nil : 200)
                    }
                    if let information {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(language.text("Flag design & meaning", "國旗設計與含義", ja: "国旗のデザインと意味", ko: "국기의 디자인과 의미"), systemImage: "flag.fill")
                                .font(.headline).foregroundStyle(Atlas.blue)
                            if information.historicalFlag {
                                Text(language.text("Historical flag shown", "本卡展示歷史旗幟", ja: "このカードは歴史的な旗を表示", ko: "이 카드는 역사적 국기를 표시합니다"))
                                    .font(.caption.bold()).foregroundStyle(Atlas.gold)
                            }
                            Text(information.flagDescription.localized(language))
                                .font(.body).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .modifier(GamePanel(tint: Atlas.blue, radius: 16))
                        if language == .japanese || language == .korean {
                            Text(language.text("Reference text is currently available in English and Traditional Chinese.", "目前提供英文與繁體中文資料。", ja: "参考本文は現在、英語と繁体字中国語で提供しています。", ko: "참고 본문은 현재 영어와 번체 중국어로 제공됩니다."))
                                .font(.caption).foregroundStyle(Atlas.muted)
                        }
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(information.sources.indices, id: \.self) { index in
                                    let source = information.sources[index]
                                    Link(destination: source.url) {
                                        Label(source.title, systemImage: "arrow.up.right.square")
                                            .font(.caption).multilineTextAlignment(.leading).frame(minHeight: 36)
                                    }
                                }
                                Text(language.text("Collected: ", "收錄日期：", ja: "収録日：", ko: "수록일: ") + information.collectedOn)
                                    .font(.caption2).foregroundStyle(Atlas.muted)
                            }.padding(.top, 8)
                        } label: {
                            Text(language.text("Sources", "資料來源", ja: "出典", ko: "출처")).font(.caption.bold())
                        }.tint(Atlas.mint)
                    } else {
                        Text(language.text("Information is unavailable for this card.", "這張圖卡的資訊暫時無法讀取。", ja: "このカードの情報を読み込めません。", ko: "이 카드의 정보를 불러올 수 없습니다."))
                    }
                }.padding(20)
            }
        }
        .foregroundStyle(Atlas.text)
        .frame(maxWidth: 900, maxHeight: .infinity)
        .modifier(GamePanel(tint: Atlas.accent, radius: 24))
        .shadow(color: .black.opacity(0.4), radius: 24, y: 10)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, close)
        .onAppear { headingFocused = true }
    }

    private var region: String {
        StudyRegion.allCases.first(where: { $0.codes.contains(country.abb2) })?.title(language)
            ?? language.text("Europe · supranational union", "歐洲 · 跨國聯盟", ja: "ヨーロッパ・国家連合", ko: "유럽 · 국가 연합")
    }

    private func fact(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("•").foregroundStyle(Atlas.mint)
            Text(label + "：").fontWeight(.semibold) + Text(value)
        }.font(.subheadline).fixedSize(horizontal: false, vertical: true)
    }
}
