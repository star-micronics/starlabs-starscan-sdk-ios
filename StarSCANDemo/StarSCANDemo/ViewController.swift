import UIKit
import StarSCAN
import CoreBluetooth

class ViewController: UIViewController {

    @IBOutlet var bluetoothState: UILabel!
    @IBOutlet var connectedNumber: UILabel!
    @IBOutlet var tableView: UITableView!

    // 已连上可以使用的外围设备和连上后断开连接的设备
    // peripherals that ready to use and disconnected after ready
    var availablePeripherals: [StarSCANPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        centralLoad()

        tableView.dataSource = self
        tableView.delegate = self

        // 获取所有已连接可以读写数据的外围设备,不包括暂时断连不能使用的设备
        // get all peripherals that ready for write/read data, not include did disconnected which unuseable
        availablePeripherals = StarSCANCentral.instance.getControllablePeripherals() // -> [StarSCANPeripheral]
    }

    // 到扫码连接页面
    // present scan and connect page
    @IBAction func clickNewConnect() {
        if self.bluetoothState.text != "available".localized() {
            let alertController = UIAlertController(title: "", message: "openBluetooth".localized(), preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok".localized(), style: .default, handler: nil)
            alertController.addAction(okAction)
            let topViewController = UIApplication.getTopViewController()
            topViewController?.present(alertController, animated: true)
            return
        }

        if let newConnect = storyboard?.instantiateViewController(withIdentifier: "newConnect") as? NewConnect {
            newConnect.onDismissHandler = { clearUuids in
                if let clearUuids = clearUuids {
                    // 从tableview删除
                    // remove from tableview
                    var removeIndexPath: [IndexPath] = []
                    for clearUuid in clearUuids {
                        if let index = self.availablePeripherals.firstIndex(where: {$0.identifier == clearUuid}) {
                            self.availablePeripherals.remove(at: index)
                            removeIndexPath.append(IndexPath(row: index, section: 0))
                        }
                    }
                    if !removeIndexPath.isEmpty {
                        self.tableView.deleteRows(at: removeIndexPath, with: .top)
                    }
                }
            }
            newConnect.modalPresentationStyle = .fullScreen
            present(newConnect, animated: true)
        }
    }

    // 分享sdk日志文件给sdk开发者如果遇到无法解决的问题,日志文件名StarSCANSdk.log
    // share sdk log file to sdk developer if you encounter problems, log file name is StarSCANSdk.log
    @IBAction func clickShareLog() {
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let logPath = documentDir?.appendingPathComponent("StarSCANSdk.log").path ?? "StarSCANSdk.log"
        let logFileURL = URL(fileURLWithPath: logPath)
        let activityViewController = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = {(_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ activityError: Error?) -> Void in
            AppLog.log.info("share log " + (completed ? "success" : "fail"))
        }
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .copyToPasteboard,
            .assignToContact,
            .print
        ]
        if let popoverController = activityViewController.popoverPresentationController { // iPad
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popoverController.sourceView = self.view
            popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }
        present(activityViewController, animated: true)
    }
}

// MARK: - UITableView
extension ViewController: UITableViewDataSource, UITableViewDelegate, MyCellDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? PeripheralCell
        cell?.updateCell(indexPath, self.availablePeripherals[indexPath.row], self)
        return cell!
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availablePeripherals.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    // MyCellDelegate
    func delete(_ cell: PeripheralCell) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            self.availablePeripherals.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .top)
        }
    }
}
