//
//  Contact.swift
//  UCSample
//
//  Created by Joe Lepple on 6/14/13.
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

class Contact {
    var subscribeID: Int
    var sipURL: String
    var basicState: String
    var note: String

    init(subscribeid: Int, andSipURL sipURL: String) {
        subscribeID = subscribeid
        self.sipURL = sipURL
        basicState = "close"
        note = ""
    }
}
