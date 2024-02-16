import UIKit
import UniformTypeIdentifiers
import StarSCAN

// Cell - ViewController
protocol MyCellDelegate: NSObjectProtocol {
    // 在ViewContorller tableview删除一个设备
    // delete a device from the ViewContorller tableview
    func delete(_ cell: PeripheralCell)
}

class PeripheralCell: UITableViewCell, UIDocumentPickerDelegate {
    @IBOutlet var name: UILabel!
    @IBOutlet var state: UILabel!
    @IBOutlet var identifier: UILabel!
    @IBOutlet var receiveDataText: UILabel!
    @IBOutlet var batteryLevel: UILabel!
    @IBOutlet var buttonSetDeviceConfig: UIButton!

    var myDelegate: MyCellDelegate?
    var remote: StarSCANPeripheral!
    var indexPath: IndexPath?
    var receivedData: [String] = []

    func updateCell(_ indexPath: IndexPath, _ peripheral: StarSCANPeripheral, _ delegate: MyCellDelegate?) {
        self.remote = peripheral
        self.indexPath = indexPath
        self.myDelegate = delegate

        setPeripheralDelegate()

        name.text = self.remote.name
        identifier.text = self.remote.identifier.uuidString
        changeState()
        receivedData = [String]()
        updateReceivedData()
        updateBattery()
    }

    // 连接的状态, connection state
    func changeState() {
        /**
         true 设备连接正常可以读写数据 peripheral is ready to write/read data
         false 设备断开连接 peripheral disconnect
         */
        state.text = self.remote.isReady ? "ready" : "disconnect"
        if self.remote.isReady {
            state.textColor = .green
            self.backgroundColor = ((indexPath?.row ?? 0) % 2) == 0 ? .darkGray : .lightGray
        } else {
            state.textColor = .red
            self.backgroundColor = .orange
        }
        refreshCell()
    }

    // 扫码返回的数据, scan data
    func updateReceivedData() {
        receiveDataText.text = self.receivedData.joined(separator: "\n")
        refreshCell()
    }

    // 更新cell高度, update cell height
    func refreshCell() {
        let tableview: UITableView? = self.superview as? UITableView
        tableview?.beginUpdates()
        tableview?.endUpdates()
    }

    // 更新电量, update battery
    func updateBattery() {
        /**
         电量 -1错误/初始状态,0-100电量值
         battery level, -1 error/init, 0-100 level
         */
        let level: Int = self.remote.batteryLevel
        batteryLevel.text = level >= 0 ? String(level) : "0"
    }

    @IBAction func clickQueryBatteryLevel() {
        /**
         查询电量,结果在onBatteryLevelRead()
         query battery level, receive value on onBatteryLevelRead()
         */
        remote.queryBatteryLevel()
    }

    @IBAction func clickClearConnection() {
        /**
         断开一个外围设备连接并清除缓存,不再重连
         disconnect peripheral and clear cache, no longer reconnect it
         */
        StarSCANCentral.instance.clearConnect(remote)

        // 从tableview删除显示的设备
        // delete the peripheral from tableview
        myDelegate?.delete(self)
    }

    @IBAction func clickQueryFirmwareVersion() {
        /**
         查询固件版本号,结果在onFirmwareVersionReceived()
         query firmware version receive value on  onFirmwareVersionReceived()
         */
        remote.queryFirmwareVersion()
    }

    @IBAction func clickQueryDeviceConfig() {
        /**
         查询设备配置信息,结果在onDeviceConfigReceived()
         query peripheral config  receive value on onDeviceConfigReceived()
         */
        remote.queryDeviceConfig()
    }

    @IBAction func clickSetDeviceConfig() {
        if let selectConfigPath = selectConfigPath, !selectConfigPath.isEmpty {
            /**
             设置设备配置, 执行结果回调 onSetDeviceConfigResponse
             set peripheral config,result callback onSetDeviceConfigResponse
             */
            remote.setDeviceConfig(selectConfigPath)
        } else {
            // 使用queryDeviceConfig()查询设备配置信息得到的文件"peripheralConfig.xml"
            // config file from queryDeviceConfig() query peripheral config "peripheralConfig.xml"
            openFileSelect("clickSetDeviceConfig")
        }
    }

    // 重置选择的文件 reset file path
    func resetSelectedConfig() {
        if let url = selectUrl {
            url.stopAccessingSecurityScopedResource()
            selectUrl = nil
        }
        selectConfigPath = nil
        buttonSetDeviceConfig.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
    }

    // MARK: - File Select
    var selectUrl: URL?

    // 选择的升级固件包路径
    // selected firmware package path
    var selectFirmwarePath: String?

    // 选择的配置文件路径
    // selected peripheral config file path
    var selectConfigPath: String?

    var selectForClick: String = "clickSetDeviceConfig"

    // SelectFirmwareDelegate
    func onSelected(_ path: String, _ filename: String) {
        receivedData.append("selected: \(filename)")
        updateReceivedData()
        AppLog.log.verbose("onSelected path=\(path) filename=\(filename)")

        if selectForClick == "clickSetDeviceConfig" { // peripheralConfig.xml
            selectConfigPath = path
            buttonSetDeviceConfig.backgroundColor = .green
        }
    }

    // MARK: - UIDocumentPickerViewController
    func openFileSelect(_ click: String) {
        selectForClick = click

        let controller: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            controller = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
            controller.shouldShowFileExtensions = true
        } else {
            controller = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .open)
        }
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        let topViewController = UIApplication.getTopViewController()
        topViewController?.present(controller, animated: true)
    }

    // UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first, url.startAccessingSecurityScopedResource() {
            // url.stopAccessingSecurityScopedResource() 使用完成后记得释放
            selectUrl = url
            onSelected(url.path, url.lastPathComponent)
        }
    }
}
