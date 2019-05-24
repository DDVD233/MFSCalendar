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
//import Reachability
import SwiftDate
 

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
}

class Main: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var classView: UICollectionView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet var classViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet var classViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var eventViewContainer: UIView!
    
    
    let formatter = DateFormatter()
    var listEvents = [[String: Any]]()
    var listClasses = [[String: Any]]()
    var listHomework = Dictionary<String, Array<Dictionary<String, Any>>>()
    var timer: Timer? = nil
//    Format: {Lead_Section_ID: [Homework]}
    var isVisible = true
    
    let eventViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier :"eventViewController") as! eventViewController

    var screenWidth = UIScreen.main.bounds.width

    override func viewDidLoad() {
        super.viewDidLoad()
        SwiftDate.defaultRegion = Region.local
        setUpUI()
        
        let preferences = Preferences()
        if preferences.firstName == nil || !preferences.didOpenAfterUpdate {
            preferences.didLogin = false
            preferences.didOpenAfterUpdate = true
        }
        
        if Preferences().didLogin && Preferences().courseInitialized {
            NSLog("Already Logged in.")
        } else {
            print("Cannot initialize data because the user did not logged in")
        }
        
//        if Reachability()?.connection == .wifi {
        DispatchQueue.global().async {
            self.updateData()
        }
//        }
        
        DispatchQueue.global().async {
            self.adaptationScheduleFix()
        }
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        isVisible = true
        
//        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidAppear(_ animated: Bool) {
        //classViewHeightConstraint.constant = classView.contentSize.height
//        eventViewLarge.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: eventViewLarge.frame, andColors: [UIColor(hexString: 0xFF6666), UIColor(hexString: 0xFF9966)])
        guard Preferences().didLogin else {
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "ftController")
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
            if self.doRefreshData() {
                NSLog("Refresh Data")
                DispatchQueue.main.async {
                    self.presentCourseFillView()
                }
            } else {
                NSLog("No refresh, version: %@", String(describing: Preferences().version))
            }
        }
        
        let notification = NotificationCenter.default
        notification.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.current, using: { _ in
            self.stopTimer()
        })
        
        presentAdIfNeeded()
        
        startTimer()
    }
    
    func setUpUI() {
        self.bottomView.layer.shadowColor = UIColor.black.cgColor
        self.bottomView.layer.shadowOpacity = 0.15
        self.bottomView.layer.shadowOffset = CGSize.zero
        self.bottomView.layer.shadowRadius = 15
        
        self.classView.delegate = self
        self.classView.dataSource = self
        self.classView.emptyDataSetSource = self
        self.classView.emptyDataSetDelegate = self
        
        self.addChild(eventViewController)
        self.eventViewContainer.addSubview(eventViewController.view)
        eventViewController.view.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        eventViewController.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func presentAdIfNeeded() {
        let presentationDate = "2018-11-30 12:56:00".toDate()!
        if Date().isBeforeDate(presentationDate.date, granularity: .minute) &&
            !Preferences().didPresentCapstoneAd {
            let adVC = self.storyboard!.instantiateViewController(withIdentifier: "adVC")
            self.present(adVC, animated: true, completion: nil)
        }
    }
    
    func adaptationScheduleFix() {
        let preferences = Preferences()
        if preferences.dataBuild < 1600 {
            preferences.dataBuild = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") ?? 0
            LoginView().getProfile()
            DispatchQueue.main.async {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "courseFillController")
                self.present(vc!, animated: true, completion: nil)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.setNavigationBarHidden(false, animated: false)
        isVisible = false
        stopTimer()
    }

    func updateData() {
        let group = DispatchGroup()

        DispatchQueue.global().async(group: group, execute: {
            NetworkOperations().refreshEvents()
        })
        
        if Preferences().schoolName ?? "" == "MFS" {
            DispatchQueue.global().async(group: group, execute: {
                self.refreshData()
            })
        }

        group.wait()
        
        DispatchQueue.main.async {
            self.refreshDisplayedData()
        }
        
        DispatchQueue.global().async {
            ClassView().getProfilePhoto()
        }
        
        DispatchQueue.global().async {
            self.updatePhotoLink()
        }
        
        DispatchQueue.global().async {
            NetworkOperations().downloadLargeProfilePhoto()
        }
        
        DispatchQueue.global().async {
            NetworkOperations().downloadQuarterScheduleFromMySchool {
                print("Downloaded Schedule From mySchool")
            }
        }
        
        if Preferences().isInStepChallenge {
            DispatchQueue.global().async {
                StepChallenge().reportSteps()
            }
        }
    }
    
    func updatePhotoLink() {
        guard let token = Preferences().token else { return }
        guard let userID = Preferences().userID else { return }
        
        provider.request(MyService.getProfile(userID: userID, token: token), callbackQueue: DispatchQueue.global(), completion: { result in
            switch result {
            case let .success(response):
                do {
                    guard let resDict = try response.mapJSON() as? Dictionary<String, Any?> else {
                        presentErrorMessage(presentMessage: "Internal error: incorrect file format.", layout: .cardView)
                        return
                    }
                    
                    print(resDict)
                    
                    guard resDict["Error"] == nil else {
                        //                        When error occured.
                        print("Login Error!")
                        if (resDict["ErrorType"] as! String) == "UNAUTHORIZED_ACCESS" {
                            DispatchQueue.main.async {
                                presentErrorMessage(presentMessage: "The username/password is incorrect. Please check your spelling.", layout: .cardView)
                            }
                        }
                        
                        return
                    }
                    
                    if let photo = resDict["ProfilePhoto"] as? NSDictionary {
                        if let photolink = photo["ThumbFilenameUrl"] as? String {
                            Preferences().photoLink = photolink
                            print(photolink)
                        }
                        
                        let largePhotoLink = photo["LargeFilenameUrl"] as? String
                        userDefaults.set(largePhotoLink, forKey: "largePhotoLink")
                    }
                } catch {
                    NSLog("Data parsing failed")
                    DispatchQueue.main.async {
                        presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                    }
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
            }
        })
    }
    
    func presentCourseFillView() {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "courseFillController") {
            self.present(vc, animated: true, completion: nil)
        } else {
            presentErrorMessage(presentMessage: "Cannot find course fill page", layout: .statusLine)
        }
    }
    
    
    func startTimer(){
        if timer == nil {
            if #available(iOS 10.0, *) {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                    DispatchQueue.main.async {
                        self.refreshDisplayedData()
                    }
                })
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    func stopTimer() {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }

    func refreshDisplayedData() {
//        if !isViewLoaded || (view.window == nil) {
//            stopTimer()
//        }
        
        getListClasses()
        setupTheHeader()

        DispatchQueue.main.async {
            self.classView.reloadData()
            self.eventDataFetching()
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

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String? = ""
        let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)]
        str = "No more classes for today!"

        return NSAttributedString(string: str!, attributes: attrs)
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        var image: UIImage? = nil
        if scrollView == classView {
            image = UIImage(named: "Achievement.png")?.imageResize(sizeChange: CGSize(width: 120, height: 93.3))
        }
        return image
    }

    func doRefreshData() -> Bool {
        if Preferences().currentQuarter == 0 {
            Preferences().doUpdateQuarter = true
            return true
        }

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
        let day = school.checkDate(checkDate: Date())
        
        DispatchQueue.main.async {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d."
            //MMMM d, yyyy
            var today = formatter.string(from: date)
            let labelAttributes = [NSAttributedString.Key.font:
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
            
            self.welcomeLabel.text = "Welcome back, \(Preferences().firstName ?? "") !"
            
            self.dateLabel.text = today
        }

    }

    func getListClasses() {
        self.listClasses = school.classesOnADayAfter(date: Date())
    }
    
    func eventDataFetching() {
        let selectedDate = Date()
        eventViewController.selectedDate = selectedDate
        eventViewController.eventDataFetching()
    }

    func getHomework() {
        self.listHomework = [String: Array<Dictionary<String, Any>>]()

        guard let username = Preferences().username else {
            return
        }
        var request = URLRequest(url: URL(string: "https://mfs-calendar.appspot.com/assignmentlist/")!)

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
                let url = Preferences().baseURL + "/api/DataDirect/AssignmentCenterAssignments/?format=json&filter=2&dateStart=\(today)&dateEnd=\(today)&persona=2"
                request.url = URL(string: url)
            }
        }


        let semaphore = DispatchSemaphore.init(value: 0)
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<Dictionary<String, Any>> {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "M/d/yyyy"
                        let tomorrow = formatter.string(from: (Date() + 1.days))
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
        let teacher = classData["teacherName"] as? String ?? ""
        
        cell.roomNumber.text = classData["roomNumber"] as? String ?? ""

        cell.teacher.text = teacher
        cell.className.text = className
        
        if row == 0 || row == 1 {
            cell.period.text = school.periodTimerString(time: Date(), index: row)
        } else {
            cell.period.text = school.meetTimeForPeriod(periodObject: classData)
        }

//        if let leadSectionId = ClassView().getLeadSectionID(classDict: classData) {
//            print(listHomework)
//            if let thisClassHomework = listHomework[String(leadSectionId)] {
//                // cell.homeworkView.isHidden = false
//
//                let numberOfHomework = thisClassHomework.count
//
//                let numberOfCompletedHomework = thisClassHomework.filter({
//                    ($0["assignment_status"] as? Int) == 1
//                }).count
//
//                let numberOfUncompletedHomework = numberOfHomework - numberOfCompletedHomework
//
//                var homeworkButtonText = ""
//                if numberOfUncompletedHomework == 0 {
//                    homeworkButtonText = "All \(String(numberOfHomework)) HW were completed!"
//                } else {
//                    homeworkButtonText = "\(String(numberOfHomework)) uncompleted HW"
//                }
//
//                cell.homeworkButton.setTitle(homeworkButtonText, for: .normal)
//            }
//        }
        cell.index = classData["index"] as? Int

        return cell
    }
}


extension Main {
    //Refresh day data and event data. Update version number.
    //刷新Day和Event数据，并更新版本号
    // @Legacy This is only for NetClassroom System. 
    func refreshData() {
        guard Preferences().schoolName == "MFS" else { return }
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(MyService.getCalendarData, completion: { result in
            switch result {
            case let .success(response):
                do {
                    guard let dayData = try response.mapJSON(failsOnEmptyData: false) as? Dictionary<String, Any> else {
                        presentErrorMessage(presentMessage: "Incorrect file format for day data", layout: .statusLine)
                        return
                    }

                    let dayFile = FileList.day.filePath

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
}
