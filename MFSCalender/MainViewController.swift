//
//  ViewController.swift
//  MFSCalender
//
//  Created by David Dai on 2016/12/1.
//  Copyright © 2016年 David. All rights reserved.
//

import UIKit
import SwiftMessages
import UserNotifications
import DZNEmptyDataSet
import Reachability
import SwiftDate
import ChameleonFramework


class customEventCellDashboard: UITableViewCell {

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

class classViewCell: UICollectionViewCell {
    var index: Int? = nil

    @IBOutlet weak var period: UILabel!

    @IBOutlet weak var className: UILabel!

    @IBOutlet weak var teacher: UILabel!

    @IBOutlet weak var roomNumber: UILabel!

    @IBOutlet var homeworkView: UIView!

    @IBOutlet var homeworkButton: UIButton!

    @IBOutlet var classViewButton: UIButton!
    

    @IBAction func classViewButtonClicked(_ sender: Any) {
        guard index != nil else {
            return
        }
        Preferences().indexForCourseToPresent = index!
        let classDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "classDetailViewController")
        if parentViewController != nil {
            parentViewController!.show(classDetailViewController, sender: parentViewController)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateTimer() {
        
    }
}

class Main: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var eventView: UITableView!
    @IBOutlet weak var classView: UICollectionView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet var eventViewLarge: UIView!
    @IBOutlet var eventBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var classViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet var classViewHeightConstraint: NSLayoutConstraint!
    
    let formatter = DateFormatter()
    var listEvents = [[String: Any]]()
    var listClasses = [[String: Any?]]()
    var listHomework = [String: Array<Dictionary<String, Any?>>]()
    var timer: Timer? = nil
//    Format: {Lead_Section_ID: [Homework]}
    var isVisible = true

    let reachability = Reachability()!
    var screenWidth = UIScreen.main.bounds.width

    override func viewDidLoad() {
        super.viewDidLoad()
//        if Preferences().isiPhoneX {
//            hidesBottomBarWhenPushed = true
//        } else {
//            hidesBottomBarWhenPushed = false
//        }
        //self.navigationController?.setStatusBarStyle(.lightContent)
        self.bottomView.layer.shadowColor = UIColor.black.cgColor
        self.bottomView.layer.shadowOpacity = 0.15
        self.bottomView.layer.shadowOffset = CGSize.zero
        self.bottomView.layer.shadowRadius = 15

        self.classView.delegate = self
        self.classView.dataSource = self
        self.classView.emptyDataSetSource = self
        self.classView.emptyDataSetDelegate = self
        self.eventView.delegate = self
        self.eventView.dataSource = self
        self.eventView.emptyDataSetDelegate = self
        self.eventView.emptyDataSetSource = self
        self.eventView.separatorStyle = .singleLine
        
        if #available(iOS 11, *) {
            eventBottomLayoutConstraint.isActive = true
        } else {
            eventBottomLayoutConstraint.isActive = false
            eventViewLarge.snp.makeConstraints({ make in
                make.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-10)
            })
        }

        if Preferences().firstName == nil {
            Preferences().didLogin = false
        }
        
        if Preferences().didLogin && Preferences().courseInitialized {

            NSLog("Already Logged in.")
            //timer = Timer.scheduledTimer(timeInterval: , target: self, selector: #selector(autoRefreshContents), userInfo: nil, repeats: true)
        } else {
            print("Cannot initialize data because the user did not logged in")
        }
        
        if Reachability()?.connection == .wifi {
            DispatchQueue.global().async {
                self.updateData()
            }
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        isVisible = true
    }

    override func viewDidAppear(_ animated: Bool) {
        //classViewHeightConstraint.constant = classView.contentSize.height
//        eventViewLarge.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: eventViewLarge.frame, andColors: [UIColor(hexString: 0xFF6666), UIColor(hexString: 0xFF9966)])

//        Add "== true" to prevent force unwrap.
        guard Preferences().didLogin else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ftController") as! firstTimeLaunchController
            self.present(vc, animated: true, completion: nil)
            return
        }

