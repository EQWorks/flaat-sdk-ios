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

}
