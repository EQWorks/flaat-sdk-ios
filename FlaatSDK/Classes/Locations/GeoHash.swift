import Foundation

struct GeoHash {

    private static let base32 = "0123456789bcdefghjkmnpqrstuvwxyz".map({$0}) // array of Characters
    private static let bitsPerChar = 5

    static func encode(coordinate: GeoLocation, precision: Int) -> String {
        let bitPrecision = precision * bitsPerChar
        let intHash: Int64 = encode(coordinate: coordinate, bitPrecision: bitPrecision)

        let hashChars = (0..<precision).reversed().map { index -> Character in
            let charBits = 0b11111 & (intHash >> (bitsPerChar * index))
            return base32[Int(charBits)]
        }

        return String(hashChars)
    }

    private static func encode(coordinate: GeoLocation, bitPrecision: Int) -> Int64 {
        var intHash: Int64 = 0

        typealias GeoInterval = (min: Double, max: Double)
        var lat = GeoInterval(-90, 90)
        var lon = GeoInterval(-180, 180)

        for i in 0..<bitPrecision {
            intHash <<= 1

            if i % 2 == 0 { // even bit
                let mid = (lon.min + lon.max) / 2

                if coordinate.longitude >= mid {
                    intHash = intHash | 1
                    lon.min = mid
                }
                else {
                    lon.max = mid
                }
            } else { // odd bit
                let mid = (lat.min + lat.max) / 2

                if coordinate.latitude >= mid {
                    intHash = intHash | 1
                    lat.min = mid
                }
                else {
                    lat.max = mid
                }
            }
        }

        return intHash
    }
}
