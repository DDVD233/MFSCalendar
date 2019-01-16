//
//  HomeworkViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/14.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import SwiftMessages
import SwiftyJSON
import M13Checkbox
import SwiftDate
import DZNEmptyDataSet
import DGElasticPullToRefresh
import XLPagerTabStrip
import Alamofire
import Crashlytics
import M13ProgressSuite
import ChameleonFramework
import StoreKit


class homeworkViewController: UITableViewController, UIViewControllerPreviewingDelegate, IndicatorInfoProvider, UIDocumentPickerDelegate {

    @IBOutlet weak var homeworkTable: UITableView!
    var isUpdatingHomework = false

    var listHomework = Dictionary<String, Array<Dictionary<String, Any>>>()
    // Format: Key: "The date homework is due" Value: The List of homework record(A dict) on that day
    var daySelected: Date? = Date()
    var filter = 2
    var sections: [String] {
        return Array(self.listHomework.keys).sorted()
    }

    let formatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        homeworkTable.rowHeight = UITableView.automaticDimension
        homeworkTable.estimatedRowHeight = 80
        homeworkTable.emptyDataSetSource = self
        homeworkTable.emptyDataSetDelegate = self
        homeworkTable.delegate = self


//        Remove the bottom 1px line on Navigation Bar
//
        
