import UIKit
import StarSCAN
import CoreBluetooth

// ---*-------*-------*----------*--------*------
// 设备: 一个中央设备 -- 多个外围设备
// 代理: 一个或者多个StarSCANPeripheralDelegate,这个demo一个外围设备关联一个StarSCANPeripheralDelegate
// device: one Central -- many Peripheral
// delegate: one/many StarSCANPeripheralDelegate, this demo one peripheral device related to one StarSCANPeripheralDelegate
// StarSCANPeripheralDelegate run on main thread,代理都是在主线程执行

// MARK: - StarSCANPeripheralDelegate 外围设备代理
 extension PeripheralCell: StarSCANPeripheralDelegate { //

    func setPeripheralDelegate() {
        /**
         外围设备代理
         peripheral delegate
         */
        remote.peripheralDelegate = self
    }

    /**
     外围设备连接成功并且可读写数据
     new peripheral has connected, ready for write/read data
     same as StarSCANCentralDelegate.onPeripheralReady
    */
    func onReady(_ peripheral: StarSCANPeripheral) {
        AppLog.log.verbose("onReady [\(peripheral.name ?? "") \(peripheral.identifier)]")
        changeState()
    }

    /**
     外围设备断开连接
     peripheral did disconnected
     same as StarSCANCentralDelegate.onPeripheralDidDisconnect
    */
    func onDidDisconnect(_ peripheral: StarSCANPeripheral) {
        AppLog.log.verbose("onDidDisconnect [\(peripheral.name ?? "") \(peripheral.identifier)]")
        changeState()
    }

     /**
      扫码识别结果
      scan data
      */
    func onScanDataReceived(_ peripheral: StarSCANPeripheral, _ data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        AppLog.log.verbose("[\(peripheral.name ?? "") \(peripheral.identifier)] onScanDataReceived: \(String(describing: str))")

        // 测试连续不间断扫描,扫描结果相同,界面只添加一次
        // test scanner scaning continuous, result equal, add once in view
        if !str.isEmpty && str == receivedData.last {
            if receivedData.count >= 2, receivedData[receivedData.count - 2].starts(with: "===========equals:") {
                let equalCountStr = receivedData[receivedData.count - 2]
                let equalCountSplit = equalCountStr.components(separatedBy: "equals:")
                let equalNumber = (Int(equalCountSplit.last ?? "-99999999") ?? 0) + 1 // add one equal
                let newEqualCountStr = "===========equals:" + String(equalNumber)
                receivedData[receivedData.count - 2] = newEqualCountStr
            } else {
                receivedData.append("===========equals:1")
                receivedData.append(str)
            }
        } else {
            receivedData.append(str)
        }

        // 收到数据在主线程,数据频次太多没通过async更新页面会让界面卡住无响应
        // received scanner data on main thread, data received frequency without async update ui will lock screen no response
        DispatchQueue.main.async {
            self.updateReceivedData()
        }
    }

     /**
      电量 -1错误/初始状态,0-100电量值
      battery level, -1 error/init, 0-100 level
      */
     func onBatteryLevelRead(_ peripheral: StarSCANPeripheral, _ level: Int) {
         AppLog.log.verbose("[\(peripheral.name ?? "") \(peripheral.identifier)] onBatteryLevelRead:\(level)")
         updateBattery()
    }

     /**
      固件版本
      firmware version
      */
     func onFirmwareVersionReceived(_ peripheral: StarSCANPeripheral, _ firmware: FirmwareVersion) {
         AppLog.log.verbose("[\(peripheral.name ?? "") \(peripheral.identifier)] onFirmwareVersionReceived:\(firmware.toString())")
         receivedData.append("firmware.productName=" + (firmware.productName ?? ""))
         receivedData.append("firmware.cpuFirmwareVersion=" + (firmware.cpuFirmwareVersion ?? ""))
         receivedData.append("firmware.btFirmwareVersion=" + (firmware.btFirmwareVersion ?? ""))
         updateReceivedData()
     }

     /**
      外围设备配置数据xml
      peripheral config xml
      */
     func onDeviceConfigReceived(_ peripheral: StarSCANPeripheral, _ config: String) {
         AppLog.log.verbose("[\(peripheral.name ?? "") \(peripheral.identifier)] onDeviceConfigReceived:\n\(config)")
         let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
         let configPath = documentDir?.appendingPathComponent("peripheralConfig.xml").path ?? "peripheralConfig.xml"
         do {
             try config.write(toFile: configPath, atomically: true, encoding: .utf8)
         } catch let error {
             AppLog.log.error("save \(configPath) \(error)")
         }
         // 保存文件到document目录,可以用系统自带的"文件"app查看
         // save config into document directory, that can open by ios system "Files" app
         receivedData.append("save peripheral config to \(configPath)")
         receivedData.append("that can open by ios system \"Files\" app")
         receivedData.append("可以用系统自带的\"文件\"app查看")
         updateReceivedData()
     }

     /**
      设置设备配置数据异步返回的结果,
      set peripheral config async response,
      - Parameters ret: -1:失败(解析config xml文件失败),0:成功 -1:failed(parser config xml failed),0:successed
      */
     func onSetDeviceConfigResponse(_ peripheral: StarSCANPeripheral, _ ret: Int) {
         AppLog.log.verbose("[\(peripheral.name ?? "") \(peripheral.identifier)] onSetDeviceConfigResponse:\(ret)")
         receivedData.append("onSetDeviceConfigResponse \(ret)")
         updateReceivedData()
         resetSelectedConfig()
     }

     /**
      固件升级状态,预留接口暂时无用
      update firmware state,, reserved interface temporarily unavailable
      - Parameters state: enum FirmwareUpdateState
      - Parameters error: 失败详细提示,  detail error string
      - Parameters progress: 升级进度 update progress
      */
     func onUpdate(_ peripheral: StarSCANPeripheral, _ state: FirmwareUpdateState, _ error: String, _ progress: Int) {
         // unavailable
     }
}
