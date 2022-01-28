//
// Created by Sergey Mergold on 28/01/2022.
//

import Foundation
import CoreBluetooth

class GimdowBleManager {
    let centralManager : CBCentralManager
    let bleHandler: GimdowBleHandler

    init(_ key: GimdowKey) {
        bleHandler = GimdowBleHandler(key)
        centralManager = CBCentralManager(delegate: bleHandler, queue: nil)
    }
}
