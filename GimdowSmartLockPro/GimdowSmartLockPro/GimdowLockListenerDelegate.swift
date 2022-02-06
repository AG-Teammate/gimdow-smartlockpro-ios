//
// Created by Sergey Mergold on 20/01/2022.
//

import Foundation

public protocol GimdowLockListenerDelegate {
    func didStartOpen()
    func didScanTimeout()
    func didFindDevice()
    func didFinishOpen()
    func didOpen(_ result: GimdowLockResult)
    func didFail(_ result: GimdowLockResult)
}

extension GimdowLockListenerDelegate {
    func didStartOpen() {}
    func didScanTimeout() {}
    func didFindDevice() {}
    func didFinishOpen() {}
    func didOpen(_ result: GimdowLockResult) {}
    func didFail(_ result: GimdowLockResult) {}
}
