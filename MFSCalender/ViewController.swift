    //
//  ViewController.swift
//  MFSCalender
//
//  Created by 戴元平 on 2016/12/1.
//  Copyright © 2016年 David. All rights reserved.
//

import UIKit
import SwiftMessages
import UserNotifications
import DZNEmptyDataSet

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
    @IBOutlet weak var period: UILabel!
    
    @IBOutlet weak var className: UILabel!
    
    @IBOutlet weak var teacher: UILabel!
    
    @IBOutlet weak var roomNumber: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
    
    let formatter = DateFormatter()
    var listEvents:NSMutableArray = []
    var listClasses:NSMutableArray = []
    

    let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bottomView.layer.shadowColor = UIColor.black.cgColor
        self.bottomView.layer.shadowOpacity = 0.15
        self.bottomView.layer.shadowOffset = CGSize.zero
        self.bottomView.layer.shadowRadius = 15
//        Could Crash?
        if userDefaults?.bool(forKey: "dataInitialized") != true {
            dataCheck(fileName: "ClassA", format: "array")
            dataCheck(fileName: "ClassB", format: "array")
            dataCheck(fileName: "ClassC", format: "array")
            dataCheck(fileName: "ClassD", format: "array")
            dataCheck(fileName: "ClassE", format: "array")
            dataCheck(fileName: "ClassF", format: "array")
            dataCheck(fileName: "Day", format: "dictionary")
            dataCheck(fileName: "Events", format: "dictionary")
            userDefaults?.set(true, forKey: "dataInitialized")
        } else {
            NSLog("Data already initialized")
            if userDefaults?.object(forKey: "firstName") == nil {
                userDefaults?.set(false, forKey: "didLogin")
            }
            if (userDefaults?.bool(forKey: "didLogin") == true) && (userDefaults?.bool(forKey: "courseInitialized") == true) {
                eventDataFetching()
                periodCheck(day: dayCheck())
                NSLog("Already Logged in.")
                setupTheHeader()
            } else {
                print("Not logged in")
            }
        }
        self.classView.delegate = self
        self.classView.dataSource = self
        self.classView.emptyDataSetSource = self
        self.classView.emptyDataSetDelegate = self
        self.eventView.delegate = self
        self.eventView.dataSource = self
        self.eventView.emptyDataSetDelegate = self
        self.eventView.emptyDataSetSource = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str:String? = ""
        var attrs:[String:Any] = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        if scrollView == classView {
            str = "No more classes for today!"
        } else if scrollView == eventView {
            self.eventView.separatorStyle = .none
            str = "No more events for today!"
            attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), NSForegroundColorAttributeName: UIColor.white]
        }
        
        return NSAttributedString(string: str!, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        var image:UIImage? = nil
        if scrollView == classView {
            image = UIImage(named: "Achievement.png")?.imageResize(sizeChange: CGSize(width: 120, height: 93.3))
        } else if scrollView == eventView {
            image = UIImage(named: "bell.png")?.imageResize(sizeChange: CGSize(width: 80, height: 80))
        }
        return image
    }

    override func viewDidAppear(_ animated: Bool) {
        let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")
        if userDefaults?.bool(forKey: "didLogin") != true {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ftController") as! firstTimeLaunchController
            self.present(vc, animated: true, completion: nil)
        } else if userDefaults?.bool(forKey: "courseInitialized") != true {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "courseFillController")
            self.present(vc!, animated: true, completion: nil)
        } else {
            self.eventView.separatorStyle = .singleLine
            eventDataFetching()
            periodCheck(day: dayCheck())
            NSLog("Already Logged in.")
            setupTheHeader()
            DispatchQueue.global().async {
                if self.doRefreshData() {
                    NSLog("Refresh Data")
                    if self.refreshData() && self.refreshEvents() {
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: "courseFillController")
                        self.present(vc!, animated: true, completion: nil)
                        DispatchQueue.main.sync {
                            self.setupTheHeader()
                        }
                    }
                } else {
                    NSLog("No refresh, version: %@", String(describing: self.userDefaults?.integer(forKey: "version")))
                }
            }
        }
    }

    func doRefreshData() -> Bool {
        let version = self.userDefaults?.integer(forKey: "version")
        var refresh = false
        let semaphore = DispatchSemaphore.init(value: 0)
        let dayCheckURL = "https://dwei.org/dataversion"
        let url = NSURL(string: dayCheckURL)
        let request = URLRequest(url: url! as URL)
        let session = URLSession.shared

        if version == nil {
            refresh = true
        } else {
            let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                NSLog("Done")

                if error == nil {
                    guard let nversion = String(data: data!, encoding: .utf8) else {
                        return
                    }
                    let newVersion = Int(nversion)
                    print("Latest version:", newVersion ?? "ERROR")
                    if newVersion! != version! {
                        refresh = true
                    }
                } else {
                    DispatchQueue.main.async {
                        //                    setup alert here
                        let presentMessage = (error?.localizedDescription)!
                        let view = MessageView.viewFromNib(layout: .StatusLine)
                        view.configureTheme(.error)
                        view.configureContent(body: presentMessage)
                        var config = SwiftMessages.Config()
                        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
                        config.preferredStatusBarStyle = .lightContent
                        SwiftMessages.show(config: config, view: view)
                    }
                    NSLog("error: %@", error!.localizedDescription)
                }
                semaphore.signal()
            })

            task.resume()
            semaphore.wait()
        }
        return refresh
    }

    

    func setupTheHeader() {
        let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")
        let day = dayCheck()
        var dayText: String? = nil
        let date = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy."
        let today = formatter.string(from: date as Date)
        if day == "No School" {
            dayLabel.text = "No school today,"
        } else {
            dayText = day + " Day"
            dayLabel.text = "Today is " + dayText! + ","
        }
        welcomeLabel.text = "Welcome back, " + (userDefaults?.string(forKey: "firstName"))! + "!"
        dateLabel.text = today

    }

    func periodCheck(day: String) {
        print("Excuted")
//        初始化，否则会加两遍
        self.listClasses = []
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + day + ".plist"
        let path = plistPath.appending(fileName)

        if NSMutableArray(contentsOfFile: path) != nil {
            let allClasses = NSMutableArray(contentsOfFile: path)!
            let date = NSDate()
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HHmm"
            let Now = Int(timeFormatter.string(from: date as Date) as String)
            print(date)
            NSLog(String(describing: Now))


            // I am going to rewrite this.
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

            switch Now! {
            case 0..<Period1Start:
                NSLog("Period 0")
                currentClass = 0
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
                NSLog("Have a great afternoon!")
                currentClass = 9
            default:
                NSLog("???")
            }
            if currentClass! < 9 {
                for number in currentClass!...8 {
                    if number == 6 {
                        for items in allClasses {
                            let rowDict = items as! NSDictionary
                            let period = Int(rowDict["period"] as! String)
                            if period == number {
                                let name = rowDict["name"] as? String
                                let room = rowDict["room"] as? String
                                let teacher = rowDict["teacherName"] as? String
                                let addData: NSDictionary = ["name": name ?? "", "roomNumber": room ?? "", "teacher": teacher ?? "", "period": String(describing:period!)]
                                self.listClasses.add(addData)
                            }
                        }
                        let addData: NSDictionary = ["name": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": "11"]
                        self.listClasses.add(addData)
                    } else {
                        for items in allClasses {
                            let rowDict = items as! NSDictionary
                            let period = Int(rowDict["period"] as! String)
                            if period == number {
                                let name = rowDict["name"] as? String
                                let room = rowDict["room"] as? String
                                let teacher = rowDict["teacherName"] as? String
                                let addData: NSDictionary = ["name": name ?? "", "roomNumber": room ?? "", "teacher": teacher ?? "", "period": String(describing:period!)]
                                self.listClasses.add(addData)
                            }
                        }
                    }
                }
            } else if currentClass == 11 {
                let addData: NSDictionary = ["name": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": "5"]
                self.listClasses.add(addData)
                for number in 7...8 {
                    for items in allClasses {
                        let rowDict = items as! NSDictionary
                        let period = Int(rowDict["period"] as! String)
                        if period == number {
                            let name = rowDict["name"] as? String
                            let room = rowDict["room"] as? String
                            let teacher = rowDict["teacherName"] as? String
                            let addData: NSDictionary = ["name": name ?? "", "roomNumber": room ?? "", "teacher": teacher ?? "", "period": String(describing:period!)]
                            self.listClasses.add(addData)
                        }
                    }
                }
            }
            self.classView.reloadData()
            print(listClasses)
        } else {
        }
    }


    func dataCheck(fileName: String, format: String) {
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        //let plistPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let filePathName = "/" + fileName + ".plist"
        let path = plistPath.appending(filePathName)
        let fileManager = FileManager.default
        var bundle: String? = nil
        if (!(fileManager.fileExists(atPath: path))) {
            if format == "array" {
                bundle = Bundle.main.path(forResource: "BlankArray", ofType: "plist")!
            } else {
                bundle = Bundle.main.path(forResource: "BlankDictionary", ofType: "plist")!
            }
            NSLog("Creating File..." + fileName)
            do {
                try fileManager.copyItem(atPath: bundle!, toPath: path)
            } catch {
                NSLog("Error!")
            }
        }

    }

    func dayCheck() -> String {
        var dayOfSchool: String? = nil
        let date = NSDate()
        let formatter = DateFormatter()
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = plistPath.appending("/Day.plist")
        let dayDict = NSDictionary(contentsOfFile: path)
        formatter.dateFormat = "yyyyMMdd"
        let checkDate = formatter.string(from: date as Date)

        if dayDict?[checkDate] == nil {
            dayOfSchool = "No School"
        } else {
            dayOfSchool = dayDict?[checkDate] as? String
        }
        return dayOfSchool!
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {
    }

}

extension Main: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (Float(UIScreen.main.bounds.size.width) - 40) / 2
        let size = CGSize(width: Double(width), height: 151.0)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(self.listClasses.count)
        return self.listClasses.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "classViewCell", for: indexPath as IndexPath) as! classViewCell
        let row = indexPath.row
        let classData = listClasses[row] as! NSDictionary
        let className = classData["name"] as? String
        let roomNumber = classData["roomNumber"] as? String
        let teacher = classData["teacher"] as? String
        let period = classData["period"] as! String
        if !((roomNumber?.isEmpty)!) {
            cell.roomNumber.text = "AT: " + roomNumber!
        } else {
            cell.roomNumber.text = nil
        }
        cell.teacher.text = teacher
        cell.className.text = className
        if row == 0 {
            cell.period.text = "CURRENT CLASS"
        } else if row == 1 {
            cell.period.text = "NEXT CLASS"
        } else if className == "Lunch" {
            cell.period.text = "LUNCH"
        } else {
            cell.period.text = "PERIOD " + period
        }
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
        let date = NSDate()
        self.formatter.dateFormat = "yyyyMMdd"
        let eventDate = formatter.string(from: date as Date)
        guard let events = eventData?[eventDate] as? NSMutableArray else {
            self.eventView.reloadData()
            return
        }
        
//        排序Events
        self.formatter.dateFormat = "HHmmss"
        let currentTime = Int(formatter.string(from: Date()))
        var eventToSort: [NSMutableDictionary] = []
//        先加上All Day的， 然后将其余还未结束的加入eventToSort进行排序
        for items in events {
            let event = items as! NSMutableDictionary
            if (event["isAllDay"] as? Int) == 1 {
                self.listEvents.add(event)
            } else {
                let rowDict = items as! NSDictionary
                if let tEnd = rowDict["tEnd"] as? Int {
                    if tEnd > currentTime! {
                        event["tEnd"] = tEnd
                        eventToSort.append(event)
                    }
                }
            }
        }
        
        let sortedEvents = eventToSort.sorted(by: {
            ($0["tEnd"] as! Int) < ($1["tEnd"] as! Int)
        })
        
        for items in sortedEvents {
            self.listEvents.add(items)
        }
        self.eventView.reloadData()
    }
    
    //    the number of the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
            return self.listEvents.count
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "eventTableDash", for: indexPath as IndexPath) as? customEventCellDashboard
            let row = indexPath.row
            let rowDict = self.listEvents[row] as! NSDictionary
            let summary = rowDict["summary"] as? String
            cell?.ClassName.text = summary
