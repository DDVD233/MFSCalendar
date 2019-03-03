//
//  Email.swift
//  MFSMobile
//
//  Created by David Dai on 3/2/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation

class Email {
    let senderName: String
    let senderAddress: String
    let body: String
    let subject: String
    let timeStamp: Int
    init(senderName: String, senderAddress: String, body: String, subject: String, timeStamp: Int) {
        self.senderName = senderName
        self.senderAddress = senderAddress
        self.body = body
        self.subject = subject
        self.timeStamp = timeStamp
    }
}
