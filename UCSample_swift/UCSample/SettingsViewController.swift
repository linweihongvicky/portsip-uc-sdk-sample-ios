//
//  SettingsViewController.m
//  UCSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

let kNumbersOfSections = 3

let kAudioCodecsKey = "Audio Codecs"
let kVideoCodecsKey = "Video Codecs"
let kAdvanceFeatureKey = "Advance Feature"
class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var portSIPSDK: PortSIPSDK!

    var settingsAudioCodec: [SettingItem]!
    var settingsVideoCodec: [SettingItem]!
    var settingsAdvanceFeature: [SettingItem]!

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        settingsAudioCodec = []

        var item = SettingItem()

        item.index = 0
        item.name = "OPUS"
        item.enable = true
        item.codeType = AUDIOCODEC_OPUS.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 1
        item.name = "G.729"
        item.enable = true
        item.codeType = AUDIOCODEC_G729.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 2
        item.name = "PCMA"
        item.enable = true
        item.codeType = AUDIOCODEC_PCMA.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 3
        item.name = "PCMU"
        item.enable = true
        item.codeType = AUDIOCODEC_PCMU.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 4
        item.name = "GSM"
        item.enable = false
        item.codeType = AUDIOCODEC_GSM.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 5
        item.name = "G.722"
        item.enable = false
        item.codeType = AUDIOCODEC_G722.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 6
        item.name = "iLBC"
        item.enable = false
        item.codeType = AUDIOCODEC_ILBC.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 7
        item.name = "AMR"
        item.enable = false
        item.codeType = AUDIOCODEC_AMR.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 8
        item.name = "AMRWB"
        item.enable = false
        item.codeType = AUDIOCODEC_AMRWB.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 9
        item.name = "SpeexNB(8Khz)"
        item.enable = false
        item.codeType = AUDIOCODEC_SPEEX.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 10
        item.name = "SpeexWB(16Khz)"
        item.enable = false
        item.codeType = AUDIOCODEC_SPEEXWB.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 11
        item.name = "ISACWB(16Khz)"
        item.enable = false
        item.codeType = AUDIOCODEC_ISACWB.rawValue
        settingsAudioCodec.append(item)

        item = SettingItem()
        item.index = 12
        item.name = "ISACSWB(32Khz)"
        item.enable = false
        item.codeType = AUDIOCODEC_ISACSWB.rawValue
        settingsAudioCodec.append(item)

        // Video codec item
        settingsVideoCodec = []
        item = SettingItem()
        item.index = 102
        item.name = "H.264"
        item.enable = true
        item.codeType = VIDEO_CODEC_H264.rawValue
        settingsVideoCodec.append(item)

        item = SettingItem()
        item.index = 103
        item.name = "VP8"
        item.enable = false
        item.codeType = VIDEO_CODEC_VP8.rawValue
        settingsVideoCodec.append(item)

        item = SettingItem()
        item.index = 104
        item.name = "VP9"
        item.enable = false
        item.codeType = VIDEO_CODEC_VP9.rawValue
        settingsVideoCodec.append(item)

        // Advance Feature
        settingsAdvanceFeature = []
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        item = SettingItem()
        item.index = 300
        item.name = "Integrated Calling"
        item.enable = appDelegate._callManager.enableCallKit
        item.codeType = -1
        settingsAdvanceFeature.append(item)

        item = SettingItem()
        item.index = 301
        item.name = "Push Notification"
        item.enable = appDelegate._enablePushNotification!
        item.codeType = -1
        settingsAdvanceFeature.append(item)

        item = SettingItem()
        item.index = 302
        item.name = "Force Background"
        item.enable = appDelegate._enableForceBackground!
        item.codeType = -1
        settingsAdvanceFeature.append(item)

        tableView.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_: Bool) {
        // save change
        portSIPSDK.clearAudioCodec()

        for item in settingsAudioCodec {
            if item.enable {
                portSIPSDK.addAudioCodec(AUDIOCODEC_TYPE(item.codeType))
            }
        }

        portSIPSDK.clearVideoCodec()
        for item in settingsVideoCodec {
            if item.enable {
                portSIPSDK.addVideoCodec(VIDEOCODEC_TYPE(item.codeType))
            }
        }

        let settings: UserDefaults? = UserDefaults.standard
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for item in settingsAdvanceFeature {
            switch item.index {
            case 300:
                // Integrated Calling
                if #available(iOS 10.0, *) {
                    appDelegate._callManager.enableCallKit = item.enable
                }

                settings?.set(item.enable, forKey: "CallKit")
            case 301:
                // Push Notification
                if appDelegate._enablePushNotification != item.enable {
                    appDelegate._enablePushNotification = item.enable
                    appDelegate.updatePushStatusToSipServer()
                }
                settings?.set(item.enable, forKey: "PushNotification")
            case 302:
                appDelegate._enableForceBackground = item.enable
                settings?.set(item.enable, forKey: "ForceBackground")
            default:
                break
            }
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        kNumbersOfSections
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return settingsAudioCodec.count
        case 1:
            return settingsVideoCodec.count
        case 2:
            return settingsAdvanceFeature.count
        default:
            return 0
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return kAudioCodecsKey
        case 1:
            return kVideoCodecsKey
        case 2:
            return kAdvanceFeatureKey
        default:
            return ""
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingCell") as! SettingCell

        var item: SettingItem
        switch indexPath.section {
        case 0:
            item = settingsAudioCodec[indexPath.row]
        case 1:
            item = settingsVideoCodec[indexPath.row]
        case 2:
            item = settingsAdvanceFeature[indexPath.row]
        default:
            return cell
        }

        cell.SetItem(item)

        return cell
    }

    func tableView(_: UITableView, didSelectRowAt _: IndexPath) {}
}