        if filter == 2 {
            let loadingview = DGElasticPullToRefreshLoadingViewCircle()
            loadingview.tintColor = UIColor.white
            homeworkTable.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
                self?.getHomework()
                self?.tableView.dg_stopLoading()
                }, loadingView: loadingview)
            homeworkTable.dg_setPullToRefreshFillColor(UIColor(hexString: 0xFF7E79))
            homeworkTable.dg_setPullToRefreshBackgroundColor(tableView.backgroundColor!)
        }
        
        if #available(iOS 11.0, *) {
            setLargeTitle(on: self)
        } else {
            if let navigationBar = self.navigationController?.navigationBar {
                navigationBar.removeBottomLine()
            }
        }
        
        if #available(iOS 9.0, *) {
            if self.traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: homeworkTable)
            }
        }

    }

    override func viewDidAppear(_ animated: Bool) {
        if filter == 2 {
            daySelected = Date()
        }
        DispatchQueue.global().async {
            self.getHomework()
        }
    }

    func errorMessage(presentMessage: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.error)
        var icon: String? = nil
        if presentMessage == "The username/password is incorrect. Please check your spelling." {
            icon = "🤔"
        } else {
            icon = "😱"
        }
        view.configureContent(title: "Error!", body: presentMessage, iconText: icon!)
        view.button?.isHidden = true
        let config = SwiftMessages.Config()
        SwiftMessages.show(config: config, view: view)
    }

    func getHomework() {
        guard daySelected != nil else {
            return
        }
        
        isUpdatingHomework = true
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.navigationController?.showProgress()
            self.navigationController?.setPrimaryColor(UIColor(hexString: 0xFF7E79))
            self.navigationController?.setSecondaryColor(UIColor.white)
            self.navigationController?.setIndeterminate(true)
            self.tableView.reloadEmptyDataSet()
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession.init(configuration: config)
        guard loginAuthentication().success else {
            return
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "M/d/yyyy"
        let daySelectedString = formatter.string(from: daySelected!).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let dayEndString = filter == 2 ? formatter.string(from: daySelected! + 1.months).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! : daySelectedString
        let url = Preferences().baseURL + "/api/DataDirect/AssignmentCenterAssignments/?format=json&filter=\(String(describing: filter))&dateStart=\(daySelectedString)&dateEnd=\(dayEndString)&persona=2"
        let request = URLRequest(url: URL(string: url)!)
        
        var originalData = [[String:Any]]()
        let semaphore = DispatchSemaphore.init(value: 0)
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] {
                        originalData = json
                    }

                } catch {
                    NSLog("Data parsing failed")
                    DispatchQueue.main.async {
                        let presentMessage = "The server is not returning the right data. Please contact David."
                        self.errorMessage(presentMessage: presentMessage)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }
            semaphore.signal()
        })

        task.resume()
        semaphore.wait()
        manageDate(originalData: originalData)

        DispatchQueue.main.async {
            self.isUpdatingHomework = false
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.navigationController?.cancelProgress()
            self.tableView.reloadData()
        }
        
        Answers.logContentView(withName: "Homework", contentType: "Homework", contentId: "1", customAttributes: nil)
        
        requestReviewIfNeeded()
    }
    
    func requestReviewIfNeeded() {
        let presentationDate = DateInRegion(components: {
            $0.year = 2018
            $0.month = 12
            $0.day = 1
            $0.hour = 12
            $0.minute = 0
        })
        
        if (Preferences().reviewDate == nil) && DateInRegion().isBeforeDate(presentationDate!, granularity: .day) {
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                Preferences().reviewDate = Date()
            }
        }
    }

    func manageDate(originalData: [[String: Any]]) {
        var managedHomework = [String: [[String: Any]]]()
//        Format: [DateDue(YearMonthDay): Array<HomeworkBelongToThatSection>]
        for homework in originalData {
            guard let dueDateData = homework["date_due"] as? String else {
                return
            }
            formatter.dateFormat = "M/d/yyyy hh:mm a"
            formatter.locale = Locale(identifier: "en_US")
            let dueDate = formatter.date(from: dueDateData)
            formatter.locale = Locale.current
            formatter.dateFormat = "yyyyMMdd"
            if dueDate != nil {
                let dueDateMDString = formatter.string(from: dueDate!)
                var homeworkArray = managedHomework[dueDateMDString]
                if homeworkArray == nil {
                    homeworkArray = []
                }
                homeworkArray?.append(homework)
                managedHomework[dueDateMDString] = homeworkArray
            } else {
                print("No duedate is found")
            }
        }

        self.listHomework = managedHomework
        //print("[test]" + String(describing: self.listHomework))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let homeworkInSection = self.listHomework[sections[section]] else {
            return 0
        }
        return homeworkInSection.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.listHomework.count
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 20 {
            self.navigationItem.title = "Homework"
        } else if let indexPath = tableView.indexPathsForVisibleRows?.first {
            let dateString = stringForHeaderInSection(section: indexPath.section)
            self.navigationItem.title = dateString
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0{
            changeTabBar(hidden: true, animated: true)
        }
        else{
            changeTabBar(hidden: false, animated: true)
        }
    }
    
    func changeTabBar(hidden:Bool, animated: Bool){
//        guard var tabBar = self.tabBarController?.tabBar else { return }
//        if tabBar.isHidden == hidden{ return }
//        let frame = tabBar.frame
//        let offset = (hidden ? frame.size.height : -frame.size.height)
//        let duration:TimeInterval = (animated ? 0.5 : 0.0)
//        tabBar.isHidden = false
//        UIView.animate(withDuration: duration,
//                                   animations: {tabBar.frame = CGRectOffset(frame, 0, offset)
//                                    CGRectOffS
//        },
//                                   completion: {
//                                    print($0)
//                                    if $0 {tabBar?.hidden = hidden}
//        })
    }

    
    func stringForHeaderInSection(section: Int) -> String {
        guard sections.count >= section + 1 else {
            return ""
        }
        
        let dueDateMDString = self.sections[section]
        formatter.dateFormat = "yyyyMMdd"
        guard let dueDate = formatter.date(from: dueDateMDString) else {
            return ""
        }
        
        if dueDate.isToday {
            return "Today"
        } else if dueDate.isTomorrow {
            return "Tomorrow"
        } else if dueDate.isBeforeDate(Date().dateAt(.endOfWeek), granularity: .day) {
            let weekDay = dueDate.toString(.custom("EEEE"))
            return "This " + weekDay
        } else if dueDate.isBeforeDate((Date() + 1.weeks).dateAt(.endOfWeek), granularity: .day) {
            let weekDay = dueDate.toString(.custom("EEEE"))
            return "Next " + weekDay
        } else {
            return dueDate.toString(.custom("EEEE, MMM d, yyyy"))
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard filter == 2 else { return nil }
        let headerView = tableView.dequeueReusableCell(withIdentifier: "homeworkTableHeader") as! homeworkTableHeader

        let dateString = stringForHeaderInSection(section: section)
        headerView.titleLabel.text = dateString
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if filter == 2 {
            return 44
        } else {
            return 0
        }
    }
    
    func detailViewControllerOf(indexPath: IndexPath) -> UIViewController? {
        guard let homework = dataForCell(at: indexPath) else {
            return nil
        }
        
        guard let assignmentIndexID = homework["assignment_index_id"] as? Int, let assignmentID = homework["assignment_id"] as? Int else {
            return nil
        }
        
        Preferences().indexIdForAssignmentToPresent = assignmentIndexID
        Preferences().idForAssignmentToPresent = assignmentID
        
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "homeworkDetailViewController") else {
            return nil
        }
        
        return viewController
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let viewController = detailViewControllerOf(indexPath: indexPath) {
            show(viewController, sender: self)
        }
    }
    
    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = homeworkTable.indexPathForRow(at: location) else {
            return nil
        }
        
        if let cell = homeworkTable.cellForRow(at: indexPath) {
            previewingContext.sourceRect = cell.frame
        }
        
        if let viewController = detailViewControllerOf(indexPath: indexPath) {
            return viewController
        } else {
            return nil
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    func dataForCell(at indexPath: IndexPath) -> [String: Any]? {
        guard sections.count >= indexPath.section + 1 else {
            return nil
        }
        let sectionHeader = sections[indexPath.section]
        
        guard let homeworkInSection = self.listHomework[sectionHeader] else {
            return nil
        }
        
        guard homeworkInSection.count >= indexPath.row + 1 else {
            return nil
        }
        let homework = homeworkInSection[indexPath.row]
        
        return homework
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeworkViewCell", for: indexPath) as! homeworkViewCell
        guard let homework = dataForCell(at: indexPath) else {
            return cell
        }
        
        if let assignmentIndexId = homework["assignment_index_id"] as? Int {
            cell.assignmentIndexId = String(describing: assignmentIndexId)
        }
        
        if let description = homework["short_description"] as? String {
            if let attributedString = description.convertToHtml() {
                cell.shortDescription.attributedText = attributedString
            } else {
                cell.shortDescription.text = description
            }
        } else {
            cell.shortDescription.text = ""
        }

        cell.shortDescription.sizeToFit()
        cell.layoutIfNeeded()

        cell.homeworkClass.text = homework["groupname"] as? String

        let homeworkType = homework["assignment_type"] as? String ?? "N/A"
        if homeworkType.isEmpty {
            cell.tagView.isHidden = true
        } else {
            cell.tagView.isHidden = false
            cell.homeworkType.text = homeworkType
        }

        cell.tagView.backgroundColor = HomeworkView().colorForTheType(type: homeworkType)

        if let status = homework["assignment_status"] as? Int {
            let checkState = HomeworkView().checkStateFor(status: status)
            cell.checkMark.setCheckState(checkState, animated: false)
        }
        
        if cell.checkMark.checkState == .unchecked && homework["drop_box_ind"] as? Bool == true {
            cell.checkMark.isHidden = true
            cell.submitButton.isHidden = false
        } else {
            cell.checkMark.isHidden = false
            cell.submitButton.isHidden = true
        }
        
        if homework["has_grade"] as? Bool == true {
            cell.checkMark.setCheckState(.checked, animated: false)
            cell.checkMark.isEnabled = false
        }
        
//        if (homework["long_description"] as? String).existsAndNotEmpty() {
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        cell.shortDescription.isSelectable = false
//        } else {
//            cell.selectionStyle = .none
//            cell.accessoryType = .none
//            cell.shortDescription.isSelectable = true
//        }

        cell.checkMark.tintColor = cell.tagView.backgroundColor
        
        return cell
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Homework")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("picked")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Cancelled")
    }
}

