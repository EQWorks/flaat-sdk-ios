import UIKit
import FlaatSDK
import TCNClient
import Security

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var bluetoothService: TCNBluetoothService!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        FlaatService.launch(apiKey: "ce8ffe25cdbd3c22da9273ac0eb35d66", logLevel: .debug)
        runBluetoothService()

        testCrypto()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    var tck: TemporaryContactKey = ReportAuthorizationKey().initialTemporaryContactKey

    private func runBluetoothService() {
        bluetoothService = TCNBluetoothService(tcnGenerator: { () -> Data in
            let deviceName = UIDevice.current.name
            let deviceNameHash = CryptoProvider.sha256(data: deviceName.data(using: .utf8)!)

            //let tcn = self.tck.temporaryContactNumber.bytes
            let tcn = deviceNameHash[0..<16]

            NSLog("Bluetooth service asked for TCN. Returning \(tcn.base64EncodedString()). Composed from device name '\(deviceName)' and corresponding hash \(deviceNameHash.base64EncodedString())")
            return tcn
        }, tcnFinder: { (data, distance) in
            NSLog("Data is here: \(data). Distance: \(distance ?? 0)")
        }, errorHandler: { (error) in
            NSLog("Bluetooth service error: \(error)")
        })

        bluetoothService.start()
    }

    private func testCrypto() {
//        let key = SecKeyCreateRandomKey(<#T##parameters: CFDictionary##CFDictionary#>, <#T##error: UnsafeMutablePointer<Unmanaged<CFError>?>?##UnsafeMutablePointer<Unmanaged<CFError>?>?#>)

        

    }

}

