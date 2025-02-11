//
// Created by Sergey Mergold on 13/01/2022.
//

import Foundation

public enum GimdowError : Error {
    case invalidDeviceName(_ deviceName: String)
    case parameterIsRequired(_ paramName: String)
    case invalidKeyData
}
