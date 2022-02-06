//
// Created by Sergey Mergold on 13/01/2022.
//

import XCTest
@testable import GimdowSmartLockPro

class BytesUtilsTests: XCTestCase {
    static let crc = 55807
    static let lsb: UInt8 = UInt8(bitPattern: -1)
    static let msb: UInt8 = UInt8(bitPattern: -39)
    static let bytes: [UInt8] = [0, 1, 2, 0, 1, 0, 2, 1, 1, 1, 1, 1, 1, 98, 108, lsb, msb]

    func test_calculateFrameCRC16Correct() {
        let crcPrev = 38814
        let result = BytesUtilsTests.bytes.calculateFrameCrc16(crcPrev)
        XCTAssertEqual(BytesUtilsTests.crc, result)
    }

    func test_createLoHiCrcCorrect() {
        let result = BytesUtilsTests.bytes.loHiCrc;
        XCTAssertEqual(BytesUtilsTests.crc, result)
    }

    func test_crcValidationCorrect() {
        let result = BytesUtilsTests.bytes.isCrcValid(BytesUtilsTests.crc)
        XCTAssertTrue(result)
    }

    func test_lsbCalculationCorrect() {
        let result = BytesUtilsTests.crc.lsb;
        XCTAssertEqual(BytesUtilsTests.lsb, result)
    }

    func test_msbCalculationCorrect() {
        let result = BytesUtilsTests.crc.msb;
        XCTAssertEqual(BytesUtilsTests.msb, result)
    }
}
