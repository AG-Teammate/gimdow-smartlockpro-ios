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
    var keyParts: [[UInt8]] = []

    var roomNumber: String {
        specialArea == 0 ? String(deviceNumber) : "Special: \(specialArea)"
    }


    init(_ deviceName: String, _ rssi: Int) throws {
        self.deviceName = deviceName
        self.rssi = rssi
        sessionKey = [UInt8](repeating: 0, count: 4)
        os_log(.debug, "Init device: \(deviceName)")

        guard let deviceNameData = Data(base64Encoded: deviceName) else {
            os_log(.error, "Invalid base64 deviceName: \(deviceName)")
            throw GimdowError.invalidDeviceName(deviceName)
        }
        let deviceNameBytes = [UInt8](deviceNameData)
        deviceNumber = deviceNameBytes.count < 2 ? 0 : (deviceNameBytes[0].asInt << 8) + deviceNameBytes[1].asInt
        specialArea = deviceNameBytes.count < 3 ? 0 : deviceNameBytes[2].asInt
    }

    func checkDeviceChallenge(_ deviceChallenge: [UInt8]) -> Bool {
        let result = GimdowProtocolV2.buildAuthChallengeResponse(deviceChallenge, self)
        appResponseChallenge = result ?? []
        return result != nil
    }

    func checkDecodeDeviceResponse(_ deviceResponse: [UInt8]) -> Bool {
        if !isAuthenticatedV2(deviceResponse) { return false }
        os_log(.debug, "Authenticated response: <\(deviceResponse.hexString)>")
        return GimdowProtocolV2.checkAuthPassed(deviceResponse, self)
    }

    func encodeSendKeyData(_ keyData: [UInt8]) -> Bool {
        let sendKey = GimdowProtocolV2.buildSendKeyV2(keyData, self)
        keyParts = GimdowProtocolV2.createKeyPartsV2(sendKey)
        return true
    }

    func isValidForKey(_ keyName: String, _ specialAreas: [Int], _ minRssi: Int) -> Bool {
        if keyName.isEmpty || rssi < minRssi { return false }
        if let keyNumber = Int(keyName) {
            if keyNumber == deviceNumber {
                os_log(.debug, "BLE device \(self.deviceName) matches key: \(keyName)")
                return true
            } else if specialAreas.contains(specialArea) {
                os_log(.debug, "BLE device \(self.deviceName) matches special areas of key: \(keyName)")
                return true
            } else {
                os_log(.debug, "BLE device \(self.deviceName) does NOT match key: \(keyName)")
                return false
            }
        } else {
            os_log(.error, "Invalid keyName: \(keyName)")
            return false
        }
    }

    func checkAuthVersion(_ changeData: [UInt8]) -> Bool {
        if !isAuthenticatedV1(changeData) {
            os_log(.debug, "Frame is invalid for auth")
            return false
        }

        let offeredVersions = changeData[9]
        let v3Offered = (offeredVersions & 4) != 0
        let v2Offered = (offeredVersions & 2) != 0
        let v1Offered = (offeredVersions & 1) != 0
        os_log(.debug, "Offered auth versions: \(String(format: "%02hhX", offeredVersions)) v3=\(v3Offered) v2=\(v2Offered) v1=\(v1Offered)")

        if v2Offered || v1Offered {
            return true
        }

        os_log(.error, "Unsupported auth version")
        return false
    }

    private func isAuthenticatedV1(_ frameBytes: [UInt8]) -> Bool {
        frameBytes[0] == 0 && frameBytes[1] == 1 && frameBytes[2] == 1 && frameBytes.count > 12
    }

    private func isAuthenticatedV2(_ frameBytes: [UInt8]) -> Bool {
        frameBytes[0] == 0 && frameBytes[1] == 1 && frameBytes[2] == 2 && frameBytes.count >= 8
    }

}
