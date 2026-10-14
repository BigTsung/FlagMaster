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
