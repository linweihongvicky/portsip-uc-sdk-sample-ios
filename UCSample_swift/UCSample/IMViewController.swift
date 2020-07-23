//
//  IMViewController.m
//  UCSample
//

//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//
import Foundation
class IMViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    var portSIPSDK: PortSIPSDK!

    @IBOutlet var textContact: UITextField!
    @IBOutlet var textMessage: UITextField!
    @IBOutlet var tableView: UITableView!
    var contacts: [Contact]!

    override func viewDidLoad() {
        super.viewDidLoad()

        textContact.delegate = self
        textMessage.delegate = self
        // Do any additional setup after loading the view.

        contacts = []
        tableView.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        tableView.delegate = self
        tableView.dataSource = self
        obseveKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func obseveKeyboard(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }


    @objc func keyboardWillShow(_ notification: NSNotification) {

        let userInfo = (notification as NSNotification).userInfo!
        let keyboardSize = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey]as! NSValue).cgRectValue
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        let kbHeight = keyboardSize.height
        let offset = (textMessage.frame.origin.y+textMessage.frame.size.height) - (self.view.frame.size.height - kbHeight)
        if(offset>0){
            UIView.animate(withDuration: duration!, animations: {
                self.view.frame = CGRect(origin: CGPoint(x: 0.0, y: -offset), size: CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height))
                
            });
        }

    }
    
    @objc func keyboardWillHide(_ notification: NSNotification){

        let userInfo = (notification as NSNotification).userInfo!
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double

        UIView.animate(withDuration: duration!, animations:{
            self.view.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height))
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {

    }

    @IBAction func onSubscribeClick(_: AnyObject) {
//        let subscribeID = portSIPSDK.presenceSubscribeContact(textContact.text,subject:"hello");
        let subscribeID = portSIPSDK.presenceSubscribe(textContact.text, subject: "hello")

        let contact = Contact(subscribeid: Int(subscribeID), andSipURL: textContact.text!)

        contacts.append(contact)
        tableView.reloadData()
    }

    @IBAction func onOnlineClick(_: AnyObject) {
        for contact in contacts {
//            portSIPSDK.presenceOnline(contact.subscribeID,statusText:"I'm here");
            portSIPSDK.setPresenceStatus(contact.subscribeID, statusText: "I'm here")
        }
    }

    @IBAction func onOfflineClick(_: AnyObject) {
        for contact in contacts {
//            portSIPSDK.presenceOffline(contact.subscribeID);
            portSIPSDK.setPresenceStatus(contact.subscribeID, statusText: "offline")
        }
    }

    @IBAction func onSendMessageClick(_: AnyObject) {
        let message = textMessage.text?.data(using: String.Encoding.utf8)
//        dataUsingEncoding:NSUTF8StringEncoding;

        let messageID = portSIPSDK.sendOut(ofDialogMessage: textContact.text, mimeType: "text", subMimeType: "plain", isSMS: false, message: message, messageLength: Int32((message?.count)!))

        NSLog("send Message %d", messageID)
    }

    // Instant Message/Presence Event
    func onSendMessageSuccess(_ messageId: Int) {
        NSLog("%zd message send success", messageId)
        return
    }

    func onSendMessageFailure(_ messageId: Int, reason _: String, code _: Int) {
        NSLog("%zd message send failure", messageId)
        return
    }

    func onPresenceRecvSubscribe(_ subscribeId: Int,
                                 fromDisplayName: String,
                                 from: String,
                                 subject: String) -> Int {
        for contact in contacts {
            if contact.sipURL == from { // has exist this contact
                // update subscribedId
                contact.subscribeID = subscribeId

                // Accept subscribe.
                portSIPSDK.presenceAcceptSubscribe(subscribeId)
//                portSIPSDK.presenceOnline(subscribeId, statusText:"Available");
                portSIPSDK.setPresenceStatus(subscribeId, statusText: "Available")
                return 0
            }
        }

        let contact = Contact(subscribeid: subscribeId, andSipURL: from)

        contacts.append(contact)
        tableView.reloadData()
        
        let alertView = UIAlertController(title: "Recv Subscribe", message: "Recv Subscribe <\(fromDisplayName)>\(from) : \(subject)", preferredStyle: .alert)

        alertView.addAction(UIAlertAction(title: "Reject", style: .default, handler: { action in
            self.portSIPSDK.presenceRejectSubscribe(subscribeId)
        }))

        alertView.addAction(UIAlertAction(title: "Accept", style: .default, handler: { action in
            for contact in self.contacts {
                if contact.subscribeID == subscribeId {
                    self.portSIPSDK.presenceAcceptSubscribe(subscribeId)
                    self.portSIPSDK.setPresenceStatus(subscribeId, statusText: "Available")

                    self.portSIPSDK.presenceSubscribe(contact.sipURL, subject: "Hello")
                }
            }
        }))
        present(alertView, animated: true)
        return 0
    }

    func onPresenceOnline(_: String,
                          from: String,
                          stateText: String) {
        for contact in contacts {
            if contact.sipURL == from {
                contact.basicState = "open"
                contact.note = stateText
                tableView.reloadData()
                break
            }
        }
    }

    func onPresenceOffline(_: String, from: String) {
        for contact in contacts {
            if contact.sipURL == from {
                contact.basicState = "close"
                tableView.reloadData()
                break
            }
        }
    }

    //        #pragma mark - Table view data source

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return contacts.count
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCellIdentifier") as! ContactCell

        // cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

        if contacts.count > indexPath.row {
            let contact = contacts[indexPath.row]

            cell.urlLabel.text = contact.sipURL
            cell.noteLabel.text = contact.note
            if contact.basicState == "open" {
                cell.onlineImageView.image = UIImage(contentsOfFile: "online.png")
            } else {
                cell.onlineImageView.image = UIImage(contentsOfFile: "offline.png")
            }
        }

        return cell
    }

    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
//            let contact = contacts[indexPath.row];
//            if (contact) {
//                mPortSIPSDK presenceUnsubscribeContact :contact.subscribeID;
//            }
            contacts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
    }
}
