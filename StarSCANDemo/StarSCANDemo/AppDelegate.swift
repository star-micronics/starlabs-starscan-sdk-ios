import UIKit
import StarSCAN

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

         // AppDelegate启动时调用,让BLE Central Manager保持在app整个的生命周期并且支持后台模式,比如息屏后继续收发数据
         // instance is called when app didFinishLaunching, the BLE central manager must exists for the lifetime of your app and support background execution mode, e.g. receive data while iphone is sleeping
        StarSCANCentral.instance.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }

}
