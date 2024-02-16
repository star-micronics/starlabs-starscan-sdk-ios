import Foundation
import SwiftyBeaver

open class AppLog: NSObject {

    public static let log: SwiftyBeaver.Type = {
        let instance = SwiftyBeaver.self

        let file = FileDestination()  // log to default swiftybeaver.log file
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let logPath = documentDir?.appendingPathComponent("AppLog.log").path ?? "AppLog.log"
        file.logFileURL = URL(fileURLWithPath: logPath)
        file.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $T $C$L$c <$N.$F:$l> $M"
        instance.addDestination(file)

#if DEBUG
        let console = ConsoleDestination()  // log to Xcode Console
        console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $T $C$L$c <$N.$F:$l> $M"
        instance.addDestination(console)
#endif

        return instance
       }()
}
