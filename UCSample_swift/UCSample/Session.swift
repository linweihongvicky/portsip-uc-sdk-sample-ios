//
//  Session.m
//  UCSample
//
//  Created by Joe Lepple on 5/1/15.
//  Copyright (c) 2015 PortSIP Solutions, Inc. All rights reserved.
//

let LINE_BASE = 0
let MAX_LINES = 8

class Session {
    var sessionId: Int
    var holdState: Bool
    var sessionState: Bool
    var conferenceState: Bool
    var recvCallState: Bool
    var isReferCall: Bool
    var originCallSessionId: Int
    var existEarlyMedia: Bool
    var videoState: Bool
    var uuid: UUID
    var groupUUID: UUID?
    var status: String
    var outgoing: Bool
    var callKitAnswered: Bool
    var callKitCompletionCallback: ((Bool) -> Void)?
    var hasAdd: Bool

    init() {
        sessionId = Int(INVALID_SESSION_ID)
        holdState = false
        sessionState = false
        conferenceState = false
        recvCallState = false
        isReferCall = false
        originCallSessionId = Int(INVALID_SESSION_ID)
        existEarlyMedia = false
        videoState = false
        outgoing = false
        uuid = UUID()
        groupUUID = nil
        status = ""
        hasAdd = false
        callKitAnswered = false
        callKitCompletionCallback = nil
    }

    func reset() {
        sessionId = Int(INVALID_SESSION_ID)
        holdState = false
        sessionState = false
        conferenceState = false
        recvCallState = false
        isReferCall = false
        originCallSessionId = Int(INVALID_SESSION_ID)
        existEarlyMedia = false
        videoState = false
        outgoing = false
        uuid = UUID()
        groupUUID = nil
        status = ""

        hasAdd = false
        callKitAnswered = false
        callKitCompletionCallback = nil
    }
}
