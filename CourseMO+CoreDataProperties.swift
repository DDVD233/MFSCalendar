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

    @NSManaged public var startTime: NSDate?
    @NSManaged public var endTime: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var teacherName: String?
    @NSManaged public var secionID: Int32
    @NSManaged public var room: String?

}
