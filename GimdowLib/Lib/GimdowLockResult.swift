//
// Created by Sergey Mergold on 20/01/2022.
//

import Foundation

enum GimdowLockResult: Int {
    case DOORS_OPEN_SUCCESS = 0,
         INVALID_CRC = 1,
         INVALID_KEY = 2,
         INVALID_GENERATION = 17,
         NO_VALID_ACCESS_ZONE = 18,
         NO_VALID_ACCESS_POINT = 19,
         ID_DOES_NOT_MATCH = 20,
         SA_INVALID = 21,
         KEY_ALREADY_USED = 22,
         BLACKLIST_KEY = 23,
         START_TIME_NOT_REACHED = 33,
         END_TIME_EXCEEDED = 34,
         TIME_MASK_NOT_MATCH = 35,
         INVALID_TIME_MODEL = 36,
         REFRESH_TIME_TOO_LONG_AGO = 37,
         KEY_LOCKED = 38,
         DND_ACCESS_DENIED = 49,
         SABOTAGE_BLOCKED = 50,
         BATTERY_BLOCKED = 51,
         PERMANENTLY_BLOCKED = 52,
         NO_TOGGLE_PRIVILEGE = 53,
         NO_ACCESS_CONTROL = 65,
         ERROR_RFID_TAG = 66,
         KEY_FORMAT_INVALID = 67,
         SA_ENTRY_EXPIRED = 68,
         SA_MASTER_OP = 69,
         NO_AUTHORIZATION = 70,
         INVALID_TIMEZONE = 71,
         ERROR_ENABLE_NOTIFY = 101,
         ERROR_DEVICE_RESPONSE = 102,
         ERROR_KEY_RESULT = 103,
         ERROR_CONNECT = 104,
         ERROR_DISCOVER_SERVICES = 105,
         ERROR_AUTH_FAILED = 106,
         ERROR_CM_STATE_UNSUPPORTED = 111,
         ERROR_CM_STATE_UNAUTHORIZED = 112,
         ERROR_CM_STATE_POWEREDOFF = 113
}
