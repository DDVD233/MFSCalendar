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

class eventViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, IndicatorInfoProvider {
    
    @IBOutlet var eventView: UITableView!
    let formatter = DateFormatter()
    var listEvents: NSMutableArray = []
    var selectedDate: Date? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        let str = "There is no event on this day."
        self.eventView.separatorStyle = .none
        
        return NSAttributedString(string: str, attributes: attr)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let image = UIImage(named: "School_building.png")?.imageResize(sizeChange: CGSize(width: 95, height: 95))
        
        return image
    }
    
    func eventDataFetching() {
        self.eventView.separatorStyle = .singleLine
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Events.plist"
        let path = plistPath.appending(fileName)
        let eventData = NSMutableDictionary(contentsOfFile: path)
        guard let SelectedDate = selectedDate else {
            print("No Date")
            return
        }
        self.formatter.dateFormat = "yyyyMMdd"
        let eventDate = formatter.string(from: SelectedDate)
        guard let events = eventData?[eventDate] as? NSMutableArray else {
            self.listEvents = []
            self.eventView.reloadData(with: .automatic)
            self.eventView.reloadData()
            return
        }
        self.listEvents = events
        self.eventView.reloadData(with: .automatic)
        self.eventView.reloadData()
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Events")
    }
}

extension eventViewController: UITableViewDelegate, UITableViewDataSource {
    
    //    the number of the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listEvents.count
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTable", for: indexPath as IndexPath) as? customEventCell
        let row = indexPath.row
        let rowDict = self.listEvents[row] as! Dictionary<String, Any?>
        guard let summary = rowDict["summary"] as? String else {
            return UITableViewCell()
        }
        cell?.ClassName.text = summary
        let letter = String(describing: summary[...summary.startIndex])
        cell?.PeriodNumber.text = letter
        if rowDict["location"] != nil {
            let location = rowDict["location"] as! String
            if location.hasSuffix("place fields") || location.hasSuffix("Place Fields") {
                cell?.RoomNumber.text = nil
            } else {
                cell?.RoomNumber.text = "At: " + location
            }
        }
        
        cell?.PeriodTime.text = EventView().getTimeInterval(rowDict: rowDict)
        return cell!
    }
}

