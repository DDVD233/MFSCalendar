//
//  CalendarViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/4/14.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import FSCalendar

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

    @IBOutlet weak var classView: UITableView!

    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var eventView: UITableView!
    
    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var calendarView: FSCalendar!
    
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    var numberOfRolls:Int? = 6
    
    let formatter = DateFormatter()
    var listClasses: NSMutableArray = []
    var listEvents: NSMutableArray = []
    var dayOfSchool: String? = nil
    
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
        self.backButton.title = "Fold"
        self.navigationItem.title = "Classes"
        self.view.addGestureRecognizer(self.scopeGesture)
        
        self.classView.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.eventView.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.bottomScrollView.contentSize = CGSize(width: self.view.frame.size.width * 2, height: self.bottomScrollView.frame.size.height)
        self.classView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.bottomScrollView.frame.size.height)
        self.bottomScrollView.addSubview(classView)
        self.eventView.frame = CGRect(x: self.view.frame.size.width, y: 0, width: self.view.frame.size.width, height: self.bottomScrollView.frame.size.height)
        self.bottomScrollView.addSubview(eventView)
        self.calendarView.select(Date())
        dataFetching()
        eventDataFetching()
        self.classView.delegate = self
        self.classView.dataSource = self
        self.classView.emptyDataSetSource = self
        self.classView.emptyDataSetDelegate = self
        self.eventView.delegate = self
        self.eventView.dataSource = self
        self.eventView.emptyDataSetDelegate = self
        self.eventView.emptyDataSetSource = self
        self.calendarView.delegate = self
        self.calendarView.dataSource = self
        self.bottomScrollView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    @IBAction func expandButton(_ sender: Any) {
        if self.calendarView.scope == .month {
            self.backButton.title = "Expand"
            self.calendarView.setScope(.week, animated: true)
        } else {
            self.backButton.title = "Fold"
            self.calendarView.setScope(.month, animated: true)
        }
        
    }
    
    @IBAction func backToToday(_ sender: Any) {
        self.calendarView.select(Date())
        let _ = self.checkDate(checkDate: Date())
        self.dataFetching()
        self.eventDataFetching()
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = self.classView.contentOffset.y <= -self.classView.contentInset.top
        if !shouldBegin {
            shouldBegin = self.eventView.contentOffset.y <= -self.eventView.contentInset.top
        }
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
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
        var str = ""
        let attr = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        if scrollView == classView {
            str = "There is no class on this day."
            self.classView.separatorStyle = .none
        } else if scrollView == eventView {
            str = "There is no event on this day."
            self.eventView.separatorStyle = .none
        }
        
        return NSAttributedString(string: str, attributes: attr)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        var image:UIImage? = nil
        if scrollView == classView {
            image = UIImage(named: "brush_pencil.png")?.imageResize(sizeChange: CGSize(width: 85, height: 85))
        } else if scrollView == eventView {
            image = UIImage(named: "School_building.png")?.imageResize(sizeChange: CGSize(width: 95, height: 95))
        }
        
        return image
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == bottomScrollView {
            let offset = bottomScrollView.contentOffset
            NSLog(String(describing:offset.x))
            let viewWidth = self.view.frame.width
            self.pageControl.currentPage = Int(offset.x) / Int(viewWidth)
            if self.pageControl.currentPage == 0 {
                self.navigationItem.title = "Classes"
            } else {
                self.navigationItem.title = "Events"
            }
        }
    }
    
    @IBAction func changePage(_ sender: Any) {
        let x = CGFloat(self.pageControl.currentPage) * self.bottomScrollView.frame.size.width
        self.bottomScrollView.setContentOffset(CGPoint(x:x, y:0), animated: true)
    }
    
    func checkDate(checkDate:Date) -> String {
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = plistPath.appending("/Day.plist")
        let dayDict = NSDictionary(contentsOfFile: path)
        var day:String? = nil
        self.formatter.dateFormat = "yyyyMMdd"
        let checkDate = self.formatter.string(from: checkDate)
        if dayDict?[checkDate] == nil {
            day = "No School"
        } else {
            day = dayDict?[checkDate] as? String
        }
        
        return day!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
}

extension CalendarViewController: UITableViewDelegate, UITableViewDataSource {

