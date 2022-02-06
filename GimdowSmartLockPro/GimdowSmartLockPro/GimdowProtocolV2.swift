//
// Created by Sergey Mergold on 13/01/2022.
//

import Foundation
import os

class GimdowProtocolV2 {
    static var gimdowBytesUtils: GimdowBytesUtilsProtocol.Type = GimdowBytesUtils.self

    static func buildAuthChallengeResponse(_ frameBytes: [UInt8], _ device: GimdowBleDevice) -> [UInt8]? {
        let crcAuth1 = frameBytes.calculateFrameCrc16(device.deviceNumber)
        if !frameBytes.isCrcValid(crcAuth1) {
            return nil
        }

        os_log(.debug, "CRC1: <\(crcAuth1)>")
        device.crcAuth1 = crcAuth1
        let sessionKey = gimdowBytesUtils.generateRandomBytes(2)
        device.sessionKey[0] = sessionKey[0]
        device.sessionKey[1] = sessionKey[1]
        var response: [UInt8] = [0, 1, 2, 0, 1, 0, 2, 1, 1, 1, 1, 1, 1, sessionKey[0], sessionKey[1], 0, 0]
        let crc = response.calculateFrameCrc16(crcAuth1)
        response[15] = crc.lsb
        response[16] = crc.msb
        let crcAuth2 = response.loHiCrc
        os_log(.debug, "CRC2: <\(crcAuth2)>")
        device.crcAuth2 = crcAuth2
        return response
    }

    static func checkAuthPassed(_ frameBytes: [UInt8], _ device: GimdowBleDevice) -> Bool {
        os_log(.debug, "Auth passed: <\(frameBytes.hexString)>")
        let crcAuth3 = frameBytes.calculateFrameCrc16(device.crcAuth2)
        if !frameBytes.isCrcValid(crcAuth3) {
            return false
        }

        os_log(.debug, "CRC3: <\(crcAuth3)>")
        device.crcAuth3 = crcAuth3
        device.sessionKey[2] = frameBytes[5]
        device.sessionKey[3] = frameBytes[6]
        return true
    }

    static func buildSendKeyV2(_ decodedGimdowKey: [UInt8], _ device: GimdowBleDevice) -> [UInt8] {
        var crcDataBytes: [UInt8] = [0, device.crcAuth2.lsb, device.crcAuth2.msb]
        crcDataBytes += device.sessionKey
        crcDataBytes += [device.crcAuth3.lsb, device.crcAuth3.msb]
        crcDataBytes += decodedGimdowKey

        let crcAuth4 = crcDataBytes.calculateCrc16(device.crcAuth1)
        device.crcAuth4 = crcAuth4
        os_log(.debug, "CRC4: <\(crcAuth4)>")

        let keyBytes: [UInt8] = [crcAuth4.lsb, crcAuth4.msb] + decodedGimdowKey
        os_log(.debug, "Key: <\(keyBytes.hexString)>")
        return keyBytes
    }

    static func createKeyPartsV2(_ keyBytes: [UInt8]) -> [[UInt8]] {
        var keyParts: [[UInt8]] = []
        let fullParts = keyBytes.count / 16
        let remainder = keyBytes.count % 16
        let partsCount = remainder == 0 ? fullParts : fullParts + 1

        for partIndex in stride(from: partsCount - 1, through: 0, by: -1) {
            let partLength = partIndex == partsCount - 1 ? remainder : 16
            keyParts.append(createKeyChunkV2(keyBytes, partIndex, partLength))
        }

        return keyParts
    }

    private static func createKeyChunkV2(_ keyBytes: [UInt8], _ partIndex: Int, _ size: Int) -> [UInt8] {
        [(UInt8)(partIndex)] + keyBytes.dropFirst(partIndex*16).prefix(size)
    }
}
