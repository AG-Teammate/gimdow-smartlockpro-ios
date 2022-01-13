//
// Created by Sergey Mergold on 13/01/2022.
//

import Foundation
import os

class GimdowBleDevice {
    let deviceName: String
    let rssi: Int
    let deviceNumber: Int
    let specialArea: Int

    var sessionKey: [UInt8]
    var crcAuth1: Int = 0
    var crcAuth2: Int = 0
    var crcAuth3: Int = 0
    var crcAuth4: Int = 0

    var appResponseChallenge: [UInt8] = []
    var keyParts: [UInt8] = []

    init(_ deviceName: String, _ rssi: Int) throws {
        self.deviceName = deviceName
        self.rssi = rssi
        sessionKey = [UInt8](repeating: 0, count: 4)
        os_log(OSLogType.debug, "Init device: \(deviceName)")

        guard let deviceNameData = Data(base64Encoded: deviceName) else {
            os_log(OSLogType.error, "Invalid base64 deviceName: \(deviceName)")
            throw GimdowError.invalidDeviceName(deviceName)
        }
        let deviceNameBytes = [UInt8](deviceNameData)
        deviceNumber = deviceNameBytes.count < 2 ? 0 : (deviceNameBytes[0].asInt << 8) + deviceNameBytes[1].asInt
        specialArea = deviceNameBytes.count < 3 ? 0 : deviceNameBytes[2].asInt
    }

    class func unwrapDeviceNumber(_ data: [UInt8]) -> Int {
        if data.count < 2 {
            return 0
        } else {
            return (data[0].asInt << 8) + data[1].asInt
        }
    }

    class private func unwrapSpecialArea(_ data: [UInt8]) -> Int {
        data[2].asInt
    }
}
