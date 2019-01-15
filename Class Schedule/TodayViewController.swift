//
//  TodayViewController.swift
//  Class Schedule
//
//  Created by 戴元平 on 2017/2/25.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import NotificationCenter
import SwiftDate


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
        SwiftDate.defaultRegion = Region.local
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
        self.listClasses = school.classesOnADayAfter(date: Date())

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

        dayOfSchool = dayDict?[checkDate] as? String ?? "No School"

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
        let periodNumber = rowDict["period"] as! Int
        
        cell?.classTime.text = school.meetTimeForPeriod(period: periodNumber, date: Date())

        if cell?.className.text == "Lunch" {
            cell?.periodNumber.text = "L"
        } else {
            cell?.periodNumber.text = String(describing: periodNumber)
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
