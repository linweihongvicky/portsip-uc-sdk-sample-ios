//
//  CallManager.swift
//  UCSample
//
//  Created by portsip on 17/2/22.
//  Copyright © 2017 portsip. All rights reserved.
//

import CallKit
import UIKit

import Foundation

protocol CallManagerDelegate: NSObjectProtocol {
    func onIncomingCallWithoutCallKit(_ sessionId: CLong, existsVideo: Bool, remoteParty: String, remoteDisplayName: String)
    func onAnsweredCall(sessionId: CLong)
    func onCloseCall(sessionId: CLong)
    func onMuteCall(sessionId: CLong, muted: Bool)
    func onHoldCall(sessionId: CLong, onHold: Bool)

    func onNewOutgoingCall(sessionid: CLong)
}

class CallManager: NSObject {
    weak var delegate: CallManagerDelegate?

    var _enableCallKit: Bool = false
    var enableCallKit: Bool {
        set {
            if _enableCallKit != newValue {
                _enableCallKit = newValue
                _portSIPSDK.enableCallKit(_enableCallKit)
            }
        }
        get {
            return _enableCallKit
        }
    }

    var isConference: Bool = false
    var _playDTMFTone: Bool = true

    var sessionArray: [Session] = []
    var _portSIPSDK: PortSIPSDK!
    var _playDTMFMethod: DTMF_METHOD!
    var _conferenceGroupID: UUID!

    init(portsipSdk: PortSIPSDK) {
        _portSIPSDK = portsipSdk

        _playDTMFTone = true
        _playDTMFMethod = DTMF_RFC2833
        _conferenceGroupID = nil

        for _ in 0 ..< MAX_LINES {
            sessionArray.append(Session())
        }

        if #available(iOS 10.0, *) {
            _enableCallKit = true
        } else {
            _enableCallKit = false
        }
        // Force disable CallKit
        // _enableCallKit = false

