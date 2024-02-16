import UIKit
import StarSCAN
import CoreBluetooth
import Lottie
import SnapKit

class NewConnect: UIViewController {

    @IBOutlet var connectImage: UIImageView!
    @IBOutlet var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var buttonSwitchCodeType: UIButton!
    @IBOutlet var versionLabel: UILabel!

    // 连接loading图,遮住二维码条码
    // loading for connecting, cover the barcode image
    private var loadingAnimationView: LottieAnimationView?
    private var loadingBackgroundView: UIVisualEffectView?

    var clearUuids: [UUID]?
    var onDismissHandler: ((_ clearUuids: [UUID]?) -> Void)?
    var codeType2d = true

    override func viewDidLoad() {
        super.viewDidLoad()
        initLoading()

        buttonSwitchCodeType.setTitle("switchTo1d".localized(), for: .normal)

        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.text = appVersion + "(" + buildVersion + ")"
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        setConnectBarCodeImage()

        /**
         开始搜索外围设备并连接,直到调用stopScan()停止搜索.连接上外围设备并且完成配对之后也会一直搜索.
         比如在进入"建立连接页面"调用
         start scan peripheral and connect, until you call stopscan() to stop scanning. The scanning is continuous even if new peripheral paired successful.
         e.g. called when enter the "NewConnect create connection page"
         */
        StarSCANCentral.instance.startScanAndConnect()
    }

    override func viewWillDisappear(_ animated: Bool) {
        /**
         停止搜索外围设备,长时间未找到外围设备或者退出app时需要停止蓝牙搜索,否则会在后台模式一直搜索设备,大量耗电.
         比如在退出"建立连接页面"调用
         stop scan, when peripheral is not found for a long time or app exit normally, you need to stop the bluetooth search, search continuously in the background mode and consume a lot of power.
         e.g. called when exit the "NewConnect create connection page"
         */
        StarSCANCentral.instance.stopScan()
    }

    // 屏幕旋转完成调整条形码长度
    // screen rotate reset image
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        setConnectBarCodeImage()
    }

    // 显示连接码图片
    func setConnectBarCodeImage() {
        if codeType2d {
            /**
             生成连接二维码 image size:176x176 scaleToFill
             generate Data Matrix Code for connect, image size:176x176 scaleToFill
             */
            self.connectImage.image = StarSCANCentral.instance.generateConnectCodeBitmap()
            imageHeightConstraint.constant = 172
            imageWidthConstraint.constant = 172
        } else {
            /**
             生成连接条形码 image size:2220x588
             generate bar code for connect, image size:2220x588
             */
            self.connectImage.image = StarSCANCentral.instance.generateConnectBarCode128()
            imageWidthConstraint.constant = UIScreen.main.bounds.size.width

            if UIApplication.shared.statusBarOrientation == .portrait { // 竖屏
                imageHeightConstraint.constant = 172.0
            } else {
                imageHeightConstraint.constant = 202.0
            }
        }
        self.connectImage.layoutIfNeeded()

        // 背景图调整为跟连接码一样大小
        // adjust the background view size same as barcode image
        self.loadingBackgroundView?.snp.remakeConstraints({ make in
            make.left.right.top.bottom.equalTo(self.connectImage)
        })
    }

    // loading view
    private func initLoading() {
        // blur
        let blurEffect = UIBlurEffect(style: .extraLight)
        loadingBackgroundView = UIVisualEffectView(effect: blurEffect)
        loadingBackgroundView?.alpha = 0.9
        loadingBackgroundView?.layer.masksToBounds = true
        loadingBackgroundView?.isHidden = true
        if let loadingBackgroundView = loadingBackgroundView {
            view.addSubview(loadingBackgroundView)
        }

        // lottie https://github.com/airbnb/lottie-ios.git
        loadingAnimationView = LottieAnimationView(name: "connecting")
        loadingAnimationView?.contentMode = .scaleAspectFit
        loadingAnimationView?.loopMode = .loop
        loadingAnimationView?.animationSpeed = 1.5
        loadingAnimationView?.isHidden = true
        if let loadingAnimationView = loadingAnimationView {
            view.addSubview(loadingAnimationView)
        }
    }

    // 显示或隐藏loading, 连接时盖住二维码条码,防止重复扫码
    // show or hide loading view, cover over the barcode image when connecting peripheral, avoid repeated scanning barcode image
    func showLoading(_ show: Bool) {
        if show {
            loadingAnimationView?.snp.remakeConstraints({ make in
                make.center.equalTo(connectImage)
                make.width.height.equalTo(min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) - 20)
            })
            loadingAnimationView?.isHidden = false
            loadingAnimationView?.play()
            loadingBackgroundView?.isHidden = false
        } else {
            loadingAnimationView?.stop()
            loadingAnimationView?.isHidden = true
            loadingBackgroundView?.isHidden = true
        }
    }

    @IBAction func clickSwitchCodeType() {
        codeType2d = !codeType2d
        buttonSwitchCodeType.setTitle(codeType2d ? "switchTo1d".localized() : "switchTo2d".localized(), for: .normal)
        setConnectBarCodeImage()
    }

    @IBAction func clickUseSystemConnectedDevice() {
        let name: String? = nil // "BS50 BG00098"
        let identifier: UUID? = nil // UUID(uuidString: "024CA0D0-8F4D-FB87-3F52-940D47215C77")
        /**
         使用已经在系统设置-蓝牙连上的外围设备,不使用连接二维码
         use the peripheral that has been  connected on ios system setting-bluetooth, jump the connection Data Matrix Code
         - Parameter name: 指定的外围设备名称,可以为空,  the connected peripheral name or nil
         - Parameter identifier: 指定的外围设备identifier,可以为空, the connected peripheral identifier or nil
         - Parameter name=nil && identifier = nil:两个参数都为空则使用系统设置-蓝牙已连上并且sdk未连接过的设备,
                    both two parameters are nil, use peripheral  that have been connected on  system settings-bluetooth but have not been connected to the sdk
         - Returns: true:找到指定设备开始建立ble连接, found the peripheral and establish ble connection.
                    false:未找到设备或者蓝牙关闭, cannot found peripheral or ios bluetooth unavaiable.
         */
        let ret = StarSCANCentral.instance.useSystemConnectedPeripheral(name, identifier)
        AppLog.log.verbose("useSystemConnectedPeripheral =\(ret)")
    }

    @IBAction func clickClearDisconnected() {
        /**
         清除所有已断开连接的设备,不再重试连接
         clear all did disconnected peripherals, no longer reconnect them
         */
        clearUuids = StarSCANCentral.instance.clearDisconnectedPeripherals() // -> [UUID]
    }

    @IBAction func clickBack() {
        self.dismiss(animated: true, completion: {
            self.onDismissHandler?(self.clearUuids)
        })
    }

    func resetBarcodeImage() {
        setConnectBarCodeImage()
    }

    func onStartConnecting(_ peripheral: CBPeripheral, _ reconnect: Bool) {
        showLoading(true)
    }

    func onStopConnecting(_ peripheral: CBPeripheral) {
        showLoading(false)
    }
}
