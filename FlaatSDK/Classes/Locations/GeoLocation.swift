import Foundation

struct GeoLocation {
    let latitude: Double
    let longitude: Double
}

struct GeoLocationRecord {
    let location: GeoLocation
    let timestamp: Date
}

extension GeoLocation: CustomStringConvertible {

    public var description: String {
        return "(\(latitude), \(longitude))"
    }
}

extension GeoLocationRecord: CustomStringConvertible {

    public var description: String {
        return "\(location) @ \(timestamp)"
    }
}

extension GeoLocation {

    func geoHash(precision: Int) -> String {
        return GeoHash.encode(coordinate: self, precision: precision)
    }
}
