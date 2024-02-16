import Foundation
import UIKit

// MARK: - String
extension String {
    func localized(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }
}

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first(where: \.isKeyWindow)
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
 
extension UIApplication {
    class func getTopViewController() -> UIViewController? {
        return UIApplication.topViewController(base: UIWindow.key?.rootViewController)
    }

    class func topViewController(base: UIViewController?) -> UIViewController? {
        if let nav = base as? UINavigationController {
          return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
          if let selected = tab.selectedViewController {
            return topViewController(base: selected)
          }
        }

        if let presented = base?.presentedViewController {
          return topViewController(base: presented)
        }

        if let alert = base as? UIAlertController {
            if let navigationController = alert.presentingViewController as? UINavigationController {
                return navigationController.viewControllers.last
            }
            return alert.presentingViewController
        }

        return base
    }
}
