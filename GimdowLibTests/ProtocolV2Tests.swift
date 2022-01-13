//
// Created by Sergey Mergold on 13/01/2022.
//

import XCTest

@testable import GimdowLib

class TestBytesUtils: GimdowBytesUtilsProtocol {
    static func generateRandomBytes(_ length: Int) -> [UInt8] {
        [38, 33]
    }
}

class ProtocolV2Tests: XCTestCase {
    let sessionBytes: [UInt8] = [38, 33, 52, -114].map { UInt8(bitPattern: $0) }
    let fKey: [UInt8] = [-79, 32, 16, 0, 99, 35, 78, 7, -78, -119, 17, -48, 80, 32, 94, 116,
                         37, -76, -99, 79, -80, 16, 48, 0, -100, 40, 94, 59, 41, -35, 9, 62, 92, 91, -78, 42,
                         -122, -10, -42, -67, -28, -24, 51, 31, -96, -91, 36, -24, 29, 56, -35, -98, 122, -113,
                         -118, 109, -44, -81, -125, 102, 56, -96, -85, 32, -86, 17, -119, -124, -78, 26, -113, -1]
            .map { UInt8(bitPattern: $0) }
    let crcAuth1 = 29
    let crcAuth2 = 57545
    let crcAuth3 = 23758
    let crcAuth4 = 54986

    override func setUpWithError() throws {
        GimdowProtocolV2.gimdowBytesUtils = TestBytesUtils.self
    }

    func test_buildAuthChallengeResponseCorrect() throws {
        let input: [UInt8] = [0, 1, 1, -51, -78, -17, 32, -59, -28, 3, 1, 0, 39, 22, 122, -1, 29, 0].map { UInt8(bitPattern: $0) }
        let output: [UInt8] = [0, 1, 2, 0, 1, 0, 2, 1, 1, 1, 1, 1, 1, 38, 33, -55, -32].map { UInt8(bitPattern: $0) }
        let device = try GimdowBleDevice("AGUA", 0)

        let result = GimdowProtocolV2.buildAuthChallengeResponse(input, device)

        XCTAssertEqual(output, result)
        XCTAssertEqual(crcAuth1, device.crcAuth1)
        XCTAssertEqual(crcAuth2, device.crcAuth2)
    }

    func test_checkAuthPassedCorrect() throws {
        let input: [UInt8] = [0, 1, 2, -68, 43, 52, -114, 127, -27, -50, 92].map { UInt8(bitPattern: $0) }
        let device = try GimdowBleDevice("AGUA", 0)
        device.crcAuth2 = crcAuth2

        let result = GimdowProtocolV2.checkAuthPassed(input, device)
        XCTAssertTrue(result)
        XCTAssertEqual(crcAuth3, device.crcAuth3)
    }

    // todo: fix
    func test_buildSendKeyV2Correct() throws {
        let output: [UInt8] = [UInt8(bitPattern: -54), UInt8(bitPattern: -42)] + fKey
        let device = try GimdowBleDevice("AGUA", 0)
        device.crcAuth1 = crcAuth1
        device.crcAuth2 = crcAuth2
        device.crcAuth3 = crcAuth3
        device.sessionKey = sessionBytes

        let result = GimdowProtocolV2.buildSendKeyV2(fKey, device)
        XCTAssertEqual(output, result)
        XCTAssertEqual(crcAuth4, device.crcAuth4)
    }

}
