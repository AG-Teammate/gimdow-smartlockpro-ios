//
// Created by Sergey Mergold on 20/01/2022.
//

import Foundation

public class GimdowKey {
    let key: String
    let lockName: String
    let specialAreas: String
    let keyBytes: [UInt8]

    public init(_ lockName: String, _ key: String, _ specialAreas: String) throws {
        self.lockName = lockName
        guard !key.isEmpty else {
            throw GimdowError.parameterIsRequired("key")
        }
        guard let keyData = Data(base64Encoded: key) else {
            throw GimdowError.invalidKeyData
        }
        self.key = key
        self.specialAreas = specialAreas
        self.keyBytes = [UInt8](keyData)
    }

    lazy var specialAreasList: [Int] = {
        specialAreas.split(separator: ",").map {
                    Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                }
                .filter {
                    $0 > 0
                }
    }()
}
