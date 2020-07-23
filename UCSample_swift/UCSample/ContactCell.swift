//
//  ContactCell.m
//  UCSample
//
//  Created by Joe Lepple on 6/14/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    var urlLabel: UILabel!
    var noteLabel: UILabel!
    @IBOutlet var onlineImageView: UIImageView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
