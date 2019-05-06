//
//  Email.swift
//  MFSMobile
//
//  Created by David Dai on 3/2/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import CoreData

class Email {
    let senderName: String
    let senderAddress: String
    let body: String
    let subject: String
    let timeStamp: Int
    let isRead: Bool
    let id: String
    let toRecepients: [Mailbox]
    init(senderName: String, senderAddress: String, body: String, subject: String, timeStamp: Int, isRead: Bool, id: String, toRecepients: [Mailbox]) {
        self.senderName = senderName
        self.senderAddress = senderAddress
        self.body = body
        self.subject = subject
        self.timeStamp = timeStamp
        self.isRead = isRead
        self.id = id
        self.toRecepients = toRecepients
    }
    
    init(dict: [String: Any]) {
        self.senderName = dict["senderName"] as? String ?? ""
        self.senderAddress = dict["senderAddress"] as? String ?? ""
        self.body = dict["body"] as? String ?? ""
        self.subject = dict["subject"] as? String ?? ""
        self.timeStamp = dict["timestamp"] as? Int ?? 0
        self.isRead = (dict["isRead"] as? Int ?? 1) == 1
        self.id = dict["id"] as? String ?? ""
        let toRecepientDict = dict["toRecipients"] as? [[String: Any]] ?? [[String: Any]]()
        var toRecepients = [Mailbox]()
        for item in toRecepientDict {
            toRecepients.append(Mailbox(dict: item))
        }
        
        self.toRecepients = toRecepients
    }
    
    init(emailRecord: EmailRecord) {
        self.senderName = emailRecord.senderName ?? ""
        self.senderAddress = emailRecord.senderAddress ?? ""
        self.body = emailRecord.body ?? ""
        self.subject = emailRecord.subject ?? ""
        self.timeStamp = Int(emailRecord.timeStamp)
        self.isRead = emailRecord.isRead
        self.id = emailRecord.id ?? ""
        let toRecepientsString = emailRecord.receiversAddress ?? ""
        var mailBoxes = [Mailbox]()
        
        for recepient in toRecepientsString.components(separatedBy: ";") {
            let separated = recepient.components(separatedBy: "&")
            let mailBox = Mailbox(name: separated[1], address: separated[0])
            mailBoxes.append(mailBox)
        }
        self.toRecepients = mailBoxes
    }
    
    init() {
        self.senderName = ""
        self.senderAddress = ""
        self.body = ""
        self.subject = ""
        self.timeStamp = 0
        self.isRead = false
        self.id = ""
        self.toRecepients = [Mailbox]()
    }
    
    func save() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let emailRecord = NSEntityDescription.insertNewObject(forEntityName: "EmailRecord", into: context) as! EmailRecord
        emailRecord.senderName = senderName
        emailRecord.senderAddress = senderAddress
        emailRecord.subject = subject
        emailRecord.timeStamp = Int64(timeStamp)
        emailRecord.body = body
        emailRecord.id = id
        emailRecord.isRead = isRead
        
        var receivers = ""
        for box in toRecepients {
            receivers += box.address
            receivers += "&"
            receivers += box.name
            receivers += ";"
        }
        emailRecord.receiversAddress = receivers
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}

class Mailbox {
    let name: String
    let address: String
    
    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
    
    init(dict: [String: Any]) {
        self.name = dict["name"] as? String ?? ""
        self.address = dict["address"] as? String ?? ""
    }
}
