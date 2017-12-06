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

        let date = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmm"
        let now = Int(timeFormatter.string(from: date as Date) as String)!
        let currentPeriod = getCurrentPeriod(time: now)

        self.listClasses = getClassDataAt(period: currentPeriod, day: day)

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
        let PeriodNumberInt = rowDict["period"] as! Int

        switch PeriodNumberInt {
        case 1: cell?.classTime.text = "8:00AM - 8:42AM"
        case 2: cell?.classTime.text = "8:46AM - 9:28AM"
        case 3: cell?.classTime.text = "9:32AM - 10:32AM"
        case 4: cell?.classTime.text = "10:42AM - 11:24AM"
        case 5: cell?.classTime.text = "11:28AM - 12:10PM"
        case 6: cell?.classTime.text = "12:14PM - 12:56PM"
        case 11: cell?.classTime.text = "12:56PM - 1:38PM"
        case 7: cell?.classTime.text = "1:42PM - 2:24PM"
        case 8: cell?.classTime.text = "2:28PM - 3:10PM"
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
