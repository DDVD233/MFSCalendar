//
//  EventViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 1/19/18.
//  Copyright © 2018 David. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import XLPagerTabStrip
import SafariServices
import JZCalendarWeekView



class eventViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, IndicatorInfoProvider {
    
    @IBOutlet var eventView: DefaultWeekView!
    
    let formatter = DateFormatter()
    var listEvents = [DefaultEvent]()
    var selectedDate: Date? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        eventView.setupCalendar(numOfDays: 1, setDate: Date(), allEvents: <#T##[Date : [JZBaseEvent]]#>, scrollType: .pageScroll, firstDayOfWeek: .Monday)
//        eventView.delegate = self
//        eventView.dataSource = self
//        eventView.emptyDataSetSource = self
//        eventView.emptyDataSetDelegate = self
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)]
        let str = "There is no event on this day."
//        self.eventView.separatorStyle = .none
        
        return NSAttributedString(string: str, attributes: attr)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let image = UIImage(named: "School_building.png")?.imageResize(sizeChange: CGSize(width: 95, height: 95))
        
        return image
    }
    
    func eventDataFetching() {
//        self.eventView.separatorStyle = .singleLine
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Events.plist"
        let path = plistPath.appending(fileName)
        guard let eventData = NSDictionary(contentsOfFile: path) as? [String: [[String: Any]]] else {
            self.listEvents = []
            reloadData()
            return
        }
        
//        guard let thisSelectedDate = selectedDate else {
//            print("No Date")
//            return
//        }
//        self.formatter.dateFormat = "yyyyMMdd"
//        let eventDate = formatter.string(from: thisSelectedDate)
//        guard let events = eventData[eventDate] else {
//            self.listEvents = []
//            reloadData()
//            return
//        }
        for (date, eventsAtDate) in eventData {
//            for event in eventsAtDate {
//                let defaultEvent = DefaultEvent(id: <#T##String#>, title: <#T##String#>, startDate: <#T##Date#>, endDate: <#T##Date#>, location: <#T##String#>)
//            }
        }
        self.listEvents = events
        reloadData()
    }
    
    func reloadData() {
        if Preferences().schoolName == "MFS" {
//            self.listEvents.insert(["summary": "1st Period Announcement", "isAllDay": 1], at: 0)
        }
        
        DispatchQueue.main.async {
//            if self.isViewLoaded && self.view != nil {
////                self.eventView.reloadData()
//            }
        }
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Events")
    }
}

//extension eventViewController: UITableViewDelegate, UITableViewDataSource {
//
//    //    the number of the cell
//    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
//        return self.listEvents.count
//    }

    
//    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTable", for: indexPath as IndexPath) as! customEventCell
//        let row = indexPath.row
//
//        if row == 0 && Preferences().schoolName == "MFS" {
//            cell.selectionStyle = .default
//        } else {
//            cell.selectionStyle = .none
//        }
//
//        guard self.listEvents.indices.contains(row) else { return cell }
//        let rowDict = self.listEvents[row]
//
//        guard let summary = rowDict["summary"] as? String else {
//            return UITableViewCell()
//        }
//        cell.ClassName.text = summary
//
//        let letter = String(describing: summary[...summary.startIndex])
//        cell.PeriodNumber.text = letter
//
//        let location = rowDict["location"] as? String ?? ""
//        if location.hasSuffix("place fields") || location.hasSuffix("Place Fields") {
//            cell.RoomNumber.text = ""
//        } else {
//            cell.RoomNumber.text = location
//        }
//
//        cell.PeriodTime.text = EventView().getTimeInterval(rowDict: rowDict)
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if indexPath.row == 0 && Preferences().schoolName == "MFS" {
//            let url = URL.init(string: "https://sites.google.com/mfriends.org/us-students/home")!
//            let safariViewController = SFSafariViewController(url: url)
//            present(safariViewController, animated: true, completion: nil)
//        }
//    }
//}

