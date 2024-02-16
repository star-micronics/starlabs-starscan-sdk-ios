import UIKit
import StarSCAN
import CoreBluetooth

// MARK: - CentralManager 中央设备iphone/ipad
extension ViewController {

    // view controller init
    func centralLoad() {
        /**
         define a delegate for checking the Bluetooth adapter state
         */
        StarSCANCentral.instance.centralDelegate = self

        updateConnectedCount()
    }

    func updateConnectedCount() {
        /**
         Get all connected peripherals that can read and write data, excluding devices that are temporarily disconnected and cannot be used.
         */
        let peripherals = StarSCANCentral.instance.getControllablePeripherals() // -> [StarSCANPeripheral]
        self.connectedNumber.text = "connectedNumber".localized() + "\(peripherals.count)"
        if peripherals.count > 0 {
            self.connectedNumber.textColor = .green
        } else {
            self.connectedNumber.textColor = .red
        }
    }
}

// MARK: - StarSCANCentralDelegate
extension ViewController: StarSCANCentralDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        AppLog.log.verbose("centralManagerDidUpdateState: \(central.state)")
        switch central.state {
        case .unknown:
            break
        case .unsupported:
            self.bluetoothState.text = "unsupported".localized()
            self.bluetoothState.textColor = .red
        case .unauthorized:
            self.bluetoothState.text = "unauthorized".localized()
            self.bluetoothState.textColor = .red
        case .poweredOff:
            self.bluetoothState.text = "poweredOff".localized()
            self.bluetoothState.textColor = .red
        case .poweredOn:
            self.bluetoothState.text = "available".localized()
            self.bluetoothState.textColor = .green
        case .resetting:
            self.bluetoothState.text = "resetting".localized()
            self.bluetoothState.textColor = .red
        default:
            break
        }
    }

    /**
     外围设备连接成功并且可读写数据
     new peripheral has connected, ready for write/read data
     same as  StarSCANPeripheralDelegate.onReady
    */
    func onPeripheralReady(_ peripheral: StarSCANPeripheral) {
        AppLog.log.verbose("onPeripheralReady [\(peripheral.name ?? "") \(peripheral.identifier)] peripheral=\(peripheral)")

        // StarSCANPeripheral可以用==比较
        // StarSCANPeripheral has implement ==
        // self.availablePeripherals.contains(where: {$0 == peripheral})
        // self.availablePeripherals.contains(peripheral)
        if let index = self.availablePeripherals.firstIndex(where: {$0 == peripheral}) {
            // 设备已经在tableview,替换
            // peripheral already exists on tableview, replace it
            self.availablePeripherals[index] = peripheral
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .left)
            AppLog.log.verbose("reloadRows \(index)")
        } else {
            // 新设备连上
            // new peripheral device connected
            self.availablePeripherals.append(peripheral)
            let indexPath = IndexPath(row: self.availablePeripherals.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .left)
            AppLog.log.verbose("insertRows \(indexPath.row)")
        }
        updateConnectedCount()

        // 关闭连接页面NewConnect
        // dismiss NewConnect
        if let viewController = presentedViewController {
            viewController.dismiss(animated: true)
        }
    }

    /**
     外围设备断开连接
     peripheral did disconnected
     same as  StarSCANPeripheralDelegate.onDidDisconnect
    */
    func onPeripheralDidDisconnect(_ peripheral: StarSCANPeripheral) {
        AppLog.log.verbose("onPeripheralDidDisconnect [\(peripheral.name ?? "") \(peripheral.identifier)]")
        updateConnectedCount()

        /**
         获取可以重连的设备uuid
         get reconnect peripherals uuid which will reconnect after disconnected
         */
        let reconnect: [UUID] = StarSCANCentral.instance.getReconnectPeripherals()
        if !reconnect.contains(peripheral.identifier) {
            if let index = self.availablePeripherals.firstIndex(of: peripheral) {
                self.availablePeripherals.remove(at: index)
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.deleteRows(at: [indexPath], with: .top)
            }
        }
    }

    /**
     可以更新连接码二维码条码图片
     reset the connection  barcode image with a new image
     */
    func resetBarcodeImage() {
        AppLog.log.verbose("resetBarcodeImage")
        if let newConnect = presentedViewController as? NewConnect {
            newConnect.resetBarcodeImage()
        }
    }

    /**
     扫码后开始连接,显示loading图,
     reconnect=true已连上的设备断开连接后重连, reconnect=false新扫码连接的设备
     start connecting after scanned barcode, show loading
     reconnect=true reconnect the connected device after disconnected, reconnect=false new peripheral that connecting by scanned barcode
     */
    func onStartConnecting(_ peripheral: CBPeripheral, _ reconnect: Bool) {
        AppLog.log.verbose("onStartConnecting [\(peripheral.name ?? "") \(peripheral.identifier)] reconnect=\(reconnect)")
        if !reconnect,
            let newConnect = presentedViewController as? NewConnect {
            newConnect.onStartConnecting(peripheral, reconnect)
        }
    }

    /**
     结束连接中状态,隐藏loading, 连接失败或者成功
     stop connecting, hide loading, connected or failed
     */
    func onStopConnecting(_ peripheral: CBPeripheral) {
        AppLog.log.verbose("onStopConnecting [\(peripheral.name ?? "") \(peripheral.identifier)]")
        if let newConnect = presentedViewController as? NewConnect {
            newConnect.onStopConnecting(peripheral)
        }
    }
}
