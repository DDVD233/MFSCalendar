//
//  CourseMO+CoreDataProperties.swift
//  
//
//  Created by 戴元平 on 2/21/18.
//
//

import Foundation
import CoreData


extension CourseMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CourseMO> {
        return NSFetchRequest<CourseMO>(entityName: "Course")
    }
    
    init(startTime: Date?, endTime: Date?, name: String?, teacherName: String?, sectionID: Int32?, room: String?) {
        self.startTime = startTime
        self.endTime = endTime
        self.name = name
        self.teacherName = teacherName
        self.sectionID = sectionID
        self.room = room
    }

    @NSManaged public var startTime: NSDate?
    @NSManaged public var endTime: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var teacherName: String?
    @NSManaged public var secionID: Int32
    @NSManaged public var room: String?

}
