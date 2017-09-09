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
import M13ProgressSuite


class homeworkViewController: UITableViewController {


    @IBOutlet weak var homeworkTable: UITableView!
    var isUpdatingHomework = false

    var listHomework = [String: [[String: Any]]]()
    var sections: [String] {
        return Array(self.listHomework.keys).sorted()
    }

    let formatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        homeworkTable.rowHeight = UITableViewAutomaticDimension
        homeworkTable.estimatedRowHeight = 80
        homeworkTable.emptyDataSetSource = self
        homeworkTable.emptyDataSetDelegate = self
        homeworkTable.delegate = self

//        Remove the bottom 1px line on Navigation Bar
        self.navigationController?.navigationBar.barTintColor = UIColor(hexString: 0xFF7E79)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()

        let loadingview = DGElasticPullToRefreshLoadingViewCircle()
        loadingview.tintColor = UIColor.white
        homeworkTable.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            self?.getHomework()
            self?.tableView.dg_stopLoading()
        }, loadingView: loadingview)
        homeworkTable.dg_setPullToRefreshFillColor(UIColor(hexString: 0xFF7E79))
        homeworkTable.dg_setPullToRefreshBackgroundColor(tableView.backgroundColor!)

    }

    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.global().async {
            self.getHomework()
        }
    }

    func errorMessage(presentMessage: String) {
        let view = MessageView.viewFromNib(layout: .CardView)
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
        isUpdatingHomework = true
        DispatchQueue.main.async {
            self.navigationController?.showProgress()
            self.navigationController?.setPrimaryColor(UIColor(hexString: 0xFF7E79))
            self.navigationController?.setSecondaryColor(UIColor.white)
            self.navigationController?.setIndeterminate(true)
            self.tableView.reloadData()
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
        let today = formatter.string(from: Date()).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url = "https://mfriends.myschoolapp.com/api/DataDirect/AssignmentCenterAssignments/?format=json&filter=2&dateStart=\(today)&dateEnd=\(today)&persona=2"
        let request = URLRequest(url: URL(string: url)!)
        
        var originalData = [[String:Any]]()
        let semaphore = DispatchSemaphore.init(value: 0)
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] {
                        print(json)
                        originalData = json
                    }

                } catch {
                    NSLog("Data parsing failed")
                    // print(String(data: data!, encoding: .utf8))
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
            self.navigationController?.cancelProgress()
            self.tableView.reloadData()
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
//            Let it crash
            formatter.dateFormat = "yyyyMMdd"
            if dueDate != nil {
                let dueDateMDString = formatter.string(from: dueDate!)
                var homeworkArray = managedHomework[dueDateMDString]
                if homeworkArray == nil {
                    homeworkArray = []
                }
                homeworkArray?.append(homework)
                managedHomework[dueDateMDString] = homeworkArray
            }
        }

        self.listHomework = managedHomework
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let homeworkInSection = self.listHomework[sections[section]] else {
            return 0
        }
        return homeworkInSection.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        print(sections)
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
        } else if dueDate.isBefore(date: Date().endOf(component: .weekOfYear), granularity: .day) {
            let weekDay = dueDate.string(format: .custom("EEEE"))
            return "This " + weekDay
        } else if dueDate.isBefore(date: (Date() + 1.week).endOf(component: .weekOfYear), granularity: .day) {
            let weekDay = dueDate.string(format: .custom("EEEE"))
            return "Next " + weekDay
        } else {
            return dueDate.string(format: .custom("EEEE, MMM d, yyyy"))
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "homeworkTableHeader") as! homeworkTableHeader

        let dateString = stringForHeaderInSection(section: section)
        headerView.titleLabel.text = dateString
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let homeworkInSection = self.listHomework[sections[indexPath.section]]
        guard let homework = homeworkInSection?[indexPath.row] else {
            return
        }
        
        guard (homework["long_description"] as? String).existsAndNotEmpty() else {
            return
        }
        
        guard let assignmentID = homework["assignment_index_id"] as? Int else {
            return
        }
        
        userDefaults?.set(assignmentID, forKey: "indexIdForAssignmentToPresent")
        
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "homeworkDetailViewController") else {
            return
        }
        
        show(viewController, sender: self)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeworkViewCell", for: indexPath) as! homeworkViewCell

        let homeworkInSection = self.listHomework[sections[indexPath.section]]
        guard let homework = homeworkInSection?[indexPath.row] else {
            return cell
        }
        if let assignmentIndexId = homework["assignment_index_id"] as? Int {
            cell.assignmentIndexId = String(describing: assignmentIndexId)
        }

//        if let sectionId = homework["section_id"] as? Int {
//            cell.sectionId = String(describing: sectionId)
//        }
        
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

        let homeworkType = homework["assignment_type"] as? String ?? ""
        cell.homeworkType.text = homeworkType

        cell.tagView.backgroundColor = HomeworkView().colorForTheType(type: homeworkType)

        if let status = homework["assignment_status"] as? Int {
            let checkState = HomeworkView().checkStateFor(status: status)
            cell.checkMark.setCheckState(checkState, animated: false)
        }
        
        if homework["has_grade"] as? Bool == true {
            cell.checkMark.setCheckState(.checked, animated: false)
            cell.checkMark.isEnabled = false
        }
        
        if (homework["long_description"] as? String).existsAndNotEmpty() {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.shortDescription.isSelectable = false
        } else {
            cell.selectionStyle = .none
            cell.accessoryType = .none
            cell.shortDescription.isSelectable = true
        }

        cell.checkMark.tintColor = cell.tagView.backgroundColor
        return cell
    }
}

extension homeworkViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "No_homework.png")?.imageResize(sizeChange: CGSize(width: 95, height: 95))
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]

        var str = "There is no homework to display."
        if isUpdatingHomework {
            str = "Updating homework..."
        }
        return NSAttributedString(string: str, attributes: attr)
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        if isUpdatingHomework {
            return NSAttributedString()
        }

        let buttonTitleString = NSAttributedString(string: "Refresh...", attributes: [NSForegroundColorAttributeName: UIColor(hexString: 0xFF7E79)])

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

    @IBOutlet var shortDescription: UITextView!

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var assignmentIndexId: String?

    override func awakeFromNib() {
        checkMark.stateChangeAnimation = .bounce(.fill)
        checkMark.boxLineWidth = 3
        checkMark.addTarget(self, action: #selector(checkDidChange), for: UIControlEvents.valueChanged)
        activityIndicator.isHidden = true
        let shortDescriptionString = shortDescription.attributedText.string
        
        if shortDescriptionString.contains("http://") || shortDescriptionString.contains("https://") {
            shortDescription.isUserInteractionEnabled = true
        } else {
            shortDescription.isUserInteractionEnabled = false
        }
    }

    func checkDidChange(checkMark: M13Checkbox) {
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
        }
    }
}

class homeworkTableHeader: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!

}

