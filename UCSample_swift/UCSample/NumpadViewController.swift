//
//  SecondViewController.m
//  UCSample
//

//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

import UIKit

class NumpadViewController: UIViewController, UITextFieldDelegate {
    let kTAGStar: Int32 = 10
    let kTAGSharp: Int32 = 11

    let kTAGVideoCall: Int32 = 12
    let kTAGAudioCall: Int32 = 13
    let kTAGHangUp: Int32 = 14

    let kTAGHold: Int32 = 15
    let kTAGUnHold: Int32 = 16
    let kTAGRefer: Int32 = 17

    let kTAGMute: Int32 = 18
    let kTAGSpeak: Int32 = 19
    let kTAGStatistics: Int32 = 20

    let kTAGDelete: Int32 = 21

    @IBOutlet var textNumber: UITextField!
    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var buttonLine: UIButton!

    var status: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        textNumber.delegate = self

        labelStatus.text = status
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        buttonLine.setTitle("Line: \(appDelegate._activeLine!)", for: .normal)
        super.viewWillAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func onButtonClick(_ sender: AnyObject) {
        let tag = Int32((sender as! UIButton).tag)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        switch tag {
        case 0, 1, 2, 3, 4, 5, 6, 7, 8, 9:

            textNumber.text = textNumber.text! + String(tag)
            let dtmf = tag
            appDelegate.pressNumpadButton(dtmf)

        case kTAGStar:
            textNumber.text = (textNumber.text)! + "*"
            appDelegate.pressNumpadButton(10)

        case kTAGSharp:
            textNumber.text = (textNumber.text)! + "#"
            appDelegate.pressNumpadButton(11)

        case kTAGDelete:

            if !textNumber.text!.isEmpty {
                var text = textNumber.text!
                text.remove(at: text.index(before: text.endIndex))
                textNumber.text = text
            }

        case kTAGVideoCall:
            _ = appDelegate.makeCall(textNumber.text!, videoCall: true)

        case kTAGAudioCall:
            _ = appDelegate.makeCall(textNumber.text!, videoCall: false)

        case kTAGHangUp:
            appDelegate.hungUpCall()

        case kTAGHold:
            appDelegate.holdCall()

        case kTAGUnHold:
            appDelegate.unholdCall()

        case kTAGRefer:
            appDelegate.referCall(textNumber.text!)

        case kTAGMute:
            let buttonMute = sender as! UIButton
            if buttonMute.titleLabel?.text == "unMute" {
                appDelegate.muteCall(false)

                buttonMute.setTitle("Mute", for: .normal)
                labelStatus.text = "Mute"
            } else {
                appDelegate.muteCall(true)

                buttonMute.setTitle("unMute", for: .normal)
                labelStatus.text = "unMute"
            }

        case kTAGSpeak:

            let buttonSpeaker = sender as! UIButton
            if buttonSpeaker.titleLabel?.text == "Speaker" {
                appDelegate.setLoudspeakerStatus(true)

                buttonSpeaker.setTitle("earphone", for: .normal)
                labelStatus.text = "Enable Speaker"
            } else {
                appDelegate.setLoudspeakerStatus(false)

                buttonSpeaker.setTitle("Speaker", for: .normal)
                labelStatus.text = "Disable Speaker"
            }
        case kTAGStatistics:
            appDelegate.getStatistics()
        default: break
        }
    }

    @IBAction func onLineClick(_: AnyObject) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.switchSessionLine()
    }

    func setStatusText(_ statusText: String) {
        status = statusText
        if labelStatus != nil {
            labelStatus.text = statusText
        }
        print(statusText)
    }
}
