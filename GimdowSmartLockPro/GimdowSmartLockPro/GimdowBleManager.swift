//
// Created by Sergey Mergold on 28/01/2022.
//

import Foundation
import CoreBluetooth

public class GimdowBleManager {
    let centralManager : CBCentralManager
    let bleHandler: GimdowBleHandler

    public convenience init(_ key: GimdowKey, _ delegate: GimdowLockListenerDelegate, _ scanTimeout: TimeInterval) {
        self.init(key, delegate)
        bleHandler.scanTimeoutSecs = scanTimeout
    }

    public convenience init(_ key: GimdowKey, _ delegate: GimdowLockListenerDelegate) {
        self.init(key)
        bleHandler.delegate = delegate
    }

    public init(_ key: GimdowKey) {
        bleHandler = GimdowBleHandler(key)
        centralManager = CBCentralManager(delegate: bleHandler, queue: nil)
    }
}
