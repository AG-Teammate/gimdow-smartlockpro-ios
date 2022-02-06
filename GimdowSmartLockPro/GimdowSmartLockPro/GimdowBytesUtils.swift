//
// Created by Sergey Mergold on 12/01/2022.
//

import Foundation

extension Int {
    var msb: UInt8 {
        (UInt8)(self >> 8)
    }

    var lsb: UInt8 {
        (UInt8)(self & 255)
    }
}

extension UInt8 {
    var asInt: Int {
        (Int)(self)
    }
}

extension Array where Element == UInt8 {
    var hexString: String {
        self.map { String(format: "%02hhX", $0)}.joined()
    }

    var loHiCrc: Int {
        (self[count - 1].asInt << 8) + (self[count - 2]).asInt
    }

    func isCrcValid(_ crc: Int) -> Bool {
        crc == loHiCrc
    }

    func calculateCrc16(_ crc: Int, _ offset: Int, _ length: Int) -> Int {
        var base = crc
        for byteIndex in 1..<length {
            base ^= self[offset + byteIndex].asInt

            for _ in 0..<8 {
                if (base & 1) == 1 {
                    base = base >> 1 ^ 33800
                } else {
                    base >>= 1
                }
            }
        }
        return (base ^ 65535) & 65535
    }

    func calculateCrc16(_ crc: Int) -> Int {
        calculateCrc16(crc, 0, count)
    }

    func calculateFrameCrc16(_ crc: Int) -> Int {
        calculateCrc16(crc, 0, count - 2)
    }
}

protocol GimdowBytesUtilsProtocol {
    static func generateRandomBytes(_ length: Int) -> [UInt8]
}

class GimdowBytesUtils: GimdowBytesUtilsProtocol {
    static func generateRandomBytes(_ length: Int) -> [UInt8] {
        (0...length).map { _ in
            UInt8.random(in: 0...UInt8.max)
        }
    }
}
