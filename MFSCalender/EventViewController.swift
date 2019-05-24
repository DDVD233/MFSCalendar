//
//  EventViewController.swift
//  MFSMobile
//
//  Created by David Dai on 1/19/18.
//  Copyright © 2018 David. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import XLPagerTabStrip
import SafariServices
import CoreData

class eventViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, IndicatorInfoProvider {
    
    @IBOutlet var eventView: UITableView!
    let formatter = DateFormatter()
    var listEvents = [Events]()
    var selectedDate: Date? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        eventView.delegate = self
        eventView.dataSource = self
        eventView.emptyDataSetSource = self
        eventView.emptyDataSetDelegate = self
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)]
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
        
        guard let thisSelectedDate = selectedDate else {
            print("No Date")
            return
        }
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Events> = Events.fetchRequest()
        let dateAtStartOfDay = thisSelectedDate.dateAtStartOf(.day)
        let dateAtEndOfDay = thisSelectedDate.dateAtEndOf(.day)
        
        // Starts before the end of day, ends after the starts of day today.
        let predicate = NSPredicate(format: "(startDate < %@) AND (endDate > %@)", dateAtEndOfDay as CVarArg, dateAtStartOfDay as CVarArg)
        fetchRequest.predicate = predicate
        let result = try! context.fetch(fetchRequest)
        
        self.formatter.dateFormat = "yyyyMMdd"
        self.listEvents = result
        reloadData()
    }
    
    func reloadData() {
        if Preferences().schoolName == "MFS" {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let event = Events(entity: NSEntityDescription.entity(forEntityName: "Events", in: context)!, insertInto: nil)
            event.setValue("1st Period Announcement", forKey: "title")
            
            self.listEvents.insert(event, at: 0)
        }
        
        DispatchQueue.main.async {
            if self.isViewLoaded && self.view != nil {
                self.eventView.reloadData()
            }
        }
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Events")
    }
}

extension eventViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    //    the number of the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listEvents.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTable", for: indexPath as IndexPath) as! customEventCell
        let row = indexPath.row
        
        if row == 0 && Preferences().schoolName == "MFS" {
            cell.selectionStyle = .default
        } else {
            cell.selectionStyle = .none
        }
        
        guard self.listEvents.indices.contains(row) else { return cell }
        let rowDict = self.listEvents[row]
        
        guard let summary = rowDict.title else {
            return UITableViewCell()
        }
        cell.ClassName.text = summary
        
        let letter = String(describing: summary[...summary.startIndex])
        cell.PeriodNumber.text = letter
        
        let location = rowDict.location ?? ""
        if location.hasSuffix("place fields") || location.hasSuffix("Place Fields") {
            cell.RoomNumber.text = ""
        } else {
            cell.RoomNumber.text = location
        }
        
        cell.PeriodTime.text = EventView().getTimeInterval(rowDict: rowDict)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && Preferences().schoolName == "MFS" {
            let url = URL.init(string: "https://sites.google.com/mfriends.org/us-students/home")!
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true, completion: nil)
        }
    }
}

