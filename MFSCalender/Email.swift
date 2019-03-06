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
    let isRead: Bool
    let id: String
    init(senderName: String, senderAddress: String, body: String, subject: String, timeStamp: Int, isRead: Bool, id: String) {
        self.senderName = senderName
        self.senderAddress = senderAddress
        self.body = body
        self.subject = subject
        self.timeStamp = timeStamp
        self.isRead = isRead
        self.id = id
    }
    
    init(dict: [String: Any]) {
        self.senderName = dict["senderName"] as? String ?? ""
        self.senderAddress = dict["senderAddress"] as? String ?? ""
        self.body = dict["body"] as? String ?? ""
        self.subject = dict["subject"] as? String ?? ""
        self.timeStamp = dict["timestamp"] as? Int ?? 0
        self.isRead = (dict["isRead"] as? Int ?? 1) == 1
        self.id = dict["id"] as? String ?? ""
    }
    
    init() {
        self.senderName = ""
        self.senderAddress = ""
        self.body = ""
        self.subject = ""
        self.timeStamp = 0
        self.isRead = false
        self.id = ""
    }
}