        guard Preferences().courseInitialized else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "courseFillController")
            self.present(vc!, animated: true, completion: nil)
            return
        }

        refreshDisplayedData()
        DispatchQueue.global().async {
            if Reachability()?.connection != .none && self.doRefreshData() {
                NSLog("Refresh Data")
                DispatchQueue.main.async {
                    self.presentCourseFillView()
                }
            } else {
                NSLog("No refresh, version: %@", String(describing: Preferences().version))
            }
        }
        
//        if Preferences().doPresentServiceView {
//            self.tabBarController?.selectedIndex = 4
//        }
//
//        if !userDefaults.bool(forKey: "didShowMobileServe") && Preferences().isStudent {
//            userDefaults.set(true, forKey: "didShowMobileServe")
//            if let mobileServeIntro = storyboard?.instantiateViewController(withIdentifier: "mobileServeIntro") {
//                self.present(mobileServeIntro, animated: true)
//            }
//        }
    }
    
    func autoRefreshContents() {
        DispatchQueue.global().async {
            self.refreshDisplayedData()
        }
        print("Content refreshed")
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        isVisible = false
    }

    func updateData() {
        let group = DispatchGroup()

        DispatchQueue.global().async(group: group, execute: {
            self.refreshEvents()
        })

        DispatchQueue.global().async(group: group, execute: {
            self.refreshData()
        })

        group.wait()

        self.refreshDisplayedData()
        
        DispatchQueue.global().async {
            ClassView().getProfilePhoto()
        }
        
        DispatchQueue.global().async {
            self.downloadLargeProfilePhoto()
        }
    }
    
    func presentCourseFillView() {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "courseFillController") {
            self.present(vc, animated: true, completion: nil)
        } else {
            presentErrorMessage(presentMessage: "Cannot find course fill page", layout: .statusLine)
        }
    }

    func refreshDisplayedData() {
        eventDataFetching()
        periodCheck(day: dayCheck())
        setupTheHeader()

        DispatchQueue.main.async {
            self.classView.reloadData()
            self.eventView.reloadData()
        }

//        Put time-taking process here.
//        DispatchQueue.global().async {
//            self.getHomework()
//
//            DispatchQueue.main.async {
//                self.classView.reloadData()
//            }
//        }
    }

    func downloadLargeProfilePhoto() {
        if reachability.connection == .wifi {
            if let largeFileLink = userDefaults.string(forKey: "largePhotoLink") {
                provider.request(.downloadLargeProfilePhoto(link: largeFileLink), completion: { result in
                    switch result {
                    case .success(_):
                        userDefaults.set(true, forKey: "didDownloadFullSizeImage")
                    case let .failure(error):
                        NSLog("Failed downloading large profile photo because: \(error)")
                    }
                })
            }
        }
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String? = ""
        var attrs: [NSAttributedStringKey: Any] = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        if scrollView == classView {
            str = "No more classes for today!"
        } else if scrollView == eventView {
            self.eventView.separatorStyle = .none
            str = "No more events for today!"
            attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), NSAttributedStringKey.foregroundColor: UIColor.white]
        }

        return NSAttributedString(string: str!, attributes: attrs)
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        var image: UIImage? = nil
        if scrollView == classView {
            image = UIImage(named: "Achievement.png")?.imageResize(sizeChange: CGSize(width: 120, height: 93.3))
        } else if scrollView == eventView {
            image = UIImage(named: "bell.png")?.imageResize(sizeChange: CGSize(width: 80, height: 80))
        }
        return image
    }

    func doRefreshData() -> Bool {

//        当版本号不存在时，默认更新数据
        let version = Preferences().version
        
        guard version != 0 else { return true }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        //let refreshDate = Preferences().refreshDate
        //let date = formatter.string(from: Date())

        //guard refreshDate != date else {
        //    return false
        //}

        var refresh = false
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(MyService.dataVersionCheck, completion: { result in
            switch result {
            case let .success(response):
                guard let nversion = try? response.mapString() else {
                    presentErrorMessage(presentMessage: "Version file nout found", layout: .statusLine)
                    return
                }

                guard let newVersion = Int(nversion) else {
                    return
                }
                print("Latest version:", newVersion)
                if newVersion != version {
                    refresh = true
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }

            semaphore.signal()
        })

        semaphore.wait()

        return refresh
    }


    func setupTheHeader() {
        let day = dayCheck()
        
        DispatchQueue.main.async {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d."
            //MMMM d, yyyy
            var today = formatter.string(from: date)
            let labelAttributes = [NSAttributedStringKey.font:
                UIFont.init(name: self.dateLabel.font.fontName, size: self.dateLabel.font.pointSize) ?? UIFont()]
            if NSString(string: today).size(withAttributes: labelAttributes).width > self.dateLabel.bounds.size.width - 10 {
                formatter.dateFormat = "EEEE, MMM d."
                today = formatter.string(from: date)
            }
            
            if NSString(string: today).size(withAttributes: labelAttributes).width > self.dateLabel.bounds.size.width - 10 {
                formatter.dateFormat = "EE, MMM d."
                today = formatter.string(from: date)
            }
            if day == "No School" {
                self.dayLabel.text = "No school today,"
            } else {
                self.dayLabel.text = "Today is " + day + " Day,"
            }
            self.welcomeLabel.text = "Welcome back, " + (Preferences().firstName ?? "") + "!"
            
            self.dateLabel.text = today
        }

    }

    func periodCheck(day: String) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmm"

        guard let now = Int(timeFormatter.string(from: Date())) else { return }

        let currentPeriod = getCurrentPeriod(time: now)

        self.listClasses = getClassDataAt(period: currentPeriod, day: day)
    }

    func getHomework() {
        self.listHomework = [String: Array<Dictionary<String, Any?>>]()

        guard let username = Preferences().username else {
            return
        }
        var request = URLRequest(url: URL(string: "https://dwei.org/assignmentlist/")!)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        let session = URLSession.init(configuration: config)

        if username != "testaccount" {
            let (success, _, _) = loginAuthentication()
            if success {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.dateFormat = "M/d/yyyy"
                let today = formatter.string(from: Date()).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = "https://mfriends.myschoolapp.com/api/DataDirect/AssignmentCenterAssignments/?format=json&filter=2&dateStart=\(today)&dateEnd=\(today)&persona=2"
                request.url = URL(string: url)
            }
        }


        let semaphore = DispatchSemaphore.init(value: 0)
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<Dictionary<String, Any?>> {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "M/d/yyyy"
                        let tomorrow = formatter.string(from: (Date() + 1.day))
                        for items in json {
//                            Temp
                            var homework = items
                            homework["date_due"] = tomorrow
                            let dueDate = homework["date_due"] as? String
                            guard dueDate?.range(of: tomorrow) != nil else {
                                continue
                            }

                            let leadSectionId = String(homework["section_id"] as! Int)
                            if self.listHomework[leadSectionId] != nil {
                                self.listHomework[leadSectionId]?.append(homework)
                            } else {
                                self.listHomework[leadSectionId] = [homework]
                            }
                        }
                    }

                } catch {
                    NSLog("Data parsing failed")
                }
            }
            semaphore.signal()
        })

        task.resume()
        semaphore.wait()

    }

    func dayCheck() -> String {
        var dayOfSchool: String? = nil
        let date = Date()
        let formatter = DateFormatter()
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = plistPath.appending("/Day.plist")
        guard let dayDict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            return "No School"
        }
        formatter.dateFormat = "yyyyMMdd"
        let checkDate = formatter.string(from: date)

        dayOfSchool = dayDict[checkDate] ?? "No School"
        return dayOfSchool!
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {
    }

}