//        截取第一个字母
            let letter = summary?.substring(to: (summary?.index(after: (summary?.startIndex)!))!)
            cell?.PeriodNumber.text = letter!
            if rowDict["location"] != nil {
                cell?.RoomNumber.text = "At: " + (rowDict["location"] as! String)
            } else {
                cell?.RoomNumber.text = nil
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
//        }
    }
}



extension Main {
    //refresh data function
    //刷新Day和Event数据，并更新版本号
    func refreshData() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)
        let dayCheckURL = "https://dwei.org/data"
        let url = NSURL(string: dayCheckURL)
        let request = URLRequest(url: url! as URL)
        let session = URLSession.shared
        
//        检查Day数据
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            NSLog("Done")
            
            if error == nil {
                do {
                    let resDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                    let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                    let path = plistPath.appending("/Day.plist")
                    resDict.write(toFile: path, atomically: true)
                    print(resDict)
                    success = true
                    NSLog("Day Data refreshed.")
                } catch {
                    NSLog("Data parsing failed")
                }
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)!
                    let view = MessageView.viewFromNib(layout: .StatusLine)
                    view.configureTheme(.error)
                    view.configureContent(body: presentMessage)
                    var config = SwiftMessages.Config()
                    config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
                    config.preferredStatusBarStyle = .lightContent
                    SwiftMessages.show(config: config, view: view)
                }
                NSLog("error: %@", error!.localizedDescription)
                NSLog("最外层的错误")
            }
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        
        return success
    }
    
    func refreshEvents() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)
        let downloadLink = "https://dwei.org/events.plist"
        let url = NSURL(string: downloadLink)
        let request = URLRequest(url: url! as URL)
        let session = URLSession.shared
        //create request.
        let downloadTask = session.downloadTask(with: request, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                //Temp location:
                print("location:\(String(describing: location))")
                let locationPath = location!.path
                //Copy to User Directory
                let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = photoPath.appending("/Events.plist")
                //Init FileManager
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path) {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        NSLog("File does not exist! (Which is impossible)")
                    }
                }
                try! fileManager.moveItem(atPath: locationPath, toPath: path)
                print("new location:\(path)")
                success = true
                NSLog("Day Data refreshed.")
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)!
                    let view = MessageView.viewFromNib(layout: .StatusLine)
                    view.configureTheme(.error)
                    view.configureContent(body: presentMessage)
                    var config = SwiftMessages.Config()
                    config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
                    config.preferredStatusBarStyle = .lightContent
                    SwiftMessages.show(config: config, view: view)
                }
                NSLog("error: %@", error!.localizedDescription)
                NSLog("最外层的错误")
            }
            semaphore.signal()
        })
        //使用resume方法启动任务
        downloadTask.resume()
        semaphore.wait()
        
        return success
    }
}

class ClassSchedule: UIViewController {

    let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }

    @IBAction func aDayButton(_ sender: Any) {
        userDefaults?.set("A", forKey: "daySelect")
    }

    @IBAction func bDayButton(_ sender: Any) {
        userDefaults?.set("B", forKey: "daySelect")
    }

    @IBAction func cDayButton(_ sender: Any) {
        userDefaults?.set("C", forKey: "daySelect")
    }

    @IBAction func eDayButton(_ sender: Any) {
        userDefaults?.set("E", forKey: "daySelect")
    }

    @IBAction func dDayButton(_ sender: Any) {
        userDefaults?.set("D", forKey: "daySelect")
    }


    @IBAction func fDayButton(_ sender: Any) {
        userDefaults?.set("F", forKey: "daySelect")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {

    }

}











