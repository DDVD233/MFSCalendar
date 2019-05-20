//
//  Events+CoreDataProperties.swift
//  
//
//  Created by 戴元平 on 5/20/19.
//
//

import Foundation
import CoreData


extension Events {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Events> {
        return NSFetchRequest<Events>(entityName: "Events")
    }

    @NSManaged public var startDate: NSDate?
    @NSManaged public var endDate: NSDate?
    @NSManaged public var title: String?
    @NSManaged public var location: String?
    @NSManaged public var groupName: String?
    @NSManaged public var briefDescription: String?
    @NSManaged public var eventId: Int64
    
    init(startDate: NSDate? = nil, endDate: NSDate? = nil, title: String? = nil, location: String? = nil, groupName: String? = nil, briefDescription: String? = nil, eventId: Int64 = nil) {
        self.startDate = startDate
        self.briefDescription = briefDescription
        self.endDate = endDate
        self.title = title
        self.location = location
        self.groupName = groupName
        self.eventId = eventId
    }
}
