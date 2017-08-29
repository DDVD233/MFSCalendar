//
//  TodayViewController.swift
//  Class Schedule
//
//  Created by 戴元平 on 2017/2/25.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import NotificationCenter


class customCellWidget: UITableViewCell {

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

    var listClasses = [[String: Any]]()

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

        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        // Do any additional setup after loading the view, typically from a nib.
    }


    func getAllClass() {
        let day = dayCheck()
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + day + ".plist"
        let path = plistPath.appending(fileName)

        guard let allClasses = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
            return
        }

        let date = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmm"
        let now = Int(timeFormatter.string(from: date as Date) as String)!
        print(date)
        NSLog(String(describing: now))


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

        switch now {
        case 0..<Period1Start:
            NSLog("Period 0")
            currentClass = 1
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
            NSLog("After School.")
            currentClass = 9
        default:
            NSLog("???")
            currentClass = -1
        }

        let lunch = ["className": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": 11] as [String: Any]

        switch currentClass! {
        case 1...8:
            self.listClasses = Array(allClasses[(currentClass! - 1)...7])

            if self.listClasses.count >= 2 { //Before lunch
                self.listClasses.insert(lunch, at: 6 - currentClass!)
            }
        case 11:
            // At lunch

            self.listClasses = Array(allClasses[6...7])

            self.listClasses.insert(lunch, at: 0)
        default:
            self.listClasses = []
        }

        print(self.listClasses)
    }

    func dayCheck() -> String {
        var dayOfSchool: String? = nil
        let date = Date()
        let formatter = DateFormatter()
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = plistPath.appending("/Day.plist")
        let dayDict = NSDictionary(contentsOfFile: path)
        formatter.dateFormat = "yyyyMMdd"
        let checkDate = formatter.string(from: date)

        if dayDict?[checkDate] == nil {
            dayOfSchool = "No School"
        } else {
            dayOfSchool = dayDict?[checkDate] as? String
        }
        return dayOfSchool!
    }

    //    the number of the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listClasses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "timeline", for: indexPath as IndexPath) as? customCellWidget

        let row = indexPath.row

        let rowDict = self.listClasses[row]

        let className = rowDict["className"] as? String
        cell?.className.text = className
        let PeriodNumberInt = rowDict["period"] as! Int

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
            cell?.periodNumber.text = String(describing: PeriodNumberInt)
        }
        cell?.classRoom.text = rowDict["roomNumber"] as? String

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowDict = self.listClasses[indexPath.row]
        print("didSelect")
        guard let index = rowDict["index"] as? Int else {
            return
        }

        let indexString = String(describing: index)
        let url = URL(string: "MFSCalendar://classDetail/?\(indexString)")!

        extensionContext?.open(url, completionHandler: nil)
    }

    @available(iOSApplicationExtension 10.0, *)
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