extension homeworkViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "No_homework.png")?.imageResize(sizeChange: CGSize(width: 95, height: 95))
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)]

        var str = "There is no homework to display."
        if isUpdatingHomework {
            str = "Updating homework..."
        }
        return NSAttributedString(string: str, attributes: attr)
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        if isUpdatingHomework {
            return NSAttributedString()
        }

        let buttonTitleString = NSAttributedString(string: "Refresh...", attributes: [NSAttributedString.Key.foregroundColor: UIColor(hexString: 0xFF7E79)])

        return buttonTitleString
    }
}

extension homeworkViewController: DZNEmptyDataSetDelegate {
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        DispatchQueue.global().async {
            self.getHomework()
        }
    }
}

class homeworkViewCell: UITableViewCell {
    @IBOutlet weak var checkMark: M13Checkbox!
    @IBOutlet weak var homeworkType: UILabel!
    @IBOutlet weak var homeworkClass: UILabel!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var shortDescription: UITextView!

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var assignmentIndexId: String?

    override func awakeFromNib() {
        checkMark.stateChangeAnimation = .bounce(.fill)
        checkMark.boxLineWidth = 3
        checkMark.addTarget(self, action: #selector(checkDidChange), for: UIControl.Event.valueChanged)
        activityIndicator.isHidden = true
        let shortDescriptionString = shortDescription.attributedText.string
        
        if shortDescriptionString.contains("http://") || shortDescriptionString.contains("https://") {
            shortDescription.isUserInteractionEnabled = true
        } else {
            shortDescription.isUserInteractionEnabled = false
        }
    }
    
    @IBAction func submit(_ sender: Any) {
        presentErrorMessage(presentMessage: "Sorry, this isn't ready. I'm still working on that.", layout: .cardView)
        return
//        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.content"], in: .import)
//        documentPicker.delegate = self
//        parentViewController!.present(documentPicker, animated: true, completion: nil)
    }
    
//    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//        print("cancelled")
//    }
//
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        guard loginAuthentication().success else {
//            return
//        }
//        let fileURL = urls[0]
//        let queue = DispatchQueue.global()
//        Alamofire.upload(fileURL, to: "https://mfriends.myschoolapp.com/app/utilities/FileTransferHandler.ashx").responseJSON(queue: queue, options: .allowFragments, completionHandler: { response in
//            if let jsonList = response.result.value as? [[String: Any]] {
//                print(response.result.value ?? "None")
//                print(jsonList)
//                guard !jsonList.isEmpty else {
//                    return
//                }
//                let json = jsonList[0]
//                self.confirmSubmission(json: json)
//            }
//        })
//    }
    
//    func confirmSubmission(json: [String: Any]) {
//        let studentId = loginAuthentication().userId
//        guard let name = json["name"] as? String, let originalName = json["original_name"] as? String, let size = json["size"] as? Int else {
//            return
//        }
//        let parameters = ["StudentUserId": studentId,
//                          "AssignmentIndexId": assignmentIndexId ?? "",
//                          "ReadyInd": 1,
//                          "files":[["Name": name, "FullPath": originalName, "Size": size]]] as [String : Any]
//        Alamofire.request("https://mfriends.myschoolapp.com/api/assignment2/DropBoxSave?format=json", method: .post, parameters: parameters).responseJSON(queue: DispatchQueue.global(), options: .allowFragments, completionHandler: { response in
//
//        })
//    }
    
    @objc func checkDidChange(checkMark: M13Checkbox) {
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
        
        DispatchQueue.global().async {
            guard (self.assignmentIndexId != nil) else {
                return
            }
            
            var assignmentStatus: String? = nil
            switch self.checkMark.checkState {
            case .checked:
                assignmentStatus = "1"
            case .unchecked:
                assignmentStatus = "-1"
            default:
                NSLog("Something strange happened.")
                return
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
            
            do {
                try HomeworkView().updateAssignmentStatus(assignmentIndexId: self.assignmentIndexId!, assignmentStatus: assignmentStatus!)
            } catch {
                switch checkMark.checkState {
                case .checked:
                    checkMark.setCheckState(.unchecked, animated: false)
                case .unchecked:
                    checkMark.setCheckState(.checked, animated: false)
                default:
                    break
                }
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
            }
            
            self.refreshData()
        }
    }
    
    func refreshData() {
        guard let homeworkVC = self.parentViewController as? homeworkViewController else {
            return
        }
        
        homeworkVC.getHomework()
    }
}

class homeworkTableHeader: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!

}

