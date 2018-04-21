//
//  A Day.swift
//  MFSCalender
//
//  Created by David Dai on 2017/2/25.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import SnapKit
import DZNEmptyDataSet

class customCell: UITableViewCell {

    @IBOutlet weak var ClassName: UILabel!

    @IBOutlet weak var PeriodNumber: UILabel!

    @IBOutlet weak var RoomNumber: UILabel!

    @IBOutlet weak var PeriodTime: UILabel!

    @IBOutlet var teachersName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

class ADay: UIViewController, IndicatorInfoProvider {
    
    var daySelected: Date? = nil
    var dayLetter: String? = nil

    @IBOutlet var tableView: UITableView!
    
    var listClasses = [CourseMO]()
    var previewController: UIViewControllerPreviewing? = nil

    override func viewDidLoad() {
        // Do any additional setup after loading the view, typically from a nib.
        super.viewDidLoad()
        dataFetching()
        self.tableView.separatorStyle = .none
        tableView.emptyDataSetSource = self
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.removeBottomLine()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.dataFetching()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if #available(iOS 9.0, *) {
            if self.traitCollection.forceTouchCapability == .available {
                previewController = registerForPreviewing(with: self, sourceView: tableView)
            }
        }
    }
    

    func dataFetching() {
        guard daySelected != nil else {
            self.listClasses = []
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        print("Day: %@", daySelected!)
        let startTime = daySelected!.atTime(hour: 0, minute: 0, second: 0)!
        self.listClasses = getClassDataAt(date: startTime)
        print(listClasses)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        if dayLetter != nil {
            return IndicatorInfo(title: dayLetter! + " Day")
        } else {
            return IndicatorInfo(title: "Classes")
        }
    }
}

extension ADay: UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listClasses.count
    }


    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath as IndexPath) as! customCell

        let row = indexPath.row

        let rowDict = self.listClasses[row] 

        cell.ClassName.text = rowDict.name
//        if let period = rowDict["period"] as? Int {
//            cell?.PeriodNumber.text = String(describing: period)
//
//            cell?.PeriodTime.text = getMeetTime(period: period)
//        }

        let roomN = rowDict.room
        cell.RoomNumber.text = roomN
        
        cell.teachersName.text = rowDict.teacherName
        
//        if rowDict["index"] != nil {
//            cell.selectionStyle = .default
//            cell.accessoryType = .disclosureIndicator
//        } else {
//            cell.selectionStyle = .none
//           // cell?.accessoryType = .none
//        }

        return cell
    }
    
    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        print(location)
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return nil
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            previewingContext.sourceRect = cell.frame
        }
        
        let rowDict = self.listClasses[indexPath.row]
        guard let index = rowDict.index else {
            return nil
        }
        
        Preferences().indexForCourseToPresent = index
        
        let classDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "classDetailViewController")
        
        return classDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowDict = self.listClasses[indexPath.row] 
        guard let index = rowDict.index else {
            return
        }
        
        Preferences().indexForCourseToPresent = index
        
        let classDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "classDetailViewController")
        self.show(classDetailViewController, sender: self)
    }
}

extension ADay: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        let str = "There is no class on this day."
        self.tableView.separatorStyle = .none
        return NSAttributedString(string: str, attributes: attr)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let image = UIImage(named: "brush_pencil.png")?.imageResize(sizeChange: CGSize(width: 85, height: 85))
        return image
    }
}

