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
let MIN_RSSI = -75

enum RxMode: Int {
    case RX_MODE_INIT = -1,
         RX_MODE_SCAN = 0,
         RX_MODE_CONN = 1,
         RX_MODE_AUTH = 2,
         RX_MODE_AUTH2 = 3,
         RX_MODE_KEY = 4
}

class GimdowBleHandler: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var delegate: GimdowLockListenerDelegate? = nil

    var peripherals = Dictionary<CBPeripheral, NSNumber>()

    var key: GimdowKey!
    var device: GimdowBleDevice!

    var scanTimer: Timer!
    var overAllTimer: Timer!
    var authTimer: Timer!
    var keyResultTimer: Timer!
    var disconnectTimer: Timer!

    var waitNotify: Bool = false
    var cm: CBCentralManager!
    var readerPeripheral: CBPeripheral!

    var readCharacteristic: CBCharacteristic!
    var writeCharacteristic: CBCharacteristic!

    var rxMode: RxMode = .RX_MODE_INIT
    var keyPart = 0

    init(_ key: GimdowKey) {
        super.init()
        self.key = key
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch (central.state) {
            case .poweredOn:
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
        rxMode = .RX_MODE_SCAN
        central.scanForPeripherals(withServices: [SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advs = advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID]
        let advn = advertisementData["kCBAdvDataLocalName"] as! String
        let rssi = Int(truncating: RSSI)

        if (advs[0] != SERVICE_UUID || advn.isEmpty) { return }

        os_log(.debug, "Found device: \(advn), rssi: \(rssi)")

        do {
            let device = try GimdowBleDevice(advn, rssi)
            if device.isValidForKey(key.lockName, key.specialAreasList, MIN_RSSI) {
                self.device = device
                scanTimer.invalidate()
                central.stopScan()

                delegate?.didFindDevice()
                os_log(.debug, "Connecting to device: \(advn)")

                readerPeripheral = peripheral
                readerPeripheral.delegate = self
                cm.connect(peripheral, options: nil)
            }
        } catch {
            os_log(.error, "Device error: \(String(describing: error))")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log(.debug, "centralManager didConnect")
        peripheral.discoverServices([SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log(.debug, "centralManager didDisconnectPeripheral")
        if error != nil {
            os_log(.error, "centralManager didDisconnectPeripheral error: \(String(describing: error))")
        }
        delegate?.didFinishOpen()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            os_log(.error, "peripheral didDiscoverServices error: \(String(describing: error))")
            return
        }
        os_log(.debug, "peripheral didDiscoverServices")

        guard let service = (peripheral.services?.first { $0.uuid == SERVICE_UUID }) else {
            os_log(.error, "peripheral didDiscoverServices: service not found")
            return
        }

        peripheral.discoverCharacteristics(characteristicsArray, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            os_log(.error, "peripheral didDiscoverCharacteristicsForService error: \(String(describing: error))")
            return
        }
        os_log(.debug, "peripheral didDiscoverCharacteristicsForService")

        guard let rxChar = (service.characteristics?.first {$0.uuid.isEqual(CHAR_RX_UUID)}) else {
            os_log(.error, "peripheral didDiscoverCharacteristicsFor: RX characteristic not found")
            return
        }

        guard let txChar = (service.characteristics?.first {$0.uuid.isEqual(CHAR_TX_UUID)}) else {
            os_log(.error, "peripheral didDiscoverCharacteristicsForService: TX characteristic not found")
            return
        }

        readCharacteristic = rxChar
        writeCharacteristic = txChar

        usleep(20000)
        rxMode = .RX_MODE_CONN
        // todo: make configurable
        overAllTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(overAllTimeout), userInfo: nil, repeats: false)
        peripheral.setNotifyValue(true, for: readCharacteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            os_log(.error, "peripheral didUpdateNotificationStateForCharacteristic error: \(String(describing: error))")
            return
        }
        os_log(.debug, "peripheral didUpdateNotificationStateForCharacteristic")

        if characteristic.isNotifying {
            rxMode = .RX_MODE_AUTH
            authTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(authTimeout), userInfo: nil, repeats: false)
        } else {
            disconnectTimer.invalidate()
//            switch(rxMode){
//            case .RX_MODE_AUTH:
//                delegate?.didFail(.ERROR_AUTH_FAILED)
//                break
//            case .RX_MODE_KEY:
//                delegate?.didFail(.ERROR_KEY_RESULT)
//                break
//            default:
//                break
//            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if((error) != nil){
            os_log(.error, "peripheral didWriteValueForCharacteristic error: \(String(describing: error))")
            return
        }
        os_log(.debug, "peripheral didWriteValueForCharacteristic")

        if device.keyParts.count > 0 && characteristic.value != nil
                   && [UInt8](characteristic.value!) == device.keyParts[keyPart] {
            if keyPart < device.keyParts.count - 1 {
                keyPart += 1
                usleep(100000)
                sendBlock(keyPart, peripheral)
            } else {
                keyResultTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(keyResultTimeout), userInfo: nil, repeats: false)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if((error) != nil){
            os_log(.error, "peripheral didUpdateValueForCharacteristic error: \(String(describing: error))")
            return
        }
        os_log(.debug, "peripheral didUpdateValueForCharacteristic")

        if characteristic.uuid == CHAR_RX_UUID {
            checkCharacteristicChange(characteristic.value,peripheral: peripheral)
        }
    }

    func checkCharacteristicChange(_ data : Data? ,peripheral: CBPeripheral) {
        if data == nil || data?.count == 0 {
            os_log(.debug, "Ignoring empty data frame")
            return
        }
        let changeData = [UInt8](data!)

        if changeData[0] == 0xff {
            os_log(.debug, "Device timeout")
            disconnectFromGimdowDevice(peripheral)
            return
        }

        if changeData[0] == 0 && changeData[1] == 3 {
            os_log(.debug, "Invalid card data")
            authFailed(peripheral)
            return
        }

        if rxMode == .RX_MODE_AUTH {
            if !device.checkAuthVersion(changeData) {
                authFailed(peripheral)
                return
            }
            deviceChallenge(changeData, peripheral)
        } else if rxMode == .RX_MODE_AUTH2 {
            deviceResponse(changeData, peripheral)
        } else if (rxMode == .RX_MODE_KEY) {
            decodeKeyResult(changeData, peripheral)
        }
    }

    func deviceChallenge(_ challengeData: [UInt8], _ peripheral: CBPeripheral) {
        authTimer.invalidate()
        if device.checkDeviceChallenge(challengeData) {
            usleep(100000)
            let responseBytes = device.appResponseChallenge
            let responseData = Data(responseBytes)
            peripheral.writeValue(responseData, for: writeCharacteristic, type: .withResponse)
            rxMode = .RX_MODE_AUTH2
        } else {
            delegate?.didFail(.ERROR_DEVICE_RESPONSE)
            disconnectFromGimdowDevice(peripheral)
        }
    }

    func deviceResponse(_ responseData: [UInt8], _ peripheral: CBPeripheral) {
        if device.checkDecodeDeviceResponse(responseData) && device.encodeSendKeyData(key.keyBytes) {
            usleep(100000)
            rxMode = .RX_MODE_KEY
            sendBlock(keyPart, peripheral)
        } else {
            delegate?.didFail(.ERROR_DEVICE_RESPONSE)
            disconnectFromGimdowDevice(peripheral)
        }
    }

    func decodeKeyResult(_ keyResultData: [UInt8], _ peripheral: CBPeripheral) {
        keyResultTimer.invalidate()
        if keyResultData[0] == 0 && keyResultData[1] == 2 && (keyResultData.count == 8 || keyResultData.count == 16) {
            let openResultCode = keyResultData[7]
            if openResultCode == 0 {
                os_log(.debug, "Open lock success")
                delegate?.didOpen(.DOORS_OPEN_SUCCESS)
            } else {
                os_log(.debug, "Open lock failed")
                delegate?.didFail(GimdowLockResult.init(rawValue: Int(openResultCode)) ?? .INVALID_KEY)
            }
        } else {
            delegate?.didFail(.INVALID_KEY)
        }
        disconnectFromGimdowDevice(peripheral)
    }

    func sendBlock(_ blockIdx: Int, _ peripheral: CBPeripheral) {
        let keyPart = device.keyParts[blockIdx]
        os_log(.debug, "Send block: \(blockIdx), value: \(keyPart.hexString)")
        let keyData = Data(keyPart)
        peripheral.writeValue(keyData, for: writeCharacteristic, type: .withResponse)
    }

    func authFailed(_ peripheral:CBPeripheral) {
        if rxMode == .RX_MODE_AUTH {
            delegate?.didFail(.ERROR_AUTH_FAILED)
        }

        disconnectFromGimdowDevice(peripheral)
    }

    func disconnectFromGimdowDevice(_ peripheral: CBPeripheral) {
        rxMode = .RX_MODE_INIT
        disconnectTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(hardDisconnect), userInfo: nil, repeats: false)
        peripheral.setNotifyValue(false, for: readCharacteristic)
        overAllTimer.invalidate()
    }

    @objc func scanTimeout() {
        if (scanTimer!.isValid) {
            delegate?.didScanTimeout()
            cm.stopScan()
        } else {
            if (rxMode == .RX_MODE_AUTH) {
                delegate?.didFail(.ERROR_CONNECT)
            }
        }
    }

    @objc func keyResultTimeout() {
        if (keyResultTimer!.isValid) {
            hardDisconnect()
            delegate?.didFail(.ERROR_KEY_RESULT)
        }
    }

    @objc func overAllTimeout(){
        if(overAllTimer!.isValid){
            hardDisconnect()
            delegate?.didFail(.ERROR_CONNECT)
        }
    }

    @objc func authTimeout(){
        rxMode = .RX_MODE_CONN
        if(!waitNotify){
            waitNotify = true
            readerPeripheral.setNotifyValue(true, for: readCharacteristic)
        }else{
            hardDisconnect()
        }
    }

    @objc func hardDisconnect(){
        overAllTimer.invalidate()
        rxMode = .RX_MODE_INIT
        cm.cancelPeripheralConnection(readerPeripheral)
    }
}