//Class view.
extension Main: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = (Float(screenWidth) - 30) / 2
        if screenWidth > 414 {
            width = Float(screenWidth) / Float(Int(screenWidth / 187))
        }
        let size = CGSize(width: Double(width), height: 155.0)
        return size
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        screenWidth = size.width
        classView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(self.listClasses.count)
        return self.listClasses.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "classViewCell", for: indexPath as IndexPath) as! classViewCell
        let row = indexPath.row
        let classData = listClasses[row]
        let className = classData["className"] as? String
        let teacher = classData["teacherName"] as? String
        
        cell.roomNumber.text = classData["roomNumber"] as? String ?? ""

        cell.teacher.text = teacher
        cell.className.text = className
        if row == 0 {
            cell.period.text = "CURRENT CLASS"
        } else if row == 1 {
            cell.period.text = "NEXT CLASS"
        } else if className == "Lunch" {
            cell.period.text = "LUNCH"
        } else {
            if let period = classData["period"] as? Int {
                cell.period.text = "PERIOD " + String(describing: period)
            }
        }

        cell.homeworkView.isHidden = true
        if let leadSectionId = classData["leadsectionid"] as? Int {
            print(listHomework)
            if let thisClassHomework = listHomework[String(leadSectionId)] {
                // cell.homeworkView.isHidden = false

                let numberOfHomework = thisClassHomework.count

                let numberOfCompletedHomework = thisClassHomework.filter({
                    ($0["assignment_status"] as? Int) == 1
                }).count

                let numberOfUncompletedHomework = numberOfHomework - numberOfCompletedHomework

                var homeworkButtonText = ""
                if numberOfUncompletedHomework == 0 {
                    homeworkButtonText = "All \(String(numberOfHomework)) HW were completed!"
                } else {
                    homeworkButtonText = "\(String(numberOfHomework)) uncompleted HW"
                }

                cell.homeworkButton.setTitle(homeworkButtonText, for: .normal)
            }
        }
        cell.index = classData["index"] as? Int

        return cell
    }
}

