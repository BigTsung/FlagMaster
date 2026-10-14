import Foundation

struct WorldCoordinate: Sendable {
    let longitude: Double
    let latitude: Double
}

struct WorldMapCountry: Sendable {
    let name: String
    let region: StudyRegion?
    let polygons: [[[WorldCoordinate]]]
}

enum WorldMapData {
    static let countries: [WorldMapCountry] = {
        guard let url = Bundle.main.url(forResource: "world-map", withExtension: "geojson"),
              let data = try? Data(contentsOf: url) else { return [] }
        return decode(data)
    }()

    static func decode(_ data: Data) -> [WorldMapCountry] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = root["features"] as? [[String: Any]] else { return [] }

        return features.compactMap { feature in
            guard let properties = feature["properties"] as? [String: Any],
                  let name = properties["name"] as? String,
                  let geometry = feature["geometry"] as? [String: Any],
                  let type = geometry["type"] as? String,
                  let coordinates = geometry["coordinates"] else { return nil }

            let polygons: [[[WorldCoordinate]]]
            switch type {
            case "Polygon":
                guard let polygon = polygon(from: coordinates) else { return nil }
                polygons = [polygon]
            case "MultiPolygon":
                guard let rawPolygons = coordinates as? [Any] else { return nil }
                polygons = rawPolygons.compactMap(polygon(from:))
            default:
                return nil
            }

            guard !polygons.isEmpty else { return nil }
            return WorldMapCountry(
                name: name,
                region: region(for: properties["region"] as? String),
                polygons: polygons
            )
        }
    }

    static func mapCountry(for country: Country) -> WorldMapCountry? {
        let aliases: [String: String] = [
            "BS": "The Bahamas", "CV": "Cape Verde", "CI": "Ivory Coast", "CN": "People's Republic of China",
            "GM": "The Gambia", "TL": "East Timor", "US": "United States of America"
        ]
        let target = aliases[country.abb2] ?? country.en
        return countries.first { $0.name.caseInsensitiveCompare(target) == .orderedSame }
    }

    static func marker(for country: Country) -> WorldCoordinate {
        if let mapped = mapCountry(for: country) {
            let points = mapped.polygons.flatMap { $0 }.flatMap { $0 }
            guard !points.isEmpty else { return fallbackMarkers[country.abb2] ?? .init(longitude: 0, latitude: 0) }
            let longitudes = points.map(\.longitude)
            let minimumLongitude = longitudes.min()!
            let maximumLongitude = longitudes.max()!
            let longitude: Double
            if maximumLongitude - minimumLongitude > 180 {
                let unwrapped = longitudes.map { $0 < 0 ? $0 + 360 : $0 }
                let midpoint = (unwrapped.min()! + unwrapped.max()!) / 2
                longitude = midpoint > 180 ? midpoint - 360 : midpoint
            } else {
                longitude = (minimumLongitude + maximumLongitude) / 2
            }
            let latitude = (points.map(\.latitude).min()! + points.map(\.latitude).max()!) / 2
            return .init(longitude: longitude, latitude: latitude)
        }
        return fallbackMarkers[country.abb2] ?? regionMarker(for: country.abb2)
    }

    private static func regionMarker(for code: String) -> WorldCoordinate {
        let region = StudyRegion.allCases.first { $0.codes.contains(code) }
        switch region {
        case .asia: return .init(longitude: 95, latitude: 35)
        case .europe: return .init(longitude: 15, latitude: 52)
        case .africa: return .init(longitude: 20, latitude: 5)
        case .northAmerica: return .init(longitude: -90, latitude: 35)
        case .southAmerica: return .init(longitude: -60, latitude: -15)
        case .oceania: return .init(longitude: 145, latitude: -20)
        case nil: return .init(longitude: 10, latitude: 50)
        }
    }

    // Natural Earth 1:110m omits many microstates and small islands. These
    // markers keep every catalogue entry locatable even without a polygon.
    private static let fallbackMarkers: [String: WorldCoordinate] = [
        "AD": .init(longitude: 1.60, latitude: 42.55), "AG": .init(longitude: -61.80, latitude: 17.06),
        "BH": .init(longitude: 50.55, latitude: 26.07), "BB": .init(longitude: -59.54, latitude: 13.19),
        "KM": .init(longitude: 43.33, latitude: -11.88), "DM": .init(longitude: -61.37, latitude: 15.42),
        "EU": .init(longitude: 10.45, latitude: 50.85), "GD": .init(longitude: -61.68, latitude: 12.12),
        "KI": .init(longitude: -157.36, latitude: 1.87), "LI": .init(longitude: 9.55, latitude: 47.17),
        "MV": .init(longitude: 73.22, latitude: 3.20), "MT": .init(longitude: 14.38, latitude: 35.94),
        "MH": .init(longitude: 171.18, latitude: 7.13), "MU": .init(longitude: 57.55, latitude: -20.35),
        "FM": .init(longitude: 158.22, latitude: 6.89), "MC": .init(longitude: 7.42, latitude: 43.74),
        "NR": .init(longitude: 166.93, latitude: -0.52), "PW": .init(longitude: 134.58, latitude: 7.51),
        "KN": .init(longitude: -62.78, latitude: 17.36), "LC": .init(longitude: -60.98, latitude: 13.91),
        "VC": .init(longitude: -61.20, latitude: 13.25), "WS": .init(longitude: -172.10, latitude: -13.76),
        "SM": .init(longitude: 12.46, latitude: 43.94), "SC": .init(longitude: 55.45, latitude: -4.62),
        "SG": .init(longitude: 103.82, latitude: 1.35), "ST": .init(longitude: 6.61, latitude: 0.19),
        "TO": .init(longitude: -175.20, latitude: -21.18), "TV": .init(longitude: 179.20, latitude: -8.52),
        "VA": .init(longitude: 12.45, latitude: 41.90)
    ]

    private static func polygon(from raw: Any) -> [[WorldCoordinate]]? {
        guard let rawRings = raw as? [Any] else { return nil }
        let rings = rawRings.compactMap(ring(from:))
        return rings.isEmpty ? nil : rings
    }

    private static func ring(from raw: Any) -> [WorldCoordinate]? {
        guard let rawPoints = raw as? [Any] else { return nil }
        let points = rawPoints.compactMap { rawPoint -> WorldCoordinate? in
            guard let pair = rawPoint as? [Any], pair.count >= 2,
                  let longitude = (pair[0] as? NSNumber)?.doubleValue,
                  let latitude = (pair[1] as? NSNumber)?.doubleValue,
                  longitude.isFinite, latitude.isFinite else { return nil }
            return WorldCoordinate(longitude: longitude, latitude: latitude)
        }
        return points.count >= 3 ? points : nil
    }

    private static func region(for name: String?) -> StudyRegion? {
        switch name {
        case "Asia": return .asia
        case "Europe": return .europe
        case "Africa": return .africa
        case "North America": return .northAmerica
        case "South America": return .southAmerica
        case "Oceania": return .oceania
        default: return nil
        }
    }
}
