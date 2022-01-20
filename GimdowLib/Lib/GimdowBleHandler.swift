//
// Created by Sergey Mergold on 12/01/2022.
//

import Foundation
import CoreBluetooth
import os

let CHAR_RX_UUID = CBUUID(string: "713D0002-503E-4C75-BA94-3148F18D941E")
let CHAR_TX_UUID = CBUUID(string: "713D0003-503E-4C75-BA94-3148F18D941E")
let SERVICE_UUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
let NOTIFY_DESCRIPTOR_UUID = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")

enum RxMode: Int {
    case RX_MODE_INIT = -1,
         RX_MODE_SCAN = 0,
         RX_MODE_CONN = 1,
         RX_MODE_AUTH = 2,
         RX_MODE_NAME = 3,
         RX_MODE_KEY = 4
}

class GimdowBleHandler: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var delegate: GimdowLockListenerDelegate! = nil

    var peripherals = Dictionary<CBPeripheral, NSNumber>()

    var key: GimdowKey!
    var device: GimdowBleDevice!

    var scanTimer: Timer!
    var overAllTimer: Timer!
    var waitForNotifyEnabled: Timer!
    var waitForDeviceResponse: Timer!
    var waitNotify: Bool = false
    var waitDeviceResp: Bool = false
    var repeatData: Data!
    var cm: CBCentralManager!
    var readerPeripheral: CBPeripheral!
    var authTimer: Timer!
    var disconnectTimer: Timer!

    var readCharacteristic: CBCharacteristic!
    var writeCharacteristic: CBCharacteristic!

    var rxMode: RxMode = RxMode.RX_MODE_INIT

    init(key: GimdowKey) {
        super.init()
        self.key = key
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch (central.state) {
            case CBManagerState.poweredOn:
                startScan(central)
                break
            default:
                break
            }
        } else {
            switch central.state.rawValue {
            case 5: //CBCentralManagerState.poweredOn:
                startScan(central)
                break
            default:
                break
            }
        }
    }

    private func startScan(_ central: CBCentralManager) {
        scanTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(scanTimeout), userInfo: nil, repeats: false)

        cm = central
        rxMode = RxMode.RX_MODE_SCAN
        central.scanForPeripherals(withServices: [SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])

    }

    @objc func scanTimeout() {
        if (scanTimer!.isValid) {
            delegate?.didScanTimeout()
            cm.stopScan()
        } else {
            if (rxMode == RxMode.RX_MODE_AUTH) {
                delegate.didFail(.ERROR_CONNECT)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advs = advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID]
        let advn = advertisementData["kCBAdvDataLocalName"] as! String
        let rssi = Int(truncating: RSSI)

        if (advs[0] != SERVICE_UUID || advn.isEmpty) { return }

        os_log(.debug, "Found device: \(advn), rssi: \(rssi)")

        do {
            let device = try GimdowBleDevice(advn, rssi)
        } catch {
            os_log(.error, "Device error: \(String(describing: error))")
        }

    }
}
