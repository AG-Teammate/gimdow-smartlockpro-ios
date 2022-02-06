//
//  ContentView.swift
//  GimdowLib
//
//  Created by Sergey Mergold on 12/01/2022.
//
//

import SwiftUI
import GimdowSmartLockPro

struct ContentView: View, GimdowLockListenerDelegate {
    @State private var gManager: GimdowBleManager!
    @ObservedObject private var viewModel = GimdowViewModel()

    var body: some View {
        GeometryReader { proxy in
            Form {
                HStack {
                    VStack {
                        TextField("Room Number", text: $viewModel.tfRoomNumber).padding()
                    }
                    VStack {
                        TextField("Special Areas", text: $viewModel.tfSpecialAreas).padding()
                    }
                }
                HStack {
                    TextField("Key", text: $viewModel.tfKey).padding()
                }
                HStack {
                    Text(viewModel.txtStatus)
                            .padding()
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(height: (proxy.size.height * 0.4), alignment: .top)
                            .multilineTextAlignment(.leading)
                }
                HStack {
                    Button(viewModel.buttonLabel, action: btnOpenAction)
                            .disabled(!viewModel.buttonIsEnabled)
                            .padding()
                            .alert(isPresented: $viewModel.alertIsPresented, content: {
                                Alert(title: Text("Error"),
                                        message: Text(viewModel.alertText),
                                        dismissButton: Alert.Button.cancel(Text("Dismiss"), action: {
                                            viewModel.alertIsPresented = false
                                        }))
                            })
                }
            }
        }

    }

    func btnOpenAction() {
        viewModel.buttonLabel = "Process open"
        viewModel.buttonIsEnabled = false
        viewModel.txtStatus = ""

        do {
            let key = try GimdowKey(viewModel.tfRoomNumber, viewModel.tfKey, viewModel.tfSpecialAreas)
            gManager = GimdowBleManager(key, self)
        } catch GimdowError.parameterIsRequired(let paramName) {
            uiAlert("Value is required: \(paramName).")
            uiFree()
        } catch GimdowError.invalidKeyData {
            uiAlert("Invalid key data!")
            uiFree()
        } catch {
            uiAlert("Unexpected error: \(String(describing: error))")
            uiFree()
        }
    }

    func didStartOpen() {
        DispatchQueue.main.async {
            addStatusText("Start Process")
            uiWait()
        }
    }

    func didScanTimeout() {
        DispatchQueue.main.async {
            addStatusText("Stopping Scan (timeout)")
            uiAlert("No devices found, try again.")
            uiFree()
        }
    }

    func didFindDevice() {
        DispatchQueue.main.async {
            addStatusText("Device found, trying to connect...")
        }
    }

    func didFinishOpen() {
        DispatchQueue.main.async {
            addStatusText("Process finished")
            uiFree()
        }
    }

    func didOpen(_ result: GimdowLockResult) {
        DispatchQueue.main.async {
            uiOpen()
        }
    }

    func didFail(_ result: GimdowLockResult) {
        DispatchQueue.main.async {
            var text = ""
            switch result {
            case .ERROR_ENABLE_NOTIFY:
                text = "Could not enable device notification"
                break
            case .ERROR_DEVICE_RESPONSE:
                text = "Device Challenge failed"
                break
            case .ERROR_KEY_RESULT:
                text = "Device didn't return key result"
                break
            case .ERROR_CONNECT:
                text = "Could not connect to device during 10s"
                break
            case .ERROR_DISCOVER_SERVICES:
                text = "Could not find necessary services on the connected device"
                break
            case .ERROR_AUTH_FAILED:
                text = "Authentication failed"
                break
            case .KEY_FORMAT_INVALID:
                text = "The key is invalid"
                break
            case .NO_ACCESS_CONTROL:
                text = "The key is not authorized for this device"
                break
            case .END_TIME_EXCEEDED:
                text = "The key has expired"
                break
            case .ERROR_CM_STATE_UNSUPPORTED:
                text = "Bluetooth LE is not supported"
                break
            case .ERROR_CM_STATE_UNAUTHORIZED:
                text = "Bluetooth LE is not authorized"
                break
            case .ERROR_CM_STATE_POWEREDOFF:
                text = "Bluetooth is off"
                break
            default:
                text = String(describing: result)
            }
            uiOpenFailed(text)
        }
    }

    func addStatusText(_ text: String) {
        viewModel.txtStatus = viewModel.txtStatus + "\n" + text
    }

    func uiWait() {
        viewModel.buttonIsEnabled = false
        addStatusText("Wait...")
    }

    func uiOpen() {
        viewModel.buttonIsEnabled = false
        addStatusText("Open successful")
    }

    func uiOpenFailed(_ reason: String) {
        viewModel.buttonIsEnabled = false
        addStatusText("Open failed: " + reason)
    }

    func uiFree() {
        viewModel.buttonIsEnabled = true
        viewModel.buttonLabel = "Press To Open"
    }

    func uiAlert(_ message: String) {
        viewModel.alertText = message
        viewModel.alertIsPresented = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
