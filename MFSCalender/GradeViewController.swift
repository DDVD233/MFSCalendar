//
//  GradeViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/7/17.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import UICircularProgressRing
import SwiftyJSON
import SwiftMessages
import DGElasticPullToRefresh

class gradeViewController: UITableViewController {
    var classObject: NSDictionary? = nil

    var cumGrade: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.global().async {
            self.refreshView()
        }

        let loadingview = DGElasticPullToRefreshLoadingViewCircle()
        loadingview.tintColor = UIColor.white
        tableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            self?.refreshView()
            self?.tableView.dg_stopLoading()
        }, loadingView: loadingview)
        tableView.dg_setPullToRefreshFillColor(UIColor(hexString: 0xFF7E79))
        tableView.dg_setPullToRefreshBackgroundColor(tableView.backgroundColor!)
    }

    func refreshView() {
        DispatchQueue.main.async {
            self.navigationController?.showProgress()
            self.navigationController?.setIndeterminate(true)
        }

        cumGrade = Float(getcumGrade()) ?? 0

        DispatchQueue.main.async {
            self.navigationController?.cancelProgress()
            let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! cumGradeCell
            cell.cumGradeProgressRing.setProgress(value: CGFloat(self.cumGrade), animationDuration: 1.0)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        tableView.dg_removePullToRefresh()
    }

    func getcumGrade() -> String {

        guard loginAuthentication().success else {
            return ""
        }

        let userId = loginAuthentication().userId

        let classObject = classView().getTheClassToPresent() ?? [String: Any]()
        let leadSectionId = classObject["leadsectionid"] as? Int

        var cumGrade = ""

        guard let durationId = NetworkOperations().getDurationId() else {
            return ""
        }

        let session = URLSession.shared
        let url = "https://mfriends.myschoolapp.com/api/datadirect/ParentStudentUserAcademicGroupsGet?userId=\(userId)&schoolYearLabel=2016+-+2017&memberLevel=3&persona=2&durationList=\(durationId)&markingPeriodId="
        let request = URLRequest(url: URL(string: url)!)
        let semaphore = DispatchSemaphore.init(value: 0)

        let dataTask = session.dataTask(with: request, completionHandler: {
            (data, response, error) -> Void in
            if error == nil {
                let json = JSON(data!)

                for (_, subJson): (String, JSON) in json {
                    if subJson["leadsectionid"].intValue == leadSectionId {
                        cumGrade = subJson["cumgrade"].stringValue
                        print("CumGrade: \(cumGrade)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let presentMessage = error!.localizedDescription + " Please check your internet connection."
                    let view = MessageView.viewFromNib(layout: .CardView)
                    view.configureTheme(.error)
                    let icon = "😱"
                    view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
                    view.button?.isHidden = true
                    let config = SwiftMessages.Config()
                    SwiftMessages.show(config: config, view: view)
                }
            }
            semaphore.signal()
        })

        dataTask.resume()
        semaphore.wait()
        return cumGrade
    }
}

extension gradeViewController {
//    UITableviewDelegate and UITableviewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cumGrade", for: indexPath) as! cumGradeCell
            cell.cumGradeProgressRing.value = CGFloat(cumGrade)
            print(cumGrade)

            cell.selectionStyle = .none

            return cell
        default:
            break
        }

        let defaultCell = tableView.dequeueReusableCell(withIdentifier: "cumGrade", for: indexPath)
        return defaultCell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 280
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Cumulative Grade"
        default:
            return ""
        }
    }
}

extension gradeViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "GRADE")
    }
}

class cumGradeCell: UITableViewCell {


    @IBOutlet var cumGradeProgressRing: UICircularProgressRingView!

    var cumGrade: Float? = nil

    override func awakeFromNib() {
        super.awakeFromNib()

        cumGradeProgressRing.font = UIFont.boldSystemFont(ofSize: 32)
    }
}
