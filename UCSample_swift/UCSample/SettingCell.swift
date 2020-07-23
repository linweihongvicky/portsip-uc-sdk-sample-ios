//
//  SettingCell.m
//  UCSample
//
//  Created by Joe Lepple on 9/25/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//
import UIKit

class SettingItem {
    var index: Int
    var name: String
    var enable: Bool
    var codeType: Int32

    init() {
        index = 0
        name = ""
        enable = false
        codeType = 0
    }
}

class SettingCell: UITableViewCell {
    var settingItem: SettingItem!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var switchOperation: UISwitch!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func SetItem(_ item: SettingItem) {
        settingItem = item

        switchOperation.isOn = item.enable
        switchOperation.tag = item.index
        nameLabel.text = item.name
    }

    @IBAction func onSwitchChange(_ sender: AnyObject) {
        if settingItem != nil {
            settingItem.enable = (sender as! UISwitch).isOn
        }
    }
}
