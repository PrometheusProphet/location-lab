import Foundation
import MapKit

struct City: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let state: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayName: String { "\(name), \(state)" }

    var gpx: String {
        let escapedName = displayName
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Location Lab" xmlns="http://www.topografix.com/GPX/1/1">
          <wpt lat="\(latitude)" lon="\(longitude)">
            <name>\(escapedName)</name>
          </wpt>
        </gpx>

        """
    }
}

enum CityCatalog {
    // Approximate city-center coordinates. These are hand-curated factual values.
    static let cities: [City] = [
        City(id: "atlanta", name: "Atlanta", state: "GA", latitude: 33.7490, longitude: -84.3880),
        City(id: "austin", name: "Austin", state: "TX", latitude: 30.2672, longitude: -97.7431),
        City(id: "baltimore", name: "Baltimore", state: "MD", latitude: 39.2904, longitude: -76.6122),
        City(id: "boston", name: "Boston", state: "MA", latitude: 42.3601, longitude: -71.0589),
        City(id: "charlotte", name: "Charlotte", state: "NC", latitude: 35.2271, longitude: -80.8431),
        City(id: "chicago", name: "Chicago", state: "IL", latitude: 41.8781, longitude: -87.6298),
        City(id: "columbus", name: "Columbus", state: "OH", latitude: 39.9612, longitude: -82.9988),
        City(id: "dallas", name: "Dallas", state: "TX", latitude: 32.7767, longitude: -96.7970),
        City(id: "denver", name: "Denver", state: "CO", latitude: 39.7392, longitude: -104.9903),
        City(id: "detroit", name: "Detroit", state: "MI", latitude: 42.3314, longitude: -83.0458),
        City(id: "houston", name: "Houston", state: "TX", latitude: 29.7604, longitude: -95.3698),
        City(id: "indianapolis", name: "Indianapolis", state: "IN", latitude: 39.7684, longitude: -86.1581),
        City(id: "jacksonville", name: "Jacksonville", state: "FL", latitude: 30.3322, longitude: -81.6557),
        City(id: "las-vegas", name: "Las Vegas", state: "NV", latitude: 36.1699, longitude: -115.1398),
        City(id: "los-angeles", name: "Los Angeles", state: "CA", latitude: 34.0522, longitude: -118.2437),
        City(id: "miami", name: "Miami", state: "FL", latitude: 25.7617, longitude: -80.1918),
        City(id: "minneapolis", name: "Minneapolis", state: "MN", latitude: 44.9778, longitude: -93.2650),
        City(id: "nashville", name: "Nashville", state: "TN", latitude: 36.1627, longitude: -86.7816),
        City(id: "new-orleans", name: "New Orleans", state: "LA", latitude: 29.9511, longitude: -90.0715),
        City(id: "new-york", name: "New York", state: "NY", latitude: 40.7128, longitude: -74.0060),
        City(id: "orlando", name: "Orlando", state: "FL", latitude: 28.5383, longitude: -81.3792),
        City(id: "philadelphia", name: "Philadelphia", state: "PA", latitude: 39.9526, longitude: -75.1636),
        City(id: "phoenix", name: "Phoenix", state: "AZ", latitude: 33.4484, longitude: -112.0740),
        City(id: "pittsburgh", name: "Pittsburgh", state: "PA", latitude: 40.4406, longitude: -79.9959),
        City(id: "portland", name: "Portland", state: "OR", latitude: 45.5152, longitude: -122.6784),
        City(id: "raleigh", name: "Raleigh", state: "NC", latitude: 35.7796, longitude: -78.6382),
        City(id: "sacramento", name: "Sacramento", state: "CA", latitude: 38.5816, longitude: -121.4944),
        City(id: "san-antonio", name: "San Antonio", state: "TX", latitude: 29.4241, longitude: -98.4936),
        City(id: "san-diego", name: "San Diego", state: "CA", latitude: 32.7157, longitude: -117.1611),
        City(id: "san-francisco", name: "San Francisco", state: "CA", latitude: 37.7749, longitude: -122.4194),
        City(id: "san-jose", name: "San Jose", state: "CA", latitude: 37.3382, longitude: -121.8863),
        City(id: "seattle", name: "Seattle", state: "WA", latitude: 47.6062, longitude: -122.3321),
        City(id: "st-louis", name: "St. Louis", state: "MO", latitude: 38.6270, longitude: -90.1994),
        City(id: "tampa", name: "Tampa", state: "FL", latitude: 27.9506, longitude: -82.4572),
        City(id: "washington", name: "Washington", state: "DC", latitude: 38.9072, longitude: -77.0369)
    ]
}
