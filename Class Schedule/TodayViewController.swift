//
//  TodayViewController.swift
//  Class Schedule
//
//  Created by 戴元平 on 2017/2/25.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import NotificationCenter

class customCellWidget:UITableViewCell {
    
    @IBOutlet weak var className: UILabel!
    
    @IBOutlet weak var classRoom: UILabel!
    
    @IBOutlet weak var classTime: UILabel!
    
    @IBOutlet weak var periodNumber: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet var noClass: UILabel!
    
    var listClasses : NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getAllClass()
        
        if listClasses.count == 0 { 
            self.tableView.isHidden = true
            noClass.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 110)
            self.view.addSubview(noClass)
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    func getAllClass() {
        let day = dayCheck()
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + day + ".plist"
        let path = plistPath.appending(fileName)
        
        if NSMutableArray(contentsOfFile: path) != nil {
            let allClasses = NSMutableArray(contentsOfFile: path)!
            let date = NSDate()
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HHmm"
            let Now = Int(timeFormatter.string(from: date as Date) as String)
            print(date)
            NSLog(String(describing: Now))
            
            
            // I am going to rewrite this.
            let Period1Start: Int = 800
            let Period2Start: Int = 847
            let Period3Start: Int = 934
            let Period4Start = 1044
            let Period5Start = 1131
            let Period6Start = 1214
            let LunchStart = 1300
            let Period7Start = 1340
            let Period8Start = 1427
            let Period8End = 1510
            var currentClass: Int? = nil
            
            switch Now! {
            case 0..<Period1Start:
                NSLog("Period 0")
                currentClass = 0
            case Period1Start..<Period2Start:
                NSLog("Period 1")
                currentClass = 1
            case Period2Start..<Period3Start:
                NSLog("Period 2")
                currentClass = 2
            case Period3Start..<Period4Start:
                NSLog("Period 3")
                currentClass = 3
            case Period4Start..<Period5Start:
                NSLog("Period 4")
                currentClass = 4
            case Period5Start..<Period6Start:
                NSLog("Period 5")
                currentClass = 5
            case Period6Start..<LunchStart:
                NSLog("Period 6")
                currentClass = 6
            case LunchStart..<Period7Start:
                NSLog("Lunch")
                currentClass = 11
            case Period7Start..<Period8Start:
                NSLog("Period 7")
                currentClass = 7
            case Period8Start..<Period8End:
                NSLog("Period 8")
                currentClass = 8
            case Period8End..<3000:
                NSLog("Have a great afternoon!")
                currentClass = 9
            default:
                NSLog("???")
            }
            if currentClass! < 9 {
                for number in currentClass!...8 {
                    if number == 6 {
                        for items in allClasses {
                            let rowDict = items as! NSDictionary
                            let period = Int(rowDict["period"] as! String)
                            if period == number {
                                let name = rowDict["name"] as? String
                                let room = rowDict["room"] as? String
                                let teacher = rowDict["teacherName"] as? String
                                let addData: NSDictionary = ["name": name ?? "", "roomNumber": room ?? "", "teacher": teacher ?? "", "period": String(describing:period!)]
                                self.listClasses.add(addData)
                            }
                        }
                        let addData: NSDictionary = ["name": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": "11"]
                        self.listClasses.add(addData)
                    } else {
                        for items in allClasses {
                            let rowDict = items as! NSDictionary
                            let period = Int(rowDict["period"] as! String)
                            if period == number {
                                let name = rowDict["name"] as? String
                                let room = rowDict["room"] as? String
                                let teacher = rowDict["teacherName"] as? String
                                let addData: NSDictionary = ["name": name ?? "", "roomNumber": room ?? "", "teacher": teacher ?? "", "period": String(describing:period!)]
                                self.listClasses.add(addData)
                            }
                        }
                    }
                }
            } else if currentClass == 11 {
                let addData: NSDictionary = ["name": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": "11"]
                self.listClasses.add(addData)
                for number in 7...8 {
                    for items in allClasses {
                        let rowDict = items as! NSDictionary
                        let period = Int(rowDict["period"] as! String)
                        if period == number {
                            let name = rowDict["name"] as? String
                            let room = rowDict["room"] as? String
                            let teacher = rowDict["teacherName"] as? String
                            let addData: NSDictionary = ["name": name ?? "", "roomNumber": room ?? "", "teacher": teacher ?? "", "period": String(describing:period!)]
                            self.listClasses.add(addData)
                        }
                    }
                }
            }
            print(listClasses)
        } else {
        }

    }
    
    func dayCheck() -> String {
        var dayOfSchool:String? = nil
        let date = NSDate()
        let formatter = DateFormatter()
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = plistPath.appending("/Day.plist")
        let dayDict = NSDictionary(contentsOfFile: path)
        formatter.dateFormat = "yyyyMMdd"
        let checkDate = formatter.string(from: date as Date)
        
        if dayDict?[checkDate] == nil {
            dayOfSchool = "No School"
        } else {
            dayOfSchool = dayDict?[checkDate] as? String
        }
        return dayOfSchool!
    }
    
    //    the number of the cell
    func tableView(_ tableView:UITableView, numberOfRowsInSection selection:Int) -> Int {
        return self.listClasses.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeline", for: indexPath as IndexPath) as? customCellWidget
        
        let row = indexPath.row
        
        let rowDict = self.listClasses[row] as! NSDictionary
        
        cell?.className.text = rowDict["name"] as? String
        let PeriodNumberInt = Int(rowDict["period"] as! String)!
        
        switch PeriodNumberInt {
            case 1: cell?.classTime.text = "8:00AM - 8:43AM"
            case 2: cell?.classTime.text = "8:47AM - 9:30AM"
            case 3: cell?.classTime.text = "9:34AM - 10:34AM"
            case 4: cell?.classTime.text = "10:44AM - 11:27AM"
            case 5: cell?.classTime.text = "11:31AM - 12:14PM"
            case 6: cell?.classTime.text = "12:14PM - 12:57PM"
            case 11: cell?.classTime.text = "1:00PM - 1:40PM"
            case 7: cell?.classTime.text = "1:40PM - 2:23PM"
            case 8: cell?.classTime.text = "2:27PM - 3:10PM"
            default: cell?.classTime.text = "Not Found"
        }
        
        if cell?.className.text == "Lunch" {
            cell?.periodNumber.text = "L"
        } else {
            cell?.periodNumber.text = rowDict["period"] as? String
        }
        cell?.classRoom.text = rowDict["roomNumber"] as? String
        
        return cell!
    }
    
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            print("Change to compact")
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.preferredContentSize = maxSize
                self.view.layoutIfNeeded()
            })
        } else if activeDisplayMode == .expanded {
            self.preferredContentSize = maxSize
            print("Change to expanded")
            let height = self.listClasses.count * 55
            print(self.listClasses.count)
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.preferredContentSize = CGSize(width: 0, height: height)
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        completionHandler(NCUpdateResult.newData)
    }
    
}