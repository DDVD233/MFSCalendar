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

    var listHomework = [String: Array<NSDictionary>]()
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
        
        var originalData = [NSDictionary]()
        let semaphore = DispatchSemaphore.init(value: 0)
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<NSDictionary> {
                        print(json)
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
            self.navigationController?.cancelProgress()
            self.tableView.reloadData()
        }
    }

    func manageDate(originalData: Array<NSDictionary>) {
        var managedHomework = [String: Array<NSDictionary>]()
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
        guard sections.count > sections.count else {
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
        print("Row selected")
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

        if let sectionId = homework["section_id"] as? Int {
            cell.sectionId = String(describing: sectionId)
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

        let homeworkType = homework["assignment_type"] as? String
        cell.homeworkType.text = homeworkType

        if homeworkType != nil {
            switch homeworkType! {
            case "Homework":
                cell.tagView.backgroundColor = UIColor(hexString: 0xF44336)
            case "Quiz":
                cell.tagView.backgroundColor = UIColor(hexString: 0x2196F3)
            case "Test":
                cell.tagView.backgroundColor = UIColor(hexString: 0x3F51B5)
            case "Project":
                cell.tagView.backgroundColor = UIColor(hexString: 0xFF9800)
            case "Classwork":
                cell.tagView.backgroundColor = UIColor(hexString: 0x795548)
            default:
                cell.tagView.backgroundColor = UIColor(hexString: 0x607D8B)
            }
        }

        if let status = homework["assignment_status"] as? Int {
            switch status {
            case -1:
                cell.checkMark.setCheckState(.unchecked, animated: false)
            case 1:
                cell.checkMark.setCheckState(.checked, animated: false)
            default:
                cell.checkMark.setCheckState(.unchecked, animated: false)
            }
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
    var sectionId: String?

    override func awakeFromNib() {
        checkMark.stateChangeAnimation = .bounce(.fill)
        checkMark.boxLineWidth = 3
        checkMark.addTarget(self, action: #selector(checkDidChange), for: UIControlEvents.valueChanged)
        activityIndicator.isHidden = true
    }
    
    func tapped(_ sender: UITapGestureRecognizer) {
        print("tapped!")
    }

    func checkDidChange(checkMark: M13Checkbox) {
        DispatchQueue.global().async {
            guard (self.assignmentIndexId != nil) else {
                return
            }
            guard (self.sectionId != nil) else {
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
            
            
            let url = "https://mfriends.myschoolapp.com/api/assignment2/assignmentstatusupdate/?format=json&assignmentIndexId=\(self.assignmentIndexId!)&assignmentStatus=\(assignmentStatus!)"
            
            let json = ["assignmentIndexId": self.assignmentIndexId!, "assignmentStatus": assignmentStatus!]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
                return
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
            var request = try! URLRequest(url: URL(string: url)!, method: .post)
            request.httpBody = jsonData
            let session = URLSession.shared
            
            let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                DispatchQueue.main.async {
                    self.activityIndicator.isHidden = true
                    self.activityIndicator.stopAnimating()
                }
                if error == nil {
                    
                } else {
                    switch checkMark.checkState {
                    case .checked:
                        checkMark.setCheckState(.unchecked, animated: false)
                    case .unchecked:
                        checkMark.setCheckState(.checked, animated: false)
                    default:
                        break
                    }
                    presentErrorMessage(presentMessage: error!.localizedDescription, layout: .StatusLine)
                }
            })
            
            task.resume()
        }
    }
}

class homeworkTableHeader: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!

}

