//
// Created by Sergey Mergold on 04/02/2022.
//

import Foundation

class GimdowViewModel : ObservableObject {
    @Published var tfRoomNumber: String = "101"
    @Published var tfSpecialAreas: String = ""
    @Published var tfKey: String = "sSAQAGMjTgeyiRHQUCBedCW0nU+wEDAAnCheOyndCT5cW7IqhvbWveToMx+gpSToHTjdnnqPim3Ur4NmOKCrIKoRiYSyGo//"

    @Published var txtStatus: String = ""

    @Published var buttonLabel: String = "Press To Open"
    @Published var buttonIsEnabled: Bool = true

    @Published var alertIsPresented: Bool = false
    @Published var alertText: String = ""
}
