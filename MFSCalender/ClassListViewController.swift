//
//  ClassListViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/6/22.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit


class classListController:UITableViewController {
    
    var classList:NSArray?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        classList = NSArray(contentsOfFile: path)!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let classCount = self.classList?.count else {
            return 0
        }
        
        return classCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "classList", for: indexPath as IndexPath)
        let row = indexPath.row
        guard let classObject = self.classList?[row] as? NSDictionary else {
            return cell
        }
        //        let block = classObject?["block"] as? String
        let roomNumber = classObject["roomNumber"] as? String
        let teacherName = classObject["teacherName"] as? String ?? ""
        cell.textLabel?.text = classObject["className"] as? String
        var detail:String? = nil
        if !((roomNumber?.isEmpty)!) {
            //            Room number 不为空的时候
            detail = "Room: " + roomNumber!
        }
        if !teacherName.isEmpty {
            //            Same
            detail = detail?.appending(" Teacher's name: " + teacherName)
        }
        cell.detailTextLabel?.text = detail
        
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        userDefaults?.set(row, forKey: "indexForCourseToPresent")
    }
}
