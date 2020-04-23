import Foundation

// TODO: tmp impl
class PersistentStorage {

    class func getValue(forKey key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    class func setValue(_ value: Any?, forKey key: String) {
        if value != nil {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    class func appendValue<T>(_ value: T, toArrayForKey key: String) where T: Equatable {
        var existingArray: [T]! = UserDefaults.standard.array(forKey: key) as? [T]
        if existingArray == nil {
            existingArray = [T]()
        }

        if !existingArray.contains(where: { $0 == value }) {
            existingArray.append(value)
            UserDefaults.standard.set(existingArray, forKey: key)
        }
    }

}
