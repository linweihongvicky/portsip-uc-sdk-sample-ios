//
//  AppDelegate.swift
//  UCSample
//
//  Created by portsip on 16/7/19.
//  Copyright © 2016 portsip. All rights reserved.
//

import PushKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, PKPushRegistryDelegate, UIApplicationDelegate, UNUserNotificationCenterDelegate, CallManagerDelegate, LineViewControllerDelegate, PortSIPEventDelegate {
    var window: UIWindow?
    var sipRegistered: Bool!
    var portSIPSDK: PortSIPSDK!
    var mSoundService: SoundService!
    var internetReach: Reachability!
    var _callManager: CallManager!

    var sipURL: String?
    var isConference: Bool!
    var conferenceId: Int32!
    var loginViewController: LoginViewController!
    var numpadViewController: NumpadViewController!
    var videoViewController: VideoViewController!
    var imViewController: IMViewController!
    var settingsViewController: SettingsViewController!

    var _activeLine: Int!
    var activeSessionid: CLong!
    var lineSessions: [CLong] = []

    var _VoIPPushToken: NSString!
    var _APNsPushToken: NSString!
    var _backtaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    var _enablePushNotification: Bool?

    var _enableForceBackground: Bool?

    func findSession(sessionid: CLong) -> (Int) {
        for i in 0 ..< MAX_LINES {
            if lineSessions[i] == sessionid {
                return i
            }
        }
        print("Can't find session, Not exist this SessionId = \(sessionid)")
        return -1
    }

    func findIdleLine() -> (Int) {
        for i in 0 ..< MAX_LINES {
            if lineSessions[i] == CLong(INVALID_SESSION_ID) {
                return i
            }
        }
        print("No idle line available. All lines are in use.")
        return -1
    }

    func freeLine(sessionid: CLong) {
        for i in 0 ..< MAX_LINES {
            if lineSessions[i] == sessionid {
                lineSessions[i] = CLong(INVALID_SESSION_ID)
                return
            }
        }
        print("Can't Free Line, Not exist this SessionId = \(sessionid)")
    }
    func showAlertView(_ title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(ok)

        let tabBarController = window?.rootViewController as! UITabBarController

        tabBarController.present(alertController, animated: true)
    }
    
    // --

    // MARK: - APNs message PUSH

    @available(iOS 10.0, *) // foreground
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Foreground Notification:\(userInfo)")
        completionHandler([.sound, .alert])
    }

    @available(iOS 10.0, *) // Background
    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Background Notification:\(userInfo)")
        completionHandler()
    }

    // 8.0 < iOS < 10.0
    private func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject: AnyObject], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if application.applicationState == UIApplication.State.active {
            print("Foreground Notification:\(userInfo)")
        } else {
            print("Background Notification:\(userInfo)")
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        completionHandler(.newData)
    }

    // MARK: - VoIP PUSH

    func addPushSupportWithPortPBX(_ enablePush: Bool) {
        if _VoIPPushToken == nil || _APNsPushToken == nil {
            return
        }
        // This VoIP Push is only work with PortPBX(https://www.portsip.com/portsip-pbx/)
        // if you want work with other PBX, please contact your PBX Provider

        let bundleIdentifier: String = Bundle.main.bundleIdentifier!
        portSIPSDK.clearAddedSipMessageHeaders()
        let token = NSString(format: "%@|%@", _VoIPPushToken, _APNsPushToken)
        if enablePush {
            let pushMessage: String = NSString(format: "device-os=ios;device-uid=%@;allow-call-push=true;allow-message-push=true;app-id=%@", token, bundleIdentifier) as String

            print("Enable pushMessage:{\(pushMessage)}")

            portSIPSDK.addSipMessageHeader(-1, methodName: "REGISTER", msgType: 1, headerName: "x-p-push", headerValue: pushMessage)
        } else {
            let pushMessage: String = NSString(format: "device-os=ios;device-uid=%@;allow-call-push=false;allow-message-push=false;app-id=%@", token, bundleIdentifier) as String

            print("Disable pushMessage:{\(pushMessage)}")

            portSIPSDK.addSipMessageHeader(-1, methodName: "REGISTER", msgType: 1, headerName: "x-p-push", headerValue: pushMessage)
        }
    }

    func updatePushStatusToSipServer() {
        // This VoIP Push is only work with
        // PortPBX(https://www.portsip.com/portsip-pbx/)
        // if you want work with other PBX, please contact your PBX Provider

        addPushSupportWithPortPBX(_enablePushNotification!)
        loginViewController.refreshRegister()
    }

    func processPushMessageFromPortPBX(_ dictionaryPayload: [AnyHashable: Any], completion: () -> Void) {
        /* dictionaryPayload JSON Format
         Payload: {
         "message_id" = "96854b5d-9d0b-4644-af6d-8d97798d9c5b";
         "msg_content" = "Received a call.";
         "msg_title" = "Received a new call";
         "msg_type" = "call";// im message is "im"
         "x-push-id" = "pvqxCpo-j485AYo9J1cP5A..";
         "send_from" = "102";
         "send_to" = "sip:105@portsip.com";
         }
         */

        let parsedObject = dictionaryPayload
        var isVideoCall = false
        let msgType = parsedObject["msg_type"] as? String
        if (msgType?.count ?? 0) > 0 {
            if msgType == "video" {
                isVideoCall = true
            } else if msgType == "aduio" {
                isVideoCall = false
            }
        }

        var uuid: UUID?
        let pushId = dictionaryPayload["x-push-id"]

        if pushId != nil {
            let uuidStr = pushId as! String
            uuid = UUID(uuidString: uuidStr)
        }
        if uuid == nil {
            return
        }

        let sendFrom = parsedObject["send_from"]
        let sendTo = parsedObject["send_to"]

        if !_callManager.enableCallKit {
            // If not enable Call Kit, show the local Notification
            let backgroudMsg = UILocalNotification()
            let alertBody = "You receive a new call From:\(String(describing: sendFrom)) To:\(String(describing: sendTo))"
            backgroudMsg.alertBody = alertBody
            backgroudMsg.soundName = "ringtone.mp3"
            backgroudMsg.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
            UIApplication.shared.presentLocalNotificationNow(backgroudMsg)
        } else {
            _callManager.incomingCall(sessionid: -1, existsVideo: isVideoCall, remoteParty: sendFrom as! String,
                                      remoteDisplayName: sendFrom as! String, callUUID: uuid!, completionHandle: completion)
            loginViewController.refreshRegister()
            beginBackgroundRegister()
        }
    }

    func pushRegistry(_: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for _: PKPushType) {
        var deviceTokenString = String()
        let bytes = [UInt8](pushCredentials.token)
        for item in bytes {
            deviceTokenString += String(format: "%02x", item & 0x0000_00FF)
        }

        _VoIPPushToken = NSString(string: deviceTokenString)

        print("didUpdatePushCredentials token=", deviceTokenString)

        updatePushStatusToSipServer()
    }

    func pushRegistry(_: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for _: PKPushType) {
        print("didReceiveIncomingPushWith:payload=", payload.dictionaryPayload)
        if sipRegistered,
            UIApplication.shared.applicationState == .active || _callManager.getConnectCallNum() > 0 { // ignore push message when app is active
            print("didReceiveIncomingPushWith:ignore push message when ApplicationStateActive or have active call. ")

            return
        }

        processPushMessageFromPortPBX(payload.dictionaryPayload, completion: {})
    }

    func pushRegistry(_: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for _: PKPushType, completion: @escaping () -> Void) {
        print("didReceiveIncomingPushWith:payload=", payload.dictionaryPayload)
        if sipRegistered,
            UIApplication.shared.applicationState == .active || _callManager.getConnectCallNum() > 0 { // ignore push message when app is active
            print("didReceiveIncomingPushWith:ignore push message when ApplicationStateActive or have active call. ")

            return
        }

        processPushMessageFromPortPBX(payload.dictionaryPayload, completion: completion)
    }

    func beginBackgroundRegister() {
        _backtaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundRegister()

        })

        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { _ in

                self.endBackgroundRegister()
            })
        } else {
            // Fallback on earlier versions

            //          Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(endBackgroundRegister), userInfo: nil, repeats: true)
        }
    }

    func endBackgroundRegister() {
        if _backtaskIdentifier != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(_backtaskIdentifier)
            _backtaskIdentifier = UIBackgroundTaskIdentifier.invalid
            NSLog("endBackgroundRegister")
        }
    }
    
    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UserDefaults.standard.register(defaults: ["CallKit": true])
        UserDefaults.standard.register(defaults: ["PushNotification": true])
        UserDefaults.standard.register(defaults: ["ForceBackground": false])

        let enableCallKit = UserDefaults.standard.bool(forKey: "CallKit")
        _enablePushNotification = UserDefaults.standard.bool(forKey: "PushNotification")
        _enableForceBackground = UserDefaults.standard.bool(forKey: "ForceBackground")

        portSIPSDK = PortSIPSDK()
        portSIPSDK.delegate = self
        mSoundService = SoundService()

        if #available(iOS 10.0, *) {
            let cxProvider = PortCxProvider.shareInstance
            _callManager = CallManager(portsipSdk: portSIPSDK)
            _callManager.delegate = self
            _callManager.enableCallKit = enableCallKit
            cxProvider.callManager = _callManager
        } else {
            // Fallback on earlier versions
        }

        _activeLine = 0
        activeSessionid = CLong(INVALID_SESSION_ID)
        for _ in 0 ..< MAX_LINES {
            lineSessions.append(CLong(INVALID_SESSION_ID))
        }

        sipRegistered = false
        isConference = false

        let tabBarController = window?.rootViewController as! UITabBarController

        let loginBase = tabBarController.viewControllers![0] as! UINavigationController

        loginViewController = loginBase.viewControllers[0] as? LoginViewController
        numpadViewController = tabBarController.viewControllers![1] as? NumpadViewController
        videoViewController = tabBarController.viewControllers![2] as? VideoViewController
        imViewController = tabBarController.viewControllers![3] as? IMViewController
        settingsViewController = tabBarController.viewControllers![4] as? SettingsViewController

        loginViewController.portSIPSDK = portSIPSDK

        videoViewController.portSIPSDK = portSIPSDK
        imViewController.portSIPSDK = portSIPSDK
        settingsViewController.portSIPSDK = portSIPSDK

        internetReach = Reachability.forInternetConnection()
        startNotifierNetwork()

        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        // voip push
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]

        // im push
        if #available(iOS 10.0, *) {
            let notifiCenter = UNUserNotificationCenter.current()
            notifiCenter.delegate = self
            notifiCenter.requestAuthorization(options: [.alert, .sound, .badge]) { accepted, _ in

                if !accepted {
                    print("Permission granted: \(accepted)")
                }
            }

            UIApplication.shared.registerForRemoteNotifications()
            // 8.0<ios<10
        } else if #available(iOS 8.0, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: UIUserNotificationType(rawValue: UIUserNotificationType.alert.rawValue | UIUserNotificationType.sound.rawValue | UIUserNotificationType.badge.rawValue), categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            let type = UIRemoteNotificationType(rawValue: UIRemoteNotificationType.alert.rawValue | UIRemoteNotificationType.badge.rawValue | UIRemoteNotificationType.sound.rawValue)
            UIApplication.shared.registerForRemoteNotifications(matching: type)
        }

        let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)

        application.registerUserNotificationSettings(notificationSettings)

        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var deviceTokenString = String()
        let bytes = [UInt8](deviceToken)
        for item in bytes {
            deviceTokenString += String(format: "%02x", item & 0x0000_00FF)
        }

        _APNsPushToken = NSString(string: deviceTokenString)
        updatePushStatusToSipServer()
    }

    private func registerAppNotificationSettings(launchOptions _: [UIApplication.LaunchOptionsKey: Any]?) {}

    @objc func reachabilityChanged(_: Notification) {
        let netStatus = internetReach.currentReachabilityStatus()
        if loginViewController.sipRegistered {
            switch netStatus {
            case NotReachable:
                NSLog("reachabilityChanged:kNotReachable")
            case ReachableViaWWAN:
                loginViewController.refreshRegister()
                NSLog("reachabilityChanged:kReachableViaWWAN")
            case ReachableViaWiFi:
                loginViewController.refreshRegister()
                NSLog("reachabilityChanged:kReachableViaWiFi")
            default:
                break
            }
        }
    }

    func startNotifierNetwork() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: NSNotification.Name.reachabilityChanged, object: nil)

        internetReach.startNotifier()
    }

    func stopNotifierNetwork() {
        internetReach.stopNotifier()

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.reachabilityChanged, object: nil)
    }

    // MARK: - UIApplicationDelegate

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        NSLog("applicationDidEnterBackground")
        if _enableForceBackground! {
            // Disable to save battery, or when you don't need incoming calls while APP is in background.
            portSIPSDK.startKeepAwake()
        } else {
            loginViewController.unRegister()

            beginBackgroundRegister()
        }
        NSLog("applicationDidEnterBackground End")
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if _enableForceBackground! {
            portSIPSDK.stopKeepAwake()
        } else {
            loginViewController.refreshRegister()
        }
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        if _enablePushNotification! {
            portSIPSDK.unRegisterServer()

            Thread.sleep(forTimeInterval: 1.0)

            print("applicationWillTerminate")
        }
    }

    // PortSIPEventDelegate

    func onRegisterSuccess(_ statusText: UnsafeMutablePointer<Int8>!, statusCode: Int32, sipMessage _: UnsafeMutablePointer<Int8>!) {
        sipRegistered = true
        loginViewController.onRegisterSuccess(statusCode, withStatusText: String(validatingUTF8: statusText)!)
        NSLog("onRegisterSuccess")
    }

    func onRegisterFailure(_ statusText: UnsafeMutablePointer<Int8>!, statusCode: Int32, sipMessage _: UnsafeMutablePointer<Int8>!) {
        sipRegistered = false
        loginViewController.onRegisterFailure(statusCode, withStatusText: String(validatingUTF8: statusText)!)
        NSLog("onRegisterFailure")
    }

    // Call Event
    func onInviteIncoming(_ sessionId: Int, callerDisplayName: UnsafeMutablePointer<Int8>!, caller: UnsafeMutablePointer<Int8>!, calleeDisplayName _: UnsafeMutablePointer<Int8>!, callee _: UnsafeMutablePointer<Int8>!, audioCodecs _: UnsafeMutablePointer<Int8>!, videoCodecs _: UnsafeMutablePointer<Int8>!, existsAudio _: Bool, existsVideo: Bool, sipMessage: UnsafeMutablePointer<Int8>!) {
        let num = _callManager.getConnectCallNum()
        let index = findIdleLine()
        if num >= MAX_LINES || index < 0 {
            portSIPSDK.rejectCall(sessionId, code: 486)
            return
        }
        let remoteParty = String(cString: caller, encoding: .ascii)
        let remoteDisplayName = String(cString: callerDisplayName, encoding: .ascii)

        var uuid: UUID?
        if _enablePushNotification! {
            let sipMessage = String(cString: sipMessage, encoding: .ascii)
            let pushId = portSIPSDK.getSipMessageHeaderValue(sipMessage, headerName: "x-push-id")
            if pushId != nil {
                uuid = UUID(uuidString: pushId!)
            }
        }
        if uuid == nil {
            uuid = UUID()
        }
        lineSessions[index] = sessionId

        _callManager.incomingCall(sessionid: sessionId, existsVideo: existsVideo, remoteParty: remoteParty!, remoteDisplayName: remoteDisplayName!, callUUID: uuid!, completionHandle: {})
        numpadViewController.setStatusText("Incoming call \(String(describing: remoteParty)) on line ")
    }

    func onInviteTrying(_ sessionId: Int) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Call is trying on line \(index)")
    }

    func onInviteSessionProgress(_ sessionId: Int, audioCodecs _: UnsafeMutablePointer<Int8>!, videoCodecs _: UnsafeMutablePointer<Int8>!, existsEarlyMedia: Bool, existsAudio: Bool, existsVideo: Bool, sipMessage _: UnsafeMutablePointer<Int8>!) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        if existsEarlyMedia {
            // Checking does this call has video
            if existsVideo {
                // This incoming call has video
                // If more than one codecs using, then they are separated with "#",
                // for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by yourself.
            }

            if existsAudio {
                // If more than one codecs using, then they are separated with "#",
                // for example: "g.729#GSM#AMR", "H264#H263", you have to parse them by yourself.
            }
        }

        let result = _callManager.findCallBySessionID(sessionId)

        result!.sessiona.existEarlyMedia = existsEarlyMedia

        numpadViewController.setStatusText("Call session progress on line \(index)")
    }

    func onInviteRinging(_ sessionId: Int, statusText _: UnsafeMutablePointer<Int8>!, statusCode _: Int32, sipMessage _: UnsafeMutablePointer<Int8>!) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }
        let result = _callManager.findCallBySessionID(sessionId)
        if !result!.sessiona.existEarlyMedia {
            _ = mSoundService.playRingBackTone()
        }
        numpadViewController.setStatusText("Call ringing on line \(index)")
    }

    func onInviteAnswered(_ sessionId: Int, callerDisplayName _: UnsafeMutablePointer<Int8>!, caller _: UnsafeMutablePointer<Int8>!, calleeDisplayName _: UnsafeMutablePointer<Int8>!, callee _: UnsafeMutablePointer<Int8>!, audioCodecs _: UnsafeMutablePointer<Int8>!, videoCodecs _: UnsafeMutablePointer<Int8>!, existsAudio: Bool, existsVideo: Bool, sipMessage _: UnsafeMutablePointer<Int8>!) {
        guard let result = _callManager.findCallBySessionID(sessionId) else {
            print("Not exist this SessionId = \(sessionId)")
            return
        }

        result.sessiona.sessionState = true
        result.sessiona.videoState = existsVideo

        if existsVideo {
            videoViewController.onStartVideo(sessionId)
        }

        if existsAudio {}

        numpadViewController.setStatusText("Call Established on line \(findSession(sessionid: sessionId))")

        if result.sessiona.isReferCall {
            result.sessiona.isReferCall = false
            result.sessiona.originCallSessionId = -1
        }

        if isConference == true {
            _callManager.joinToConference(sessionid: sessionId)
        }
        _ = mSoundService.stopRingBackTone()
    }

    func onInviteFailure(_ sessionId: Int, reason: UnsafeMutablePointer<Int8>!, code: Int32, sipMessage _: UnsafeMutablePointer<Int8>!) {
        guard let result = _callManager.findCallBySessionID(sessionId) else {
            return
        }

        let tempreaon = NSString(utf8String: reason)

        numpadViewController.setStatusText("Failed to call on line \(findSession(sessionid: sessionId)),\(tempreaon!),\(code)")

        if result.sessiona.isReferCall {
            let originSession = _callManager.findCallByOrignalSessionID(sessionID: result.sessiona.originCallSessionId)

            if originSession != nil {
                numpadViewController.setStatusText("Call failure on line \(findSession(sessionid: sessionId)) , \(String(describing: tempreaon)) , \(code)")

                portSIPSDK.unHold(originSession!.session.sessionId)
                originSession!.session.holdState = false

                _activeLine = findSession(sessionid: sessionId)
            }
        }

        if activeSessionid == sessionId {
            activeSessionid = CLong(INVALID_SESSION_ID)
        }
        _callManager.removeCall(call: result.sessiona)

        _ = mSoundService.stopRingTone()
        _ = mSoundService.stopRingBackTone()
        setLoudspeakerStatus(true)
    }

    func onInviteUpdated(_ sessionId: Int, audioCodecs _: UnsafeMutablePointer<Int8>!, videoCodecs _: UnsafeMutablePointer<Int8>!, existsAudio: Bool, existsVideo: Bool, sipMessage _: UnsafeMutablePointer<Int8>!) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        // Checking does this call has video
        if existsVideo {
            videoViewController.onStartVideo(sessionId)
        }
        if existsAudio {}

        numpadViewController.setStatusText("The call has been updated on line \(index)")
    }

    func onInviteConnected(_ sessionId: Int) {
        guard let result = _callManager.findCallBySessionID(sessionId) else {
            return
        }

        numpadViewController.setStatusText("The call is connected on line \(findSession(sessionid: sessionId))")
        if result.sessiona.videoState {
            setLoudspeakerStatus(true)
        } else {
            setLoudspeakerStatus(false)
        }
        NSLog("onInviteConnected...")
    }

    func onInviteBeginingForward(_ forwardTo: UnsafeMutablePointer<Int8>!) {
        let strForwardTo = String(validatingUTF8: forwardTo)
        numpadViewController.setStatusText("Call has been forward to:\(strForwardTo!)")
    }

    func onInviteClosed(_ sessionId: Int) {
        numpadViewController.setStatusText("Call closed by remote on line \(findSession(sessionid: sessionId))")
        let result = _callManager.findCallBySessionID(sessionId)
        if result != nil {
            _callManager.endCall(sessionid: sessionId)
        }
        _ = mSoundService.stopRingTone()
        _ = mSoundService.stopRingBackTone()
        // Setting speakers for sound output (The system default behavior)
        setLoudspeakerStatus(true)

        if activeSessionid == sessionId {
            activeSessionid = CLong(INVALID_SESSION_ID)
        }
        NSLog("onInviteClosed...")
    }

    func onDialogStateUpdated(_ BLFMonitoredUri: UnsafeMutablePointer<Int8>!, blfDialogState BLFDialogState: UnsafeMutablePointer<Int8>!, blfDialogId BLFDialogId: UnsafeMutablePointer<Int8>!, blfDialogDirection BLFDialogDirection: UnsafeMutablePointer<Int8>!) {
        NSLog("The user %s dialog state is updated:%s, dialog id: %s, direction: %s ",
              BLFMonitoredUri, BLFDialogState, BLFDialogId, BLFDialogDirection)
    }

    func onRemoteHold(_ sessionId: Int) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Placed on hold by remote on line \(index)")
    }

    func onRemoteUnHold(_ sessionId: Int, audioCodecs _: UnsafeMutablePointer<Int8>!, videoCodecs _: UnsafeMutablePointer<Int8>!, existsAudio _: Bool, existsVideo _: Bool) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Take off hold by remote on line  \(index)")
    }

    // Transfer Event

    func onReceivedRefer(_ sessionId: Int, referId: Int, to: UnsafeMutablePointer<Int8>!, from _: UnsafeMutablePointer<Int8>!, referSipMessage: UnsafeMutablePointer<Int8>!) {
        let strTo = String(validatingUTF8: to)
        // let strFrom = String.init(validatingUTF8:from);
        let strReferSipMessage = String(validatingUTF8: referSipMessage)

        guard _callManager.findCallBySessionID(sessionId) != nil else {
            portSIPSDK.rejectRefer(referId)
            return
        }

        let index = findIdleLine()
        if index < 0 {
            // Not found the idle line, reject refer.
            portSIPSDK.rejectRefer(referId)
            return
        }
        numpadViewController.setStatusText("Received the refer on line \(findSession(sessionid: sessionId)), refer to \(strTo!)")

        // auto accept refer
        let referSessionId = portSIPSDK.acceptRefer(referId, referSignaling: strReferSipMessage)
        if referSessionId <= 0 {
            numpadViewController.setStatusText("Failed to accept the refer.")
        } else {
            _callManager.endCall(sessionid: sessionId)

            _ = String(utf8String: to)
            let session = Session()
            session.sessionId = referSessionId
            session.videoState = true
            session.recvCallState = true

            let newIndex = _callManager.addCall(call: session)
            lineSessions[index] = referSessionId

            session.sessionState = true
            session.isReferCall = true
            session.originCallSessionId = sessionId

            numpadViewController.setStatusText("Accepted the refer, new call is trying on line \(newIndex)")
        }
        /* if you want to reject Refer
         [mPortSIPSDK rejectRefer:referId);
         [numpadViewController setStatusText("Rejected the the refer.");
         */
    }

    func onReferAccepted(_ sessionId: Int) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Line \(index), the REFER was accepted.")
    }

    func onReferRejected(_ sessionId: Int, reason _: UnsafeMutablePointer<Int8>!, code _: Int32) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Line \(index), the REFER was rejected.")
    }

    func onTransferTrying(_ sessionId: Int) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Transfer trying on line \(index)")
    }

    func onTransferRinging(_ sessionId: Int) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Transfer ringing on line \(index)")
    }

    func onACTVTransferSuccess(_ sessionId: Int) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Transfer succeeded on line \(index)")

        // Transfer has success, hangup call.
        portSIPSDK.hangUp(sessionId)
    }

    func onACTVTransferFailure(_ sessionId: Int, reason _: UnsafeMutablePointer<Int8>!, code _: Int32) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Failed to transfer on line \(index)")
    }

    // Signaling Event

    func onReceivedSignaling(_: Int, message _: UnsafeMutablePointer<Int8>!) {
        // This event will be fired when the SDK received a SIP message
        // you can use signaling to access the SIP message.
    }

    func onSendingSignaling(_: Int, message _: UnsafeMutablePointer<Int8>!) {
        // This event will be fired when the SDK sent a SIP message
        // you can use signaling to access the SIP message.
    }

    func onWaitingVoiceMessage(_ messageAccount: UnsafeMutablePointer<Int8>!, urgentNewMessageCount: Int32, urgentOldMessageCount: Int32, newMessageCount: Int32, oldMessageCount _: Int32) {
        let strMessageAccount = String(validatingUTF8: messageAccount)
        numpadViewController.setStatusText("Has voice messages,\(strMessageAccount!)(\(urgentNewMessageCount),\(urgentOldMessageCount),\(newMessageCount),\(newMessageCount))")
    }

    func onWaitingFaxMessage(_ messageAccount: UnsafeMutablePointer<Int8>!, urgentNewMessageCount: Int32, urgentOldMessageCount: Int32, newMessageCount: Int32, oldMessageCount _: Int32) {
        let strMessageAccount = String(validatingUTF8: messageAccount)
        numpadViewController.setStatusText("Has Fax messages,\(strMessageAccount!)(\(urgentNewMessageCount),\(urgentOldMessageCount),\(newMessageCount),\(newMessageCount))")
    }

    func onRecvDtmfTone(_ sessionId: Int, tone: Int32) {
        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Received DTMF tone: \(tone)  on line \(index)")
    }

    func onRecvOptions(_ optionsMessage: UnsafeMutablePointer<Int8>!) {
        let stroptionsMessage = String(validatingUTF8: optionsMessage)
        NSLog("Received an OPTIONS message:\(stroptionsMessage!)")
    }

    func onRecvInfo(_ infoMessage: UnsafeMutablePointer<Int8>!) {
        let strinfoMessage = String(validatingUTF8: infoMessage)
        NSLog("Received an INFO message:\(strinfoMessage!)")
    }

    func onRecvNotifyOfSubscription(_: Int, notifyMessage _: UnsafeMutablePointer<Int8>!, messageData _: UnsafeMutablePointer<UInt8>!, messageDataLength _: Int32) {
        NSLog("Received an Notify message")
    }

    // Instant Message/Presence Event

    func onPresenceRecvSubscribe(_ subscribeId: Int, fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, subject: UnsafeMutablePointer<Int8>!) {
        let strfromDisplayName = String(validatingUTF8: fromDisplayName)
        let strfrom = String(validatingUTF8: from)
        let strsubject = String(validatingUTF8: subject)

        _ = imViewController.onPresenceRecvSubscribe(subscribeId, fromDisplayName: strfromDisplayName!, from: strfrom!, subject: strsubject!)
    }

    func onPresenceOnline(_ fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, stateText: UnsafeMutablePointer<Int8>!) {
        let strfromDisplayName = String(validatingUTF8: fromDisplayName)
        let strfrom = String(validatingUTF8: from)
        let strstateText = String(validatingUTF8: stateText)

        imViewController.onPresenceOnline(strfromDisplayName!, from: strfrom!,
                                          stateText: strstateText!)
    }

    func onPresenceOffline(_ fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!) {
        let strfromDisplayName = String(validatingUTF8: fromDisplayName)
        let strfrom = String(validatingUTF8: from)

        imViewController.onPresenceOffline(strfromDisplayName!, from: strfrom!)
    }

    func onRecvMessage(_ sessionId: Int, mimeType: UnsafeMutablePointer<Int8>!, subMimeType: UnsafeMutablePointer<Int8>!, messageData: UnsafeMutablePointer<UInt8>!, messageDataLength _: Int32) {
        let strmimeType = String(validatingUTF8: mimeType)
        let strsubMimeType = String(validatingUTF8: subMimeType)

        let index = findSession(sessionid: sessionId)
        if index == -1 {
            return
        }

        numpadViewController.setStatusText("Received a MESSAGE message on line \(index)")

        if strmimeType == "text", strsubMimeType == "plain" {
            let recvMessage = String(cString: messageData)

            showAlertView("recvMessage", message: recvMessage)
        } else if strmimeType == "application", strsubMimeType == "vnd.3gpp.sms" {
            // The messageData is binary data
        } else if strmimeType == "application", strsubMimeType == "vnd.3gpp2.sms" {
            // The messageData is binary data
        }
    }

    func onRecvOutOfDialogMessage(_: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, toDisplayName _: UnsafeMutablePointer<Int8>!, to _: UnsafeMutablePointer<Int8>!, mimeType: UnsafeMutablePointer<Int8>!, subMimeType: UnsafeMutablePointer<Int8>!, messageData: UnsafeMutablePointer<UInt8>!, messageDataLength _: Int32,
                                  sipMessage _: UnsafeMutablePointer<Int8>!) {
        // let strFromDisplayName = String.init(validatingUTF8: mimeType);
        let strFrom = String(validatingUTF8: from)
        // let strToDisplayName = String.init(validatingUTF8: toDisplayName);
        // let strTo = String.init(validatingUTF8: to);

        let strMimeType = String(validatingUTF8: mimeType)
        let strSubMimeType = String(validatingUTF8: subMimeType)

        numpadViewController.setStatusText("Received a message(out of dialog) from \(strFrom!)")

        if strMimeType == "text", strSubMimeType == "plain" {
            let strMessageData = String(cString: messageData)
            showAlertView(strFrom!, message: strMessageData)
        } else if strMimeType == "application", strSubMimeType == "vnd.3gpp.sms" {
            // The messageData is binary data
        } else if strMimeType == "application", strSubMimeType == "vnd.3gpp2.sms" {
            // The messageData is binary data
        }
    }

    func onSendMessageSuccess(_: Int, messageId: Int) {
        imViewController.onSendMessageSuccess(messageId)
    }

    func onSendMessageFailure(_: Int, messageId: Int, reason: UnsafeMutablePointer<Int8>!, code: Int32) {
        let strreason = String(validatingUTF8: reason)
        imViewController.onSendMessageFailure(messageId, reason: strreason!, code: Int(code))
    }

    func onSendOutOfDialogMessageSuccess(_ messageId: Int, fromDisplayName _: UnsafeMutablePointer<Int8>!, from _: UnsafeMutablePointer<Int8>!, toDisplayName _: UnsafeMutablePointer<Int8>!, to _: UnsafeMutablePointer<Int8>!) {
        imViewController.onSendMessageSuccess(messageId)
    }

    func onSendOutOfDialogMessageFailure(_ messageId: Int, fromDisplayName _: UnsafeMutablePointer<Int8>!, from _: UnsafeMutablePointer<Int8>!, toDisplayName _: UnsafeMutablePointer<Int8>!, to _: UnsafeMutablePointer<Int8>!, reason: UnsafeMutablePointer<Int8>!, code: Int32) {
        let strreason = String(validatingUTF8: reason)
        imViewController.onSendMessageFailure(messageId, reason: strreason!, code: Int(code))
    }

    func onSubscriptionFailure(_ subscribeId: Int, statusCode: Int32) {
        NSLog("SubscriptionFailure subscribeId \(subscribeId) statusCode: \(statusCode)")
    }

    func onSubscriptionTerminated(_ subscribeId: Int) {
        NSLog("SubscriptionFailure subscribeId \(subscribeId)")
    }

    // Play file event
    func onPlayAudioFileFinished(_: Int, fileName _: UnsafeMutablePointer<Int8>!) {}

    func onPlayVideoFileFinished(_: Int) {}

    // RTP/Audio/video stream callback data

    func onReceivedRTPPacket(_: Int, isAudio _: Bool, rtpPacket _: UnsafeMutablePointer<UInt8>!, packetSize _: Int32) {
        /* !!! IMPORTANT !!!

         Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
         other code which will spend long time, you should post a message to main thread(main window) or other thread,
         let the thread to call SDK API functions or other code.
         */
    }

    func onSendingRTPPacket(_: Int, isAudio _: Bool, rtpPacket _: UnsafeMutablePointer<UInt8>!, packetSize _: Int32) {
        /* !!! IMPORTANT !!!

         Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
         other code which will spend long time, you should post a message to main thread(main window) or other thread,
         let the thread to call SDK API functions or other code.
         */
    }

    func onAudioRawCallback(_: Int, audioCallbackMode _: Int32, data _: UnsafeMutablePointer<UInt8>!, dataLength _: Int32, samplingFreqHz _: Int32) {
        /* !!! IMPORTANT !!!

         Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
         other code which will spend long time, you should post a message to main thread(main window) or other thread,
         let the thread to call SDK API functions or other code.
         */
    }

    func onVideoRawCallback(_: Int, videoCallbackMode _: Int32, width _: Int32, height _: Int32, data _: UnsafeMutablePointer<UInt8>!, dataLength _: Int32) -> Int32 {
        /* !!! IMPORTANT !!!

         Don't call any PortSIP SDK API functions in here directly. If you want to call the PortSIP API functions or
         other code which will spend long time, you should post a message to main thread(main window) or other thread,
         let the thread to call SDK API functions or other code.
         */
        0
    }

    func pressNumpadButton(_ dtmf: Int32) {
        if activeSessionid != CLong(INVALID_SESSION_ID) {
            _callManager.playDtmf(sessionid: activeSessionid, tone: Int(dtmf))
        }
    }

    func makeCall(_ callee: String, videoCall: Bool) -> (CLong) {
        if activeSessionid != CLong(INVALID_SESSION_ID) {
            showAlertView("Warning", message: "Current line is busy now, please switch a line")
            return CLong(INVALID_SESSION_ID)
        }

        let sessionId = _callManager.makeCall(callee: callee, displayName: callee, videoCall: videoCall)

        if sessionId >= 0 {
            activeSessionid = sessionId
            print("makeCall------------------ \(String(describing: activeSessionid))")
            numpadViewController.setStatusText("Calling:\(callee) on line \(_activeLine!)")

            return activeSessionid
        } else {
            numpadViewController.setStatusText("make call failure ErrorCode =\(sessionId)")
            return sessionId
        }
    }

    func hungUpCall() {
        if activeSessionid != CLong(INVALID_SESSION_ID) {
            _ = mSoundService.stopRingTone()
            _ = mSoundService.stopRingBackTone()
            _callManager.endCall(sessionid: activeSessionid)

            numpadViewController.setStatusText("Hungup call on line \(String(describing: _activeLine))")
        }
    }

    func holdCall() {
        if activeSessionid != CLong(INVALID_SESSION_ID) {
            _callManager.holdCall(sessionid: activeSessionid, onHold: true)
        }
        numpadViewController.setStatusText("hold call on line \(_activeLine as Int?)")

        if isConference == true {
            _callManager.holdAllCall(onHold: true)
        }
    }

    func unholdCall() {
        if activeSessionid != CLong(INVALID_SESSION_ID) {
            _callManager.holdCall(sessionid: activeSessionid, onHold: false)
        }
        numpadViewController.setStatusText("UnHold the call on line \(_activeLine as Int?)")

        if isConference == true {
            _callManager.holdAllCall(onHold: false)
        }
    }

    func referCall(_ referTo: String) {
        let result = _callManager.findCallBySessionID(activeSessionid)
        if result == nil || !result!.sessiona.sessionState {
            showAlertView("Warning", message: "Need to make the call established first")
            return
        }

        let ret = portSIPSDK.refer(activeSessionid, referTo: referTo)
        if ret != 0 {
            showAlertView("Warning", message: "Refer failed")
        }
    }

    func muteCall(_ mute: Bool) {
        if activeSessionid != CLong(INVALID_SESSION_ID) {
            _callManager.muteCall(sessionid: activeSessionid, muted: mute)
        }
        if isConference == true {
            _callManager.muteAllCall(muted: mute)
        }
    }

    func setLoudspeakerStatus(_ enable: Bool) {
        portSIPSDK.setLoudspeakerStatus(enable)
    }

    func getStatistics() {
        let audio: Bool = true
        let video: Bool = true
        if audio {
            // audio Statistics
            var sendBytes: Int32 = 0
            var sendPackets: Int32 = 0
            var sendPacketsLost: Int32 = 0
            var sendFractionLost: Int32 = 0
            var sendRttMS: Int32 = 0
            var sendCodecType: Int32 = 0
            var sendJitterMS: Int32 = 0
            var sendAudioLevel: Int32 = 0
            var recvBytes: Int32 = 0
            var recvPackets: Int32 = 0
            var recvPacketsLost: Int32 = 0
            var recvFractionLost: Int32 = 0
            var recvCodecType: Int32 = 0
            var recvJitterMS: Int32 = 0
            var recvAudioLevel: Int32 = 0

            let errorCodec: Int32 = portSIPSDK.getAudioStatistics(activeSessionid, sendBytes: &sendBytes, sendPackets: &sendPackets, sendPacketsLost: &sendPacketsLost, sendFractionLost: &sendFractionLost, sendRttMS: &sendRttMS, sendCodecType: &sendCodecType, sendJitterMS: &sendJitterMS, sendAudioLevel: &sendAudioLevel, recvBytes: &recvBytes, recvPackets: &recvPackets, recvPacketsLost: &recvPacketsLost, recvFractionLost: &recvFractionLost, recvCodecType: &recvCodecType, recvJitterMS: &recvJitterMS, recvAudioLevel: &recvAudioLevel)
            if errorCodec == 0 {
                print("Audio Send Statistics sendBytes:\(sendBytes) sendPackets:\(sendPackets) sendPacketsLost:\(sendPacketsLost) sendFractionLost:\(sendFractionLost) sendRttMS:\(sendRttMS) sendCodecType:\(sendCodecType) sendJitterMS:\(sendJitterMS) sendAudioLevel:\(sendAudioLevel) ")
                print("Audio Received Statistics recvBytes:\(recvBytes) recvPackets:\(recvPackets) recvPacketsLost:\(recvPacketsLost) recvFractionLost:\(recvFractionLost) recvCodecType:\(recvCodecType) recvJitterMS:\(recvJitterMS) recvAudioLevel:\(recvAudioLevel)")
            }
        }
        if video {
            // Video Statistics
            var sendBytes: Int32 = 0
            var sendPackets: Int32 = 0
            var sendPacketsLost: Int32 = 0
            var sendFractionLost: Int32 = 0
            var sendRttMS: Int32 = 0
            var sendCodecType: Int32 = 0
            var sendFrameWidth: Int32 = 0
            var sendFrameHeight: Int32 = 0
            var sendBitrateBPS: Int32 = 0
            var sendFramerate: Int32 = 0
            var recvBytes: Int32 = 0
            var recvPackets: Int32 = 0
            var recvPacketsLost: Int32 = 0
            var recvFractionLost: Int32 = 0
            var recvCodecType: Int32 = 0
            var recvFrameWidth: Int32 = 0
            var recvFrameHeight: Int32 = 0
            var recvBitrateBPS: Int32 = 0
            var recvFramerate: Int32 = 0
            let errorCodec: Int32 = portSIPSDK.getVideoStatistics(activeSessionid, sendBytes: &sendBytes, sendPackets: &sendPackets, sendPacketsLost: &sendPacketsLost, sendFractionLost: &sendFractionLost, sendRttMS: &sendRttMS, sendCodecType: &sendCodecType, sendFrameWidth: &sendFrameWidth, sendFrameHeight: &sendFrameHeight, sendBitrateBPS: &sendBitrateBPS, sendFramerate: &sendFramerate, recvBytes: &recvBytes, recvPackets: &recvPackets, recvPacketsLost: &recvPacketsLost, recvFractionLost: &recvFractionLost, recvCodecType: &recvCodecType, recvFrameWidth: &recvFrameWidth, recvFrameHeight: &recvFrameHeight, recvBitrateBPS: &recvBitrateBPS, recvFramerate: &recvFramerate)

            if errorCodec == 0 {
                print("Video Send Statistics sendBytes:\(sendBytes) sendPackets:\(sendPackets) sendPacketsLost:\(sendPacketsLost) sendFractionLost:\(sendFractionLost) sendRttMS:\(sendRttMS) sendCodecType:\(sendCodecType) sendFrameWidth:\(sendFrameWidth) sendFrameHeight:\(sendFrameHeight) sendBitrateBPS:\(sendBitrateBPS) sendFramerate:\(sendFramerate) ")
            }
        }
    }

    func didSelectLine(_ activedline: Int) {
        let tabBarController = window?.rootViewController as! UITabBarController

        tabBarController.dismiss(animated: true, completion: nil)

        if !sipRegistered || _activeLine == activedline {
            return
        }

        if !isConference {
            _callManager.holdCall(sessionid: activeSessionid, onHold: true)
        }
        _activeLine = activedline

        activeSessionid = lineSessions[_activeLine]

        numpadViewController.buttonLine.setTitle("Line\(activedline)", for: .normal)

        if !isConference && activeSessionid != CLong(INVALID_SESSION_ID) {
            _callManager.holdCall(sessionid: activeSessionid, onHold: false)
        }
    }

    func switchSessionLine() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)

        let selectLineView = storyBoard.instantiateViewController(withIdentifier: "LineTableViewController") as! LineTableViewController

        selectLineView.delegate = self
        selectLineView.activeLine = _activeLine

        let tabBarController = window?.rootViewController as! UITabBarController

        tabBarController.present(selectLineView, animated: true, completion: nil)
    }

