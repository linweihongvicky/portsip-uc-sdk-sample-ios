//
//  FirstViewController.m
//  UCSample
//

//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//
import UIKit

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

class LoginViewController: UIViewController, UITextFieldDelegate, NetParamsControllerDelegate {
    var portSIPSDK: PortSIPSDK!
    var sipInitialized = false
    var sipRegistered = false

    var sipRegistrationStatus: Int!

    var autoRegisterRetryTimes: Int!
    var autoRegisterTimer: Timer!
    var srtpItems: [String]!
    var transPortItems: [String]!

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var viewStatus: UIView!
    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var labelDebugInfo: UILabel!

    @IBOutlet var textUsername: UITextField!
    @IBOutlet var textPassword: UITextField!
    @IBOutlet var textUserDomain: UITextField!
    @IBOutlet var textSIPserver: UITextField!
    @IBOutlet var textSIPPort: UITextField!
    @IBOutlet var textAuthname: UITextField!

    @IBOutlet var btTrans: UIButton!
    @IBOutlet var btSrtp: UIButton!
    @IBOutlet var labelTrans: UILabel!
    @IBOutlet var labelSrtp: UILabel!
    @IBOutlet var rootView: UIScrollView!

    @IBOutlet var websiteLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!

    override func viewDidLayoutSubviews() {
        rootView.contentSize = CGSize(width: 320, height: 568)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        textUsername.delegate = self
        textPassword.delegate = self
        textUserDomain.delegate = self
        textSIPserver.delegate = self
        textSIPPort.delegate = self
        textAuthname.delegate = self

        sipInitialized = false
        sipRegistered = false
        sipRegistrationStatus = 0
        autoRegisterRetryTimes = 0

        labelDebugInfo.text = "PortSIP VoIP SDK for iOS"

        transPortItems = ["UDP", "TLS", "TCP", "PERS_UDP", "PERS_TCP"]

        srtpItems = ["NONE", "FORCE", "PREFER"]

        textUsername.text = UserDefaults.standard.object(forKey: "kUserName") as? String
        textAuthname.text = UserDefaults.standard.object(forKey: "kAuthName") as? String
        textPassword.text = UserDefaults.standard.object(forKey: "kPassword") as? String
        textUserDomain.text = UserDefaults.standard.object(forKey: "kUserDomain") as? String
        textSIPserver.text = UserDefaults.standard.object(forKey: "kSIPServer") as? String
        textSIPPort.text = UserDefaults.standard.object(forKey: "kSIPServerPort") as? String

        doAutoRegister()
    }

