//
// Created by Sergey Mergold on 20/01/2022.
//

import Foundation

class GimdowKey {
    let key: String
    let lockName: String
    let specialAreas: String

    init(_ lockName: String, _ key: String, _ specialAreas: String) throws {
        self.lockName = lockName
        guard !key.isEmpty else {
            throw GimdowError.parameterIsRequired("key")
        }
        self.key = key
        self.specialAreas = specialAreas
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