extension Main: UITableViewDelegate, UITableViewDataSource {

    func eventDataFetching() {
        self.listEvents = []
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Events.plist"
        let path = plistPath.appending(fileName)
        let eventData = NSMutableDictionary(contentsOfFile: path)
        let date = Date()
        self.formatter.dateFormat = "yyyyMMdd"
        let eventDate = formatter.string(from: date)
        guard let events = eventData?[eventDate] as? Array<Dictionary<String, Any>> else {
            return
        }

//        Add all day events first
        let allDayEvents = events.filter({ $0["isAllDay"] as? Int == 1 })
        self.listEvents += allDayEvents

        self.formatter.dateFormat = "HHmmss"
        let currentTime = Int(formatter.string(from: Date())) ?? 0

        //        Sort the event from earliest to latest
        let eventToSort = events.filter({ $0["tEnd"] as? Int ?? -1 > currentTime })
        let sortedEvents = eventToSort.sorted(by: {
            ($0["tEnd"] as? Int ?? 0) < ($1["tEnd"] as? Int ?? 0)
        })
        
        self.listEvents += sortedEvents
    }

    //    the number of the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        print(listEvents.count)
        return self.listEvents.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTableDash", for: indexPath as IndexPath) as! customEventCellDashboard
        let row = indexPath.row
        guard self.listEvents.count >= row + 1 else {
            return cell
        }
        let rowDict = self.listEvents[row]
        guard let summary = rowDict["summary"] as? String else {
            return UITableViewCell()
        }
        cell.ClassName.text = summary
//        Use the first letter as the letter on the left side of the cell
        let letter = String(describing: summary[...summary.startIndex])
        cell.PeriodNumber.text = letter

        if rowDict["location"] != nil {
            cell.RoomNumber.text = "At: " + (rowDict["location"] as! String)
        } else {
            cell.RoomNumber.text = nil
        }

        cell.PeriodTime.text = EventView().getTimeInterval(rowDict: rowDict)
        return cell
    }
}


extension Main {
    //Refresh day data and event data. Update version number.
    //刷新Day和Event数据，并更新版本号
    func refreshData() {
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(MyService.getCalendarData, completion: { result in
            switch result {
            case let .success(response):
                do {
                    guard let dayData = try response.mapJSON(failsOnEmptyData: false) as? Dictionary<String, Any> else {
                        presentErrorMessage(presentMessage: "Incorrect file format for day data", layout: .statusLine)
                        return
                    }

                    let dayFile = userDocumentPath.appending("/Day.plist")

                    print("Info: Day Data refreshed")
                    NSDictionary(dictionary: dayData).write(toFile: dayFile, atomically: true)
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }

            semaphore.signal()
        })

        semaphore.wait()
    }

    func refreshEvents() {
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(MyService.getCalendarEvent, completion: { result in
            switch result {
            case .success(_):
                print("Info: event data refreshed")
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }

            semaphore.signal()
        })

        semaphore.wait()
    }
}