//    #pragma mark - CallManager delegate

    func onIncomingCallWithoutCallKit(_ sessionId: CLong, existsVideo: Bool, remoteParty: String, remoteDisplayName: String) {
        guard _callManager.findCallBySessionID(sessionId) != nil else {
            return
        }
        if UIApplication.shared.applicationState == .background, _enablePushNotification == false {
            let localNotif = UILocalNotification()
            var stringAlert = "Call from \n \(remoteParty)"

            if existsVideo {
                stringAlert = "VideoCall from \n  \(remoteParty)"
            }
            localNotif.soundName = "ringtone.mp3"
            localNotif.alertBody = stringAlert
            localNotif.repeatInterval = NSCalendar.Unit(rawValue: 0)

            UIApplication.shared.presentLocalNotificationNow(localNotif)
        } else {
            let index = findSession(sessionid: sessionId)
            if index < 0 {
                return
            }
            let alertController = UIAlertController(title: "Incoming Call", message: "Call from <\(remoteDisplayName)>\(remoteParty) on line \(index)", preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "Reject", style: .default, handler: { action in
                _ = self.mSoundService.stopRingTone()
                self._callManager.endCall(sessionid: sessionId)

                self.numpadViewController.setStatusText("Reject Call on line \(index)")
            }))
            
            alertController.addAction(UIAlertAction(title: "Answer", style: .default, handler: { action in
                _ = self.mSoundService.stopRingTone()
                _ = self._callManager.answerCall(sessionId: sessionId, isVideo: false)

                self.numpadViewController.setStatusText("Answer Call on line \(index)")
            }))
            
            if existsVideo {
                           alertController.addAction(UIAlertAction(title: "Video", style: .default, handler: { action in
                               _ = self.mSoundService.stopRingTone()
                               _ = self._callManager.answerCall(sessionId: sessionId, isVideo: true)

                               self.numpadViewController.setStatusText("Answer Video Call on line \(index)")
                           }))
                       }

            let tabBarController = window?.rootViewController as! UITabBarController

            tabBarController.present(alertController, animated: true)
            
            _ = mSoundService.playRingTone()
        }
    }

    func onNewOutgoingCall(sessionid: CLong) {
        lineSessions[_activeLine] = sessionid
    }

    func onAnsweredCall(sessionId: CLong) {
        let result = _callManager.findCallBySessionID(sessionId)

        if result != nil {
            if result!.sessiona.videoState {
                videoViewController.onStartVideo(sessionId)
                setLoudspeakerStatus(true)
            } else {
                setLoudspeakerStatus(false)
            }
            let line = findSession(sessionid: sessionId)
            if line >= 0 {
                didSelectLine(line)
            }
        }

        _ = mSoundService.stopRingTone()
        _ = mSoundService.stopRingBackTone()

        if activeSessionid == CLong(INVALID_SESSION_ID) {
            activeSessionid = sessionId
        }

        numpadViewController.setStatusText("Call Established on line \(findSession(sessionid: sessionId))")
    }

    func onCloseCall(sessionId: CLong) {
        numpadViewController.setStatusText("Call Close on line \(findSession(sessionid: sessionId))")

        freeLine(sessionid: sessionId)

        let result = _callManager.findCallBySessionID(sessionId)
        if result != nil {
            if result!.sessiona.videoState {
                videoViewController.onStopVideo(sessionId)
            }

            _callManager.removeCall(call: result!.sessiona)
        }
        if sessionId == activeSessionid {
            activeSessionid = CLong(INVALID_SESSION_ID)
        }

        _ = mSoundService.stopRingTone()
        _ = mSoundService.stopRingBackTone()

        if _callManager.getConnectCallNum() == 0 {
            setLoudspeakerStatus(true)
        }
    }

    func onMuteCall(sessionId: CLong, muted _: Bool) {
        let result = _callManager.findCallBySessionID(sessionId)
        if result != nil {
            // update Mute status
        }
    }

    func onHoldCall(sessionId: CLong, onHold: Bool) {
        let result = _callManager.findCallBySessionID(sessionId)
        if result != nil, sessionId == activeSessionid {
            if onHold {
                portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: nil)
                numpadViewController.setStatusText("Hold call on line \(_activeLine as Int?)")
            } else {
                portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: videoViewController.viewRemoteVideo)
                numpadViewController.setStatusText("unHold call on line \(_activeLine as Int?)")
            }
        }
    }

    func createConference(_ conferenceVideoWindow: PortSIPVideoRenderView) {
        if _callManager.createConference(conferenceVideoWindow: conferenceVideoWindow, videoWidth: 352, videoHeight: 288, displayLocalVideoInConference: true) {
            isConference = true
        }
    }

    func setConferenceVideoWindow(conferenceVideoWindow: PortSIPVideoRenderView) {
        portSIPSDK.setConferenceVideoWindow(conferenceVideoWindow)
    }

    func joinToConference(_ sessionId: Int) -> Bool {
        if isConference != nil {
//            let ret = portSIPSDK.join(toConference: conferenceId, sessionId: sessionId);
            let ret = portSIPSDK.join(toConference: sessionId)

            if ret != 0 {
                NSLog("Join to Conference fail")
                return false
            } else {
                // Remove session remote video window, Only show conference video windows
                portSIPSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: nil)
                portSIPSDK.sendVideo(sessionId, sendState: true)
                NSLog("Join to Conference success")
                return true
            }
        }
        return false
    }

    func removeFromConference(_ sessionId: Int) {
        if isConference != nil {
            let ret = portSIPSDK.remove(fromConference: sessionId)

//            let ret = portSIPSDK.remove(fromConference: conferenceId, sessionId: sessionId);
            if ret != 0 {
                NSLog("Session %zd Remove from Conference fail", sessionId)
            } else {
                NSLog("Session %zd Remove from Conference success", sessionId)
            }
        }
    }

    func destoryConference(_: UIView) {
        _callManager.destoryConference()
        let result = _callManager.findCallBySessionID(activeSessionid)
        if result != nil && result!.sessiona.holdState {
            _callManager.holdCall(sessionid: result!.sessiona.sessionId, onHold: false)
        }
        isConference = false
    }
}