        _portSIPSDK.enableCallKit(_enableCallKit)
    }

    func setPlayDTMFMethod(dtmfMethod: DTMF_METHOD, playDTMFTone: Bool) {
        _playDTMFTone = playDTMFTone
        _playDTMFMethod = dtmfMethod
    }

    func reportUpdateCall(uuid: UUID, hasVideo: Bool, from: String) {
        guard findCallByUUID(uuid: uuid) != nil else {
            return
        }
        if #available(iOS 10.0, *) {
            let handle = CXHandle(type: .generic, value: from)
            let update = CXCallUpdate()
            update.remoteHandle = handle
            update.hasVideo = hasVideo
            update.supportsGrouping = true
            update.supportsDTMF = true
            update.supportsUngrouping = true
            update.localizedCallerName = from

            PortCxProvider.shareInstance.cxprovider.reportCall(with: uuid, updated: update)
        }
    }

    func reportOutgoingCall(number: String, uuid: UUID, video: Bool = false) {
        if #available(iOS 10.0, *) {
            let handle = CXHandle(type: .generic, value: number)

            let startCallAction = CXStartCallAction(call: uuid, handle: handle)

            startCallAction.isVideo = video

            let transaction = CXTransaction()
            transaction.addAction(startCallAction)
            let callController = CXCallController()
            callController.request(transaction) { error in
                if let err = error {
                    print("Error requesting transaction: \(err)")
                } else {
                    print("Requested transaction successfully")
                }
            }
        }
    }

    @available(iOS 10.0, *)
    func reportInComingCall(uuid: UUID, hasVideo: Bool, from: String, completion: ((Error?) -> Void)? = nil) {
        guard findCallByUUID(uuid: uuid) != nil else {
            return
        }

        let handle = CXHandle(type: .generic, value: from)
        let update = CXCallUpdate()
        update.remoteHandle = handle
        update.hasVideo = hasVideo
        update.supportsGrouping = true
        update.supportsDTMF = true
        update.supportsUngrouping = true

        PortCxProvider.shareInstance.cxprovider.reportNewIncomingCall(with: uuid, update: update, completion: { error in
            print("ErrorCode: \(String(describing: error))")
            completion?(error)
        })
    }

    func reportAnswerCall(uuid: UUID) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        if #available(iOS 10.0, *) {
            let answerAction = CXAnswerCallAction(call: result.session.uuid)

            let transaction = CXTransaction()
            transaction.addAction(answerAction)
            let callController = CXCallController()
            callController.request(transaction) { error in
                if let error = error {
                    print("Error requesting transaction: \(error)")
                } else {
                    print("Requested transaction successfully")
                }
            }
        }
    }

    func reportEndCall(uuid: UUID) {
        if #available(iOS 10.0, *) {
            guard let result = findCallByUUID(uuid: uuid) else {
                return
            }
            let sesion = result.session as Session
            let endCallAction = CXEndCallAction(call: sesion.uuid)
            let transaction = CXTransaction()
            transaction.addAction(endCallAction)
            let callController = CXCallController()
            callController.request(transaction) { error in
                if let error = error {
                    print("Error requesting transaction: \(error)")
                } else {
                    print("Requested transaction successfully")
                }
            }
        }
    }

    func reportSetHeld(uuid: UUID, onHold: Bool) {
        print("reportSetHeld transaction successfully")
        if #available(iOS 10.0, *) {
            guard let result = findCallByUUID(uuid: uuid) else {
                return
            }

            let setHeldCallAction = CXSetHeldCallAction(call: result.session.uuid, onHold: onHold)
            let transaction = CXTransaction()
            transaction.addAction(setHeldCallAction)
            let callController = CXCallController()
            callController.request(transaction) { error in
                if let error = error {
                    print("Error requesting transaction: \(error)")
                } else {
                    print("Requested transaction successfully")
                }
            }
        }
    }

    func reportSetMute(uuid: UUID, muted: Bool) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }

        if result.session.sessionState {
            if #available(iOS 10.0, *) {
                let setMutedCallAction = CXSetMutedCallAction(call: result.session.uuid, muted: muted)
                let transaction = CXTransaction()
                transaction.addAction(setMutedCallAction)
                let callController = CXCallController()
                callController.request(transaction) { error in
                    if let error = error {
                        print("Error requesting transaction: \(error)")
                    } else {
                        print("Requested transaction successfully")
                    }
                }
            }
        }
    }

    func reportJoninConference(uuid: UUID) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        if #available(iOS 10.0, *) {
            let setGroupCallAction = CXSetGroupCallAction(call: result.session.uuid, callUUIDToGroupWith: _conferenceGroupID)
            let transaction = CXTransaction()
            transaction.addAction(setGroupCallAction)
            let callController = CXCallController()
            callController.request(transaction) { error in
                if let error = error {
                    print("Error requesting transaction: \(error)")
                } else {
                    print("Requested transaction successfully")
                }
            }
        }
    }

    func reportRemoveFromConference(uuid: UUID) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        if #available(iOS 10.0, *) {
            let setGroupCallAction = CXSetGroupCallAction(call: result.session.uuid, callUUIDToGroupWith: nil)
            let transaction = CXTransaction()
            transaction.addAction(setGroupCallAction)
            let callController = CXCallController()
            callController.request(transaction) { error in
                if let error = error {
                    print("Error requesting transaction: \(error)")
                } else {
                    print("Requested transaction successfully")
                }
            }
        }
    }

    func reportPlayDtmf(uuid: UUID, tone: Int) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        var digits: String
        if tone == 10 {
            digits = "*"
        } else if tone == 11 {
            digits = "#"
        } else {
            digits = String(tone)
        }
        if #available(iOS 10.0, *) {
            let dtmfCallAction = CXPlayDTMFCallAction(call: result.session.uuid, digits: digits, type: .singleTone)
            let transaction = CXTransaction()
            transaction.addAction(dtmfCallAction)
            let callController = CXCallController()
            callController.request(transaction) { error in
                if let error = error {
                    print("Error requesting transaction: \(error)")
                } else {
                    print("Requested transaction successfully")
                }
            }
        }
    }

    //    Call Manager interface
    func makeCall(callee: String, displayName: String, videoCall: Bool) -> (CLong) {
        let num = getConnectCallNum()
        if num > MAX_LINES {
            return (CLong)(INVALID_SESSION_ID)
        }

        let sessionid = makeCallWithUUID(callee: callee, displayName: displayName, videoCall: videoCall, uuid: UUID())
        let result = findCallBySessionID(sessionid)

        if result != nil, _enableCallKit {
            reportOutgoingCall(number: callee, uuid: result!.sessiona.uuid, video: videoCall)
            print("reportOutgoingCall uuid = \(result!.sessiona.uuid))")
        }
        return sessionid
    }

    func incomingCall(sessionid: CLong, existsVideo: Bool, remoteParty: String, remoteDisplayName: String, callUUID: UUID, completionHandle _: () -> Void) {
        var session: Session
        let result = findCallByUUID(uuid: callUUID)
        if result != nil {
            session = result!.session
            session.sessionId = sessionid
            session.videoState = existsVideo
            if session.callKitAnswered {
                let bRet = answerCallWithUUID(uuid: session.uuid, isVideo: existsVideo)
                session.callKitCompletionCallback?(bRet)
                reportUpdateCall(uuid: session.uuid, hasVideo: existsVideo, from: remoteParty)
            }
        } else {
            session = Session()
            session.sessionId = sessionid
            session.videoState = existsVideo
            session.uuid = callUUID

            _ = addCall(call: session)

            if _enableCallKit {
                if #available(iOS 10.0, *) {
                    reportInComingCall(uuid: session.uuid, hasVideo: existsVideo, from: remoteParty)
                }
            } else {
                delegate?.onIncomingCallWithoutCallKit(sessionid, existsVideo: existsVideo, remoteParty: remoteParty, remoteDisplayName: remoteDisplayName)
            }
        }
    }

    func answerCall(sessionId: CLong, isVideo: Bool) -> (Bool) {
        guard let result = findCallBySessionID(sessionId) else {
            return false
        }
        if _enableCallKit {
            result.sessiona.videoState = isVideo
            reportAnswerCall(uuid: result.sessiona.uuid)
            return true
        } else {
            return answerCallWithUUID(uuid: result.sessiona.uuid, isVideo: isVideo)
        }
    }

    func endCall(sessionid: CLong) {
        guard let result = findCallBySessionID(sessionid) else {
            return
        }
        if _enableCallKit {
            let sesion = result.sessiona as Session
            reportEndCall(uuid: sesion.uuid)
        } else {
            hungUpCall(uuid: result.sessiona.uuid)
        }
    }

    func holdCall(sessionid: CLong, onHold: Bool) {
        guard let result = findCallBySessionID(sessionid) else {
            return
        }
        if !result.sessiona.sessionState || result.sessiona.holdState == onHold {
            return
        }
        holdCall(uuid: result.sessiona.uuid, onHold: onHold)
    }

    func holdAllCall(onHold: Bool) {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd,
                sessionArray[i].sessionState,
                sessionArray[i].holdState != onHold {
                holdCall(sessionid: sessionArray[i].sessionId, onHold: onHold)
            }
        }
    }

    func muteCall(sessionid: CLong, muted: Bool) {
        guard let result = findCallBySessionID(sessionid) else {
            return
        }
        if !result.sessiona.sessionState {
            return
        }
        if _enableCallKit {
            reportSetMute(uuid: result.sessiona.uuid, muted: muted)
        } else {
            muteCall(muted, uuid: result.sessiona.uuid)
        }
    }

    func muteAllCall(muted: Bool) {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd,
                sessionArray[i].sessionState {
                muteCall(sessionid: sessionArray[i].sessionId, muted: muted)
            }
        }
    }

    func playDtmf(sessionid: CLong, tone: Int) {
        guard let result = findCallBySessionID(sessionid) else {
            return
        }

        if !result.sessiona.sessionState {
            return
        }
        sendDTMF(uuid: result.sessiona.uuid, dtmf: Int32(tone))
    }

    func createConference(conferenceVideoWindow: PortSIPVideoRenderView?, videoWidth: Int, videoHeight: Int, displayLocalVideoInConference: Bool) -> (Bool) {
        if isConference {
            return false
        }
        var ret = 0
        if conferenceVideoWindow != nil, videoWidth > 0, videoHeight > 0 {
            ret = Int(_portSIPSDK.createVideoConference(conferenceVideoWindow, videoWidth: Int32(videoWidth), videoHeight: Int32(videoHeight), displayLocalVideo: displayLocalVideoInConference))
        } else {
            ret = Int(_portSIPSDK.createAudioConference())
        }

        if ret != 0 {
            isConference = false
            return false
        }

        isConference = true
        _conferenceGroupID = UUID()

        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd {
                _portSIPSDK.setRemoteVideoWindow(sessionArray[i].sessionId, remoteVideoWindow: nil)
                joinToConference(sessionid: sessionArray[i].sessionId)
            }
        }
        return true
    }

    func joinToConference(sessionid: CLong) {
        guard let result = findCallBySessionID(sessionid) else {
            return
        }
        if !result.sessiona.sessionState || !isConference {
            return
        }

        joinToConference(uuid: result.sessiona.uuid)

        if _enableCallKit {
            reportJoninConference(uuid: result.sessiona.uuid)
        }
    }

    func removeFromConference(sessionid: CLong) {
        guard let result = findCallBySessionID(sessionid) else {
            return
        }

        if !isConference {
            return
        }

        if _enableCallKit {
            reportRemoveFromConference(uuid: result.sessiona.uuid)
        } else {
            removeFromConference(uuid: result.sessiona.uuid)
        }
    }

    func destoryConference() {
        if isConference {
            for i in 0 ..< MAX_LINES {
                if sessionArray[i].hasAdd {
                    removeFromConference(sessionid: sessionArray[i].sessionId)
                }
            }
        }
        _portSIPSDK.destroyConference()
        _conferenceGroupID = nil
        isConference = false
        print("DestoryConference")
    }

    //    Call Manager implementation

    func makeCallWithUUID(callee: String, displayName: String?, videoCall: Bool, uuid: UUID) -> (CLong) {
        let result = findCallByUUID(uuid: uuid)
        if result != nil {
            return result!.session.sessionId
        }
        let num = getConnectCallNum()
        if num >= MAX_LINES {
            return (CLong)(INVALID_SESSION_ID)
        }
        let sessionid = _portSIPSDK.call(callee, sendSdp: true, videoCall: videoCall)

        if sessionid <= 0 {
            return sessionid
        }
        if displayName == nil {
            //            displayName = callee
        }
        let session = Session()
        session.uuid = uuid
        session.sessionId = sessionid
        session.originCallSessionId = -1
        session.videoState = videoCall
        session.outgoing = true

        _ = addCall(call: session)
        delegate?.onNewOutgoingCall(sessionid: sessionid)
        return session.sessionId
    }

    func answerCallWithUUID(uuid: UUID, isVideo: Bool) -> (Bool) {
        let sessionCall = findCallByUUID(uuid: uuid)
        guard sessionCall != nil else {
            return false
        }

        if sessionCall!.session.sessionId <= INVALID_SESSION_ID {
            // Haven't received INVITE CALL
            sessionCall!.session.callKitAnswered = true
            return true
        } else {
            let nRet = _portSIPSDK.answerCall(sessionCall!.session.sessionId, videoCall: isVideo)
            if nRet == 0 {
                sessionCall!.session.sessionState = true
                sessionCall!.session.videoState = isVideo

                if isConference {
                    joinToConference(sessionid: sessionCall!.session.sessionId)
                }
                delegate?.onAnsweredCall(sessionId: sessionCall!.session.sessionId)

                print("Answer Call on session \(sessionCall!.session.sessionId)")
                return true
            } else {
                delegate?.onCloseCall(sessionId: sessionCall!.session.sessionId)

                print("Answer Call on session \(sessionCall!.session.sessionId) Failed! ret = \(nRet)")
                return false
            }
        }
    }

    func hungUpCall(uuid: UUID) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        if isConference {
            removeFromConference(sessionid: result.session.sessionId)
        }

        if result.session.sessionState {
            _portSIPSDK.hangUp(result.session.sessionId)
            if result.session.videoState {}
            print("Hungup call on session \(result.session.sessionId)")
        } else if result.session.outgoing {
            _portSIPSDK.hangUp(result.session.sessionId)
            print("Invite call Failure on session \(result.session.sessionId)")
        } else {
            _portSIPSDK.rejectCall(result.session.sessionId, code: 486)
            print("Rejected call on session \(result.session.sessionId)")
        }

        delegate?.onCloseCall(sessionId: result.session.sessionId)
    }

    func holdCall(uuid: UUID, onHold: Bool) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        if !result.session.sessionState ||
            result.session.holdState == onHold {
            return
        }

        if onHold {
            _portSIPSDK.hold(result.session.sessionId)
            result.session.holdState = true
            print("Hold call on session: \(result.session.sessionId)")
        } else {
            _portSIPSDK.unHold(result.session.sessionId)
            result.session.holdState = false
            print("UnHold call on session: \(result.session.sessionId)")
        }
        delegate?.onHoldCall(sessionId: result.session.sessionId, onHold: onHold)
    }

    public func muteCall(_ mute: Bool, uuid: UUID) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        if result.session.sessionState {
            if mute {
                _portSIPSDK.muteSession(result.session.sessionId,
                                        muteIncomingAudio: false,
                                        muteOutgoingAudio: true,
                                        muteIncomingVideo: false,
                                        muteOutgoingVideo: true)
            } else {
                _portSIPSDK.muteSession(result.session.sessionId,
                                        muteIncomingAudio: false,
                                        muteOutgoingAudio: false,
                                        muteIncomingVideo: false,
                                        muteOutgoingVideo: false)
            }
            delegate?.onMuteCall(sessionId: result.session.sessionId, muted: mute)
        }
    }

    public func sendDTMF(uuid: UUID, dtmf: Int32) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }

        if result.session.sessionState {
            _portSIPSDK.sendDtmf(result.session.sessionId, dtmfMethod: _playDTMFMethod, code: dtmf, dtmfDration: 160, playDtmfTone: _playDTMFTone)
        }
    }

    public func joinToConference(uuid: UUID) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }
        if isConference {
            if result.session.sessionState {
                if result.session.holdState {
                    holdCall(sessionid: result.session.sessionId, onHold: false)

                    result.session.holdState = false
                }
                _portSIPSDK.join(toConference: result.session.sessionId)
            }
        }
    }

    public func removeFromConference(uuid: UUID) {
        guard let result = findCallByUUID(uuid: uuid) else {
            return
        }

        if isConference {
            _portSIPSDK.remove(fromConference: result.session.sessionId)
        }
    }

    public func findCallBySessionID(_ sessionID: CLong) -> (sessiona: Session, index: Int)? {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd,
                sessionArray[i].sessionId == sessionID {
                return (sessionArray[i], i)
            }
        }
        return nil
    }

    public func findAnotherCall(_ sessionID: CLong) -> (session: Session, index: Int)? {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd,
                sessionArray[i].sessionId != sessionID {
                return (sessionArray[i], i)
            }
        }
        return nil
    }

    public func findCallByOrignalSessionID(sessionID: CLong) -> (session: Session, index: Int)? {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd,
                sessionArray[i].originCallSessionId == sessionID {
                return (sessionArray[i], i)
            }
        }
        return nil
    }

    public func findCallByUUID(uuid: UUID) -> (session: Session, index: Int)? {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].uuid == uuid {
                return (sessionArray[i], i)
            }
        }
        return nil
    }

    public func addCall(call: Session) -> (Int) {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd == false {
                sessionArray[i] = call
                sessionArray[i].hasAdd = true
                return i
            }
        }
        return -1
    }

    public func removeCall(call: Session) {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i] === call {
                sessionArray[i].reset()
            }
        }
    }

    public func clear() {
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd {
                _portSIPSDK.hangUp(sessionArray[i].sessionId)
                sessionArray[i].reset()
            }
        }
    }

    public func getConnectCallNum() -> Int {
        var num: Int = 0
        for i in 0 ..< MAX_LINES {
            if sessionArray[i].hasAdd {
                num += 1
            }
        }
        return num
    }

    func startAudio() {
        _portSIPSDK.startAudio()
        print("_portSIPSDK startAudio")
    }

    func stopAudio() {
        _portSIPSDK.stopAudio()
        print("_portSIPSDK stopAudio")
    }
}

// Audio Controller
