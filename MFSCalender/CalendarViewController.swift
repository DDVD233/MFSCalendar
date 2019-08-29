//
//  CalendarViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/4/14.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import FSCalendar
import Crashlytics
import SnapKit
import XLPagerTabStrip

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

class CalendarViewController: SegmentedPagerTabStripViewController, UIGestureRecognizerDelegate {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var calendarView: FSCalendar!

    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!

    var numberOfRolls: Int? = 6

    let formatter = DateFormatter()
    var dayOfSchool: String? = nil
    var screenSize = UIScreen.main.bounds.size
    
    let classViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier :"timeTableViewController") as! ADay
    let eventViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier :"eventViewController") as! eventViewController
    let homeworkViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier :"homeworkViewController") as! homeworkViewController

    override func viewDidLoad() {
//        if Preferences().isiPhoneX {
//            hidesBottomBarWhenPushed = true
//        } else {
//            hidesBottomBarWhenPushed = false
//        }
        super.viewDidLoad()
        self.backButton.title = NSLocalizedString("Collapse", comment: "")
        addScopeGesture()
        self.calendarView.select(Date())
        
        dataFetching()
        eventDataFetching()
        homeworkDataFetching()
        
        self.calendarView.delegate = self
        self.calendarView.dataSource = self
    }
    
    func addScopeGesture() {
        let viewArray = [self, classViewController, eventViewController, homeworkViewController]
        for viewController in viewArray {
            let scopeGesture: UIPanGestureRecognizer = {
                [unowned self] in
                let panGesture = UIPanGestureRecognizer(target: self.calendarView, action: #selector(self.calendarView.handleScopeGesture(_:)))
                panGesture.delegate = self
                panGesture.minimumNumberOfTouches = 1
                panGesture.maximumNumberOfTouches = 2
                return panGesture
                }()
            viewController.view.addGestureRecognizer(scopeGesture)
            
            if let thisViewController = viewController as? ADay {
                thisViewController.tableView.panGestureRecognizer.require(toFail: scopeGesture)
            } else if let thisViewController = viewController as? eventViewController {
                thisViewController.eventView.panGestureRecognizer.require(toFail: scopeGesture)
            } else if let thisViewController = viewController as? homeworkViewController {
                thisViewController.homeworkTable.panGestureRecognizer.require(toFail: scopeGesture)
            }
        }
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [classViewController, homeworkViewController, eventViewController]
    }

    @IBAction func expandButton(_ sender: Any) {
        if self.calendarView.scope == .month {
            self.backButton.title = NSLocalizedString("Expand", comment: "")
            self.calendarView.setScope(.week, animated: true)
        } else {
            self.backButton.title = NSLocalizedString("Collapse", comment: "")
            self.calendarView.setScope(.month, animated: true)
        }

    }

    @IBAction func backToToday(_ sender: Any) {
        self.calendarView.select(Date())
        self.dataFetching()
        self.eventDataFetching()
        self.homeworkDataFetching()
//        Crashlytics.sharedInstance().crash()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin =
            ((classViewController.tableView.contentOffset.y <= -classViewController.tableView.contentInset.top) &&
            (eventViewController.eventView.contentOffset.y <= -eventViewController.eventView.contentInset.top)) && (homeworkViewController.homeworkTable.contentOffset.y <= -homeworkViewController.homeworkTable.contentInset.top)
        if shouldBegin {
            let velocity = (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: self.view)
//            往上拉->日历拉长。
            switch self.calendarView.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            @unknown default:
                fatalError("What is this?")
            }
        }
        return shouldBegin
    }
    
    func dataFetching() {
        guard let checkDate = self.calendarView.selectedDates.first else {
            return
        }
        
        classViewController.date = checkDate
//        self.dayOfSchool = self.checkDate(checkDate: checkDate)
//        if self.dayOfSchool != "No School" {
//            classViewController.daySelected = self.dayOfSchool
//        } else {
//            classViewController.daySelected = nil
//        }
        
        DispatchQueue.main.async {
            self.classViewController.dataFetching()
        }
    }
    
    func eventDataFetching() {
        let selectedDate = self.calendarView.selectedDates.first
        eventViewController.selectedDate = selectedDate
        eventViewController.eventDataFetching()
    }
    
    func homeworkDataFetching() {
        let selectedDate = self.calendarView.selectedDates.first
        homeworkViewController.daySelected = selectedDate
        homeworkViewController.filter = 1
        
        DispatchQueue.global().async {
            self.homeworkViewController.getHomework()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
}




extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
        
        DispatchQueue.main.async {
            self.reloadPagerTabStripView()
        }
        
        dataFetching()
        eventDataFetching()
        homeworkDataFetching()
    }

    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        let day = school.checkDate(checkDate: date)
        if day == NSLocalizedString("No School", comment: "") {
            return nil
        } else {
            return day
        }
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        if self.calendarView.scope == .month {
            self.backButton.title = NSLocalizedString("Collapse", comment: "")
        } else {
            self.backButton.title = NSLocalizedString("Expand", comment: "")
        }
        
        self.view.layoutIfNeeded()
        //self.classView.frame.size.height = self.bottomScrollView.frame.height
    }

}
