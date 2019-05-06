//
//  EmailRecord+CoreDataProperties.swift
//  
//
//  Created by 戴元平 on 5/6/19.
//
//

import Foundation
import CoreData


extension EmailRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailRecord> {
        return NSFetchRequest<EmailRecord>(entityName: "EmailRecord")
    }

    @NSManaged public var senderName: String?
    @NSManaged public var senderAddress: String?
    @NSManaged public var body: String?
    @NSManaged public var subject: String?
    @NSManaged public var timeStamp: Int64
    @NSManaged public var isRead: Bool
    @NSManaged public var id: String?
    @NSManaged public var receiversAddress: String?

}