    func dataFetching() {
        if let checkDate = self.calendarView.selectedDates.first {
            self.dayOfSchool = self.checkDate(checkDate: checkDate)
        }
        if (self.dayOfSchool == "No School") || (self.dayOfSchool == nil) {
            self.listClasses = []
            self.classView.reloadData()
        } else {
            self.classView.separatorStyle = .singleLine
            let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let fileName = "/Class" + self.dayOfSchool! + ".plist"
            let path = plistPath.appending(fileName)

            self.listClasses = NSMutableArray(contentsOfFile: path)!
            var i = 1
            let sortedClass: NSMutableArray = []
            for _ in 1...8 {
                for items in self.listClasses {
                    let dict = items as! NSDictionary
                    let periodNumber = Int(dict["period"] as! String)!
                    if (periodNumber == i) {
                        sortedClass.add(dict)
                    }
                }
                i += 1
            }
            self.listClasses = sortedClass
            self.classView.reloadData()
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
            self.eventView.reloadData()
            return
        }
        self.listEvents = events
        self.eventView.reloadData()
    }

    //    the number of the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        if tableView == self.classView {
            return self.listClasses.count
        } else {
            return self.listEvents.count
        }
    }


    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == classView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "classTable", for: indexPath as IndexPath) as? customCalendarCell
            
            let row = indexPath.row
            
            let rowDict = self.listClasses[row] as! NSDictionary
            
            cell?.ClassName.text = rowDict["name"] as? String
            cell?.PeriodNumber.text = rowDict["period"] as? String
            let inFormatter = DateFormatter()
            inFormatter.dateFormat = "HH:mm"
            let PeriodNumberInt = Int(rowDict["period"] as! String)!
            var meetTime:String? = nil
            
            switch PeriodNumberInt {
            case 1: meetTime = "8:00 - 8:43"
            case 2: meetTime = "8:47 - 9:30"
            case 3: meetTime = "9:34 - 10:34"
            case 4: meetTime = "10:44 - 11:27"
            case 5: meetTime = "11:31 - 12:14"
            case 6: meetTime = "12:14 - 12:57"
            case 7: meetTime = "13:40 - 14:23"
            case 8: meetTime = "14:27 - 15: 10"
            default: meetTime = "Error!"
            }
            let teacherName = rowDict["teacherName"] as? String
            if teacherName != nil {
                cell?.PeriodTime.text = meetTime! + "     Teacher: " + teacherName!
            } else {
                cell?.PeriodTime.text = meetTime!
            }
            if rowDict["room"] != nil {
                cell?.RoomNumber.text = "Room " + (rowDict["room"] as! String)
            } else {
                cell?.RoomNumber.text = nil
            }
            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "eventTable", for: indexPath as IndexPath) as? customEventCell
            let row = indexPath.row
            let rowDict = self.listEvents[row] as! NSDictionary
            let summary = rowDict["summary"] as? String
            cell?.ClassName.text = summary
            let letter = summary?.substring(to: (summary?.index(after: (summary?.startIndex)!))!)
            cell?.PeriodNumber.text = letter!
            if rowDict["location"] != nil {
                let location = rowDict["location"] as! String
                //这里有问题啊啊啊啊啊啊
//                ???什么问题啊没看见
                if location.hasSuffix("place fields") || location.hasSuffix("Place Fields") {
                    cell?.RoomNumber.text = nil
                } else {
                    cell?.RoomNumber.text = "At: " + location
                }
            }
            if (rowDict["isAllDay"] as! Int) == 1 {
                cell?.PeriodTime.text = "All Day"
            } else {
                let tEnd = String(describing:(rowDict["tEnd"] as! Int))
                if (rowDict["tEnd"] as! Int) > 99999 {
                    self.formatter.dateFormat = "HHmmss"
                } else {
                    self.formatter.dateFormat = "Hmmss"
                }
                let timeEnd = formatter.date(from: tEnd)
                let tStart = String(describing:(rowDict["tStart"] as! Int))
                if (rowDict["tStart"] as! Int) > 99999 {
                    self.formatter.dateFormat = "HHmmss"
                } else {
                    self.formatter.dateFormat = "Hmmss"
                }
                let timeStart = formatter.date(from: tStart)
                self.formatter.dateFormat = "h:mm a"
                let startString = formatter.string(from: timeStart!)
                let endString = formatter.string(from: timeEnd!)
                cell?.PeriodTime.text = startString + " - " + endString
            }
            return cell!
        }
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
            self.backButton.title = "Fold"
        } else {
            self.backButton.title = "Expand"
        }
        self.view.layoutIfNeeded()
        self.classView.frame.size.height = self.bottomScrollView.frame.height
        self.eventView.frame.size.height = self.bottomScrollView.frame.height
    }
    
}