    func doAutoRegister() {
        if textUsername.text!.count > 0, textPassword.text!.count > 0,
            textSIPserver.text!.count > 0, textSIPPort.text!.count > 0 {
            onLine()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    func keyboardWillShow(_ noti:Notification)
//    {
//        let height:CGFloat = 216.0;
//        var frame = self.view.frame;
//        frame.size = CGSize(width: frame.size.width, height: frame.size.height - height);
//        UIView.beginAnimations("Curl" ,context: nil);
//        UIView.setAnimationDuration(0.30);
//        UIView.setAnimationDelegate(self);
//        self.view.frame = frame;
//        UIView.commitAnimations();
//    }

    func textFieldShouldReturn(_ textField: UITextField) -> CBool {
        // When the user presses return, take focus away from the text field so that the keyboard is dismissed.
        let animationDuration: TimeInterval = 0.30
        UIView.beginAnimations("ResizeForKeyboard", context: nil)
        UIView.setAnimationDuration(animationDuration)
        let rect = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
        view.frame = rect
        UIView.commitAnimations()
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let frame = textField.frame
        let offset = frame.origin.y + 32 - (view.frame.size.height - 216.0)
        let animationDuration: TimeInterval = 0.30
        UIView.beginAnimations("ResizeForKeyBoard", context: nil)
        UIView.setAnimationDuration(animationDuration)

        let width = view.frame.size.width
        let height = view.frame.size.height

        if offset > 0 {
            let rect = CGRect(x: 0.0, y: -offset, width: width, height: height)
            view.frame = rect
        }
        UIView.commitAnimations()
    }

    func onLine() {
        if sipInitialized {
            labelDebugInfo.text = "You already registered, Offline first!"
            return
        }

        let kUserName = textUsername.text
        let kDisplayName = textUsername.text
        let kAuthName = textAuthname.text
        let kPassword = textPassword.text
        let kUserDomain = textUserDomain.text
        let kSIPServer = textSIPserver.text
        var kSIPServerPort = Int32(textSIPPort.text!)

        if kSIPServerPort == nil {
            kSIPServerPort = 5060
        }

        if kUserName?.count < 1 {
            showAlterViewWith(title: "Information", message: "Please enter user name!")
            return
        }

        if kPassword?.count < 1 {
            showAlterViewWith(title: "Information", message: "Please enter password")
            return
        }

        if kSIPServer?.count < 1 {
            showAlterViewWith(title: "Information", message: "Please enter SIP Server")
            return
        }

        var transport = TRANSPORT_UDP // TRANSPORT_TCP
        // When you need background, TCP and TLS SIP transport is save battery, UDP takes more battery

        switch btTrans.tag {
        case 0:
            transport = TRANSPORT_UDP
        case 1:
            transport = TRANSPORT_TLS
        case 2:
            transport = TRANSPORT_TCP
        case 3:
            transport = TRANSPORT_PERS_UDP

        case 4:
            transport = TRANSPORT_PERS_TCP

        default:
            break
        }

        var srtp = SRTP_POLICY_NONE
        switch btSrtp.tag {
        case 0:
            srtp = SRTP_POLICY_NONE
        case 1:
            srtp = SRTP_POLICY_FORCE
        case 2:
            srtp = SRTP_POLICY_PREFER
        default:
            break
        }

        UserDefaults.standard.set(kUserName, forKey: "kUserName")
        UserDefaults.standard.set(kAuthName, forKey: "kAuthName")
        UserDefaults.standard.set(kPassword, forKey: "kPassword")
        UserDefaults.standard.set(kUserDomain, forKey: "kUserDomain")
        UserDefaults.standard.set(kSIPServer, forKey: "kSIPServer")
        UserDefaults.standard.set(textSIPPort.text, forKey: "kSIPServerPort")
        // UserDefaults.standard.set(transport, forKey: "kTRANSPORT")

        // let localPort = 10000 + arc4random()%1000;
        let localPort = 10002
        let loaclIPaddress = "0.0.0.0" // Auto select IP address

        var ret = portSIPSDK.initialize(transport, localIP: loaclIPaddress, localSIPPort: Int32(localPort), loglevel: PORTSIP_LOG_NONE, logPath: "", maxLine: 8, agent: "PortSIP SDK for IOS", audioDeviceLayer: 0, videoDeviceLayer: 0, tlsCertificatesRootPath: "", tlsCipherList: "", verifyTLSCertificate: false)

        if ret != 0 {
            NSLog("initialize failure ErrorCode = %d", ret)
            return
        }

        ret = portSIPSDK.setUser(kUserName, displayName: kDisplayName, authName: kAuthName, password: kPassword, userDomain: kUserDomain, sipServer: kSIPServer, sipServerPort: kSIPServerPort!, stunServer: "", stunServerPort: 0, outboundServer: "", outboundServerPort: 0)

        if ret != 0 {
            NSLog("setUser failure ErrorCode = %d", ret)
            return
        }
        
        showAlterViewWith(title: "Warning", message: "This PortSIP UC SDK is free to use. It could be only works with PortSIP PBX. To use with other PBX, please use PortSIP VoIP SDK instead. Feel free to contact us by sales@portsip.com to get more details.")

        portSIPSDK.addAudioCodec(AUDIOCODEC_OPUS)
        portSIPSDK.addAudioCodec(AUDIOCODEC_G729)
        portSIPSDK.addAudioCodec(AUDIOCODEC_PCMA)
        portSIPSDK.addAudioCodec(AUDIOCODEC_PCMU)

        // portSIPSDK.addAudioCodec(AUDIOCODEC_GSM);
        // portSIPSDK.addAudioCodec(AUDIOCODEC_ILBC);
        // portSIPSDK.addAudioCodec(AUDIOCODEC_AMR);
        // portSIPSDK.addAudioCodec(AUDIOCODEC_SPEEX);
        // portSIPSDK.addAudioCodec(AUDIOCODEC_SPEEXWB);

        portSIPSDK.addVideoCodec(VIDEO_CODEC_H264)
        // portSIPSDK.addVideoCodec(VIDEO_CODEC_VP8);
        // portSIPSDK.addVideoCodec(VIDEO_CODEC_VP9);

        portSIPSDK.setVideoBitrate(-1, bitrateKbps: 500) // video send bitrate,500kbps
        portSIPSDK.setVideoFrameRate(-1, frameRate: 10)
        portSIPSDK.setVideoResolution(352, height: 288)
        portSIPSDK.setAudioSamples(20, maxPtime: 60) // ptime 20

        portSIPSDK.setInstanceId(UIDevice.current.identifierForVendor?.uuidString)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        appDelegate.addPushSupportWithPortPBX(appDelegate._enablePushNotification!)

        // 1 - FrontCamra 0 - BackCamra
        portSIPSDK.setVideoDeviceId(1)

        // enable video RTCP nack
        portSIPSDK.setVideoNackStatus(true)

        // enable srtp
        portSIPSDK.setSrtpPolicy(srtp)

        // Try to register the default identity. Registration refreshment interval is 90 seconds
        ret = portSIPSDK.registerServer(90, retryTimes: 0)
        if ret != 0 {
            portSIPSDK.unInitialize()
            NSLog("registerServer failure ErrorCode = %d", ret)
            return
        }

        if transport == TRANSPORT_TCP ||
            transport == TRANSPORT_TLS {
            portSIPSDK.setKeepAliveTime(0)
        }

        activityIndicator.startAnimating()

        labelDebugInfo.text = "Registration..."
        var sipURL: String
        if kSIPServerPort == 5060 {
            sipURL = "sip:\(kUserName!):\(kUserDomain!)"
        } else {
            sipURL = "sip:\(kUserName!):\(kUserDomain!):\(String(describing: kSIPServerPort))"
        }

        appDelegate.sipURL = sipURL

        sipInitialized = true
        sipRegistrationStatus = 1
    }

    func offLine(_ keepPush: Bool) {
        if sipInitialized {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if appDelegate._enablePushNotification!, !keepPush {
                appDelegate.addPushSupportWithPortPBX(false)
            }
            portSIPSDK.unRegisterServer()
            viewStatus.backgroundColor = UIColor.red
            labelStatus.text = "Not Connected"
            labelDebugInfo.text = "unRegisterServer"

            Thread.sleep(forTimeInterval: 1.0)
            portSIPSDK.unInitialize()
            sipInitialized = false
        }
        if activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
        }
        sipRegistrationStatus = 0
    }

    @IBAction func onOnlineButtonClick(_: AnyObject) {
        onLine()
    }

    @IBAction func Offline_keepPush(_: Any) {
        offLine(true)
    }

    @IBAction func onOfflineButtonClick(_: AnyObject) {
        offLine(false)
    }

    @objc func refreshRegister() {
        if sipRegistrationStatus == 0 {
            // Not Register
            return
        } else if sipRegistrationStatus == 1 {
            // is registering
            return
        } else if sipRegistrationStatus == 2 {
            // has registered, refreshRegistration
            print("Refresh Registration...")
            portSIPSDK.refreshRegistration(0)
            labelDebugInfo.text = "Refresh Registration..."
        } else if sipRegistrationStatus == 3 {
            print("retry a new register")
            // Register Failure
            portSIPSDK.unRegisterServer()
            portSIPSDK.unInitialize()
            sipInitialized = false
            onLine()
        }
    }

    func unRegister() {
        if sipRegistrationStatus == 1 || sipRegistrationStatus == 2 {
            portSIPSDK.unRegisterServer()
            labelDebugInfo.text = "unRegister when background"
            print("unRegister when background")
            sipRegistrationStatus = 3
        }
    }

    func onRegisterSuccess(_: CInt, withStatusText statusText: String) {
        viewStatus.backgroundColor = UIColor.green

        labelStatus.text = "Connected"

        labelDebugInfo.text = "onRegisterSuccess: \(statusText)"

        activityIndicator.stopAnimating()

        sipRegistered = true

        sipRegistrationStatus = 2
        autoRegisterRetryTimes = 0
        return
    }

    func onRegisterFailure(_ statusCode: CInt, withStatusText statusText: String) {
        viewStatus.backgroundColor = UIColor.red

        labelStatus.text = "Not Connected"

        labelDebugInfo.text = "onRegisterFailure: \(statusText)"

        activityIndicator.stopAnimating()

        sipRegistrationStatus = 3

        if statusCode != 401, statusCode != 403, statusCode != 404 {
            // 401-Unauthorized 403-Forbidden
            // If the NetworkStatus not change, received onRegisterFailure event.
            // added a atuo reRegister Timer
            var interval = TimeInterval(autoRegisterRetryTimes * 2 + 1)
            // max interval is 60
            interval = interval > 60 ? 60 : interval
            autoRegisterRetryTimes = autoRegisterRetryTimes + 1
            autoRegisterTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(refreshRegister), userInfo: nil, repeats: false)
        }
    }

    func showAlterViewWith(title: String, message: String) {
        //create alertcontroller object
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        //add action
        alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alertView, animated: true)
    }

    func didSelectValue(_ key: String, value: Int) {
        if key == "TransPort" {
            btTrans.tag = value
            labelTrans.text = transPortItems[value]
        } else {
            btSrtp.tag = value
            labelSrtp.text = srtpItems[value]
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let from = sender as! UIButton
        if from == btTrans {
            let controller = segue.destination as! NetParamsController
            controller.data = transPortItems
            controller.labletitle = "TransPort"
            controller.delegate = self

        } else if from == btSrtp {
            let controller = segue.destination as! NetParamsController
            controller.data = srtpItems
            controller.labletitle = "SRTP"
            controller.delegate = self
        }
    }
}
