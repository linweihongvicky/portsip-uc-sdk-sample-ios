//
//  PortCxProvider.swift
//  UCSample
//
//  Created by portsip on 17/2/22.
//  Copyright © 2017 portsip. All rights reserved.
//

import CallKit
import UIKit

@available(iOS 10.0, *)
class PortCxProvider: NSObject, CXProviderDelegate {
    var cxprovider: CXProvider!
    var callManager: CallManager!
    var callController: CXCallController!
    private static var instance: PortCxProvider = PortCxProvider()

    class var shareInstance: PortCxProvider {
        PortCxProvider.instance
    }

    override init() {
        super.init()
        configurationCallProvider()
    }

    func configurationCallProvider() {
        let infoDic = Bundle.main.infoDictionary!
        let localizedName = infoDic["CFBundleName"] as! String

        let providerConfiguration = CXProviderConfiguration(localizedName: localizedName)
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        if let iconMaskImage = UIImage(named: "IconMask") {
            providerConfiguration.iconTemplateImageData = iconMaskImage.pngData()
        }

        cxprovider = CXProvider(configuration: providerConfiguration)

        cxprovider.setDelegate(self, queue: DispatchQueue.main)

        callController = CXCallController()
    }

    func reportOutgoingCall(callUUID: UUID, startDate: Date) -> (UUID) {
        cxprovider.reportOutgoingCall(with: callUUID, connectedAt: startDate)
        return callUUID
    }

//    #pragma mark - CXProviderDelegate

    func providerDidReset(_: CXProvider) {
        callManager.stopAudio()
        print("Provider did reset")

        callManager.clear()
    }

    func provider(_: CXProvider, perform action: CXPlayDTMFCallAction) {
        print(" CXPlayDTMFCallAction \(action.callUUID) \(action.digits)")

        var dtmf: Int32 = 0
        switch action.digits {
        case "0":
            dtmf = 0
        case "1":
            dtmf = 1
        case "2":
            dtmf = 2
        case "3":
            dtmf = 3
        case "4":
            dtmf = 4
        case "5":
            dtmf = 5
        case "6":
            dtmf = 6
        case "7":
            dtmf = 7
        case "8":
            dtmf = 8
        case "9":
            dtmf = 9
        case "*":
            dtmf = 10
        case "#":
            dtmf = 11
        default:
            return
        }
        callManager.sendDTMF(uuid: action.callUUID, dtmf: dtmf)
        action.fulfill()
    }

    func provider(_: CXProvider, timedOutPerforming _: CXAction) {}

    func provider(_: CXProvider, perform action: CXSetGroupCallAction) {
        guard callManager.findCallByUUID(uuid: action.callUUID) != nil else {
            action.fail()
            return
        }

        if action.callUUIDToGroupWith != nil {
            callManager.joinToConference(uuid: action.callUUID)
            action.fulfill()
        } else {
            callManager.removeFromConference(uuid: action.callUUID)
            action.fulfill()
        }

        action.fulfill()
    }

    func performAnswerCall(uuid: UUID, completion completionHandler: @escaping (_ success: Bool) -> Void) {
        let session = callManager.findCallByUUID(uuid: uuid)

        if session != nil {
            if session!.session.sessionId <= INVALID_SESSION_ID {
                // Haven't received INVITE CALL
                session?.session.callKitAnswered = true
                session?.session.callKitCompletionCallback = completionHandler
            } else {
                if callManager.answerCallWithUUID(uuid: uuid, isVideo: session?.session.videoState ?? false) {
                    completionHandler(true)
                } else {
                    print("Answer Call Failed!")
                    completionHandler(false)
                }
            }
        } else {
            print("Session not found")

            completionHandler(false)
        }
    }

    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        performAnswerCall(uuid: action.callUUID) { success in
            if success {
                action.fulfill()
            } else {
                action.fail()
            }
        }
        // [action fulfill];
        print("performAnswerCallAction fail")
    }

    func provider(_: CXProvider, perform action: CXStartCallAction) {
        print("performStartCallAction uuid = \(action.callUUID)")

        let sessionid = callManager.makeCallWithUUID(callee: action.handle.value, displayName: action.handle.value, videoCall: action.isVideo, uuid: action.callUUID)
        if sessionid >= 0 {
            action.fulfill()
        } else {
            action.fail()
        }
    }

    func provider(_: CXProvider, perform action: CXEndCallAction) {
        let result = callManager.findCallByUUID(uuid: action.callUUID)
        if result != nil {
            callManager.hungUpCall(uuid: action.callUUID)
        }

        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        let result = callManager.findCallByUUID(uuid: action.callUUID)
        if result != nil {
            callManager.holdCall(uuid: action.callUUID, onHold: action.isOnHold)
        }

        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        let result = callManager.findCallByUUID(uuid: action.callUUID)
        if result != nil {
            callManager.muteCall(action.isMuted, uuid: action.callUUID)
        }
        action.fulfill()
    }

    func provider(_: CXProvider, didActivate _: AVAudioSession) {
        callManager.startAudio()
    }

    func provider(_: CXProvider, didDeactivate _: AVAudioSession) {
        callManager.stopAudio()
    }
}
