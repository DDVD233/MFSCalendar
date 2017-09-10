//
//  CalendarViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/4/14.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import FSCalendar
import Crashlytics
import SnapKit

class customCalendarCell: UITableViewCell {

    @IBOutlet weak var ClassName: UILabel!

    @IBOutlet weak var PeriodNumber: UILabel!

    @IBOutlet weak var RoomNumber: UILabel!

    @IBOutlet weak var PeriodTime: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class customEventCell: UITableViewCell {

    @IBOutlet weak var ClassName: UILabel!

    @IBOutlet weak var PeriodNumber: UILabel!

    @IBOutlet weak var RoomNumber: UILabel!

    @IBOutlet weak var PeriodTime: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class CalendarViewController: UIViewController, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIGestureRecognizerDelegate {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!

    @IBOutlet weak var eventView: UITableView!

    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var calendarView: FSCalendar!

    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!

    var numberOfRolls: Int? = 6

    let formatter = DateFormatter()
    var listClasses: NSMutableArray = []
    var listEvents: NSMutableArray = []
    var dayOfSchool: String? = nil
    var isFirstTimeLoad = true
    
    let classViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier :"timeTableViewController") as! ADay

    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendarView, action: #selector(self.calendarView.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.backButton.title = "Collapse"
        self.navigationItem.title = "Classes"
        self.view.addGestureRecognizer(self.scopeGesture)
        self.eventView.panGestureRecognizer.require(toFail: self.scopeGesture)
        classViewController.view.addGestureRecognizer(scopeGesture)
        classViewController.tableView.panGestureRecognizer.require(toFail: self.scopeGesture)

        self.bottomScrollView.contentSize = CGSize(width: self.view.frame.size.width * 2, height: self.bottomScrollView.frame.size.height)
        self.eventView.delegate = self
        self.eventView.dataSource = self
        self.eventView.emptyDataSetDelegate = self
        self.eventView.emptyDataSetSource = self
        self.calendarView.delegate = self
        self.calendarView.dataSource = self
        self.bottomScrollView.delegate = self
        
        addChildViewController(classViewController)
    }

    override func viewDidAppear(_ animated: Bool) {
        if isFirstTimeLoad {
            classViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.bottomScrollView.frame.size.height)
            self.bottomScrollView.addSubview(classViewController.view)
            
            self.eventView.frame = CGRect(x: self.view.frame.size.width, y: 0, width: self.view.frame.size.width, height: self.bottomScrollView.frame.size.height)
            self.bottomScrollView.addSubview(eventView)
            
            self.calendarView.select(Date())
            
            dataFetching()
            eventDataFetching()
            
            isFirstTimeLoad = false
        }
    }

    @IBAction func expandButton(_ sender: Any) {
        if self.calendarView.scope == .month {
            self.backButton.title = "Expand"
            self.calendarView.setScope(.week, animated: true)
        } else {
            self.backButton.title = "Collapse"
            self.calendarView.setScope(.month, animated: true)
        }

    }

    @IBAction func backToToday(_ sender: Any) {
        self.calendarView.select(Date())
        let _ = self.checkDate(checkDate: Date())
        self.dataFetching()
        self.eventDataFetching()
//        Crashlytics.sharedInstance().crash()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = classViewController.tableView.contentOffset.y <= -classViewController.tableView.contentInset.top
        if !shouldBegin {
            shouldBegin = self.eventView.contentOffset.y <= -self.eventView.contentInset.top
        }
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
//            往上拉->日历拉长。
            switch self.calendarView.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        let str = "There is no event on this day."
        self.eventView.separatorStyle = .none

        return NSAttributedString(string: str, attributes: attr)
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let image = UIImage(named: "School_building.png")?.imageResize(sizeChange: CGSize(width: 95, height: 95))

        return image
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == bottomScrollView {
            let offset = bottomScrollView.contentOffset
            NSLog(String(describing: offset.x))
            let viewWidth = self.view.frame.width
            self.pageControl.currentPage = Int(offset.x) / Int(viewWidth)
            if self.pageControl.currentPage == 0 {
                self.navigationItem.title = "Classes"
            } else {
                self.navigationItem.title = "Events"
            }
        }
    }

    func checkDate(checkDate: Date) -> String {
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = plistPath.appending("/Day.plist")
        let dayDict = NSDictionary(contentsOfFile: path)
        self.formatter.dateFormat = "yyyyMMdd"
        let checkDate = self.formatter.string(from: checkDate)

        let day = dayDict?[checkDate] as? String ?? "No School"

        return day
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
}

extension CalendarViewController: UITableViewDelegate, UITableViewDataSource {

    func dataFetching() {
        guard let checkDate = self.calendarView.selectedDates.first else {
            return
        }
        
        self.dayOfSchool = self.checkDate(checkDate: checkDate)
        if self.dayOfSchool != "No School" {
            classViewController.daySelected = self.dayOfSchool
        } else {
            classViewController.daySelected = nil
        }
        
        if classViewController.tableView.visibleCells.count > 0 {
            classViewController.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        DispatchQueue.main.async {
            self.classViewController.dataFetching()
        }
    }

    func eventDataFetching() {
        self.eventView.separatorStyle = .singleLine
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Events.plist"
        let path = plistPath.appending(fileName)
        let eventData = NSMutableDictionary(contentsOfFile: path)
        guard let SelectedDate = self.calendarView.selectedDates.first else {
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

    //    the number of the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listEvents.count
    }


    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTable", for: indexPath as IndexPath) as? customEventCell
        let row = indexPath.row
        let rowDict = self.listEvents[row] as! Dictionary<String, Any?>
        let summary = rowDict["summary"] as? String
        cell?.ClassName.text = summary
        let letter = summary?.substring(to: (summary?.index(after: (summary?.startIndex)!))!)
        cell?.PeriodNumber.text = letter!
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


extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let _ = self.checkDate(checkDate: date)
        dataFetching()
        eventDataFetching()
    }

    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        let day = checkDate(checkDate: date)
        if day == "No School" {
            return nil
        } else {
            return day
        }
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        if self.calendarView.scope == .month {
            self.backButton.title = "Collapse"
        } else {
            self.backButton.title = "Expand"
        }
        self.view.layoutIfNeeded()
        //self.classView.frame.size.height = self.bottomScrollView.frame.height
        
        self.eventView.frame.size.height = self.bottomScrollView.frame.height

        self.bottomScrollView.contentSize = CGSize(width: self.view.frame.size.width * 2, height: self.bottomScrollView.frame.size.height)
    }

}

extension CalendarViewController: FSCalendarDelegateAppearance {
//    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
//        let day = self.checkDate(checkDate: date)
//        if day == "No School" {
//            return UIColor.red
//        } else {
//            return UIColor.black
//        }
//    }
}
