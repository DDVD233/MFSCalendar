//
//  A Day.swift
//  MFSCalender
//
//  Created by David Dai on 2017/2/25.
//  Copyright © 2017年 David. All rights reserved.
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
    
    @IBOutlet var mainView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 13.0, *) {
            let hover = UIHoverGestureRecognizer(target: self, action: #selector(hovering(_:)))
            mainView.addGestureRecognizer(hover)
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @available(iOS 13.0, *)
    @objc
    func hovering(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            mainView.backgroundColor = UIColor(hexString: 0xFF8080)
        case .ended:
            mainView.backgroundColor = UIColor(hexString: 0xff6666)
        default:
            break
        }
    }

}

class ADay: UIViewController, IndicatorInfoProvider {
    
    var date: Date? = nil
    var daySelected: String? = nil

    @IBOutlet var tableView: UITableView!
    
    var listClasses = [[String: Any]]()
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
        if date != nil {
            self.listClasses = school.getClassDataAt(date: date!)
            print(listClasses)
        } else if daySelected != nil {
            self.listClasses = school.getClassDataAt(day: daySelected!)
        } else {
            self.listClasses = []
        }
        
        
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        if daySelected != nil {
            return IndicatorInfo(title: daySelected! + NSLocalizedString(" Day", comment: ""))
        } else {
            return IndicatorInfo(title: NSLocalizedString("Classes", comment: ""))
        }
    }
}

extension ADay: UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listClasses.count
    }


    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath as IndexPath) as? customCell

        let row = indexPath.row

        let rowDict = self.listClasses[row] 

        cell?.ClassName.text = rowDict["className"] as? String
        if let period = rowDict["period"] as? Int {
            cell?.PeriodNumber.text = String(describing: period)

            cell?.PeriodTime.text = school.meetTimeForPeriod(periodObject: rowDict)
        }

        let roomN = rowDict["roomNumber"] as? String
        cell?.RoomNumber.text = roomN
        
        cell?.teachersName.text = rowDict["teacherName"] as? String
        
        if rowDict["index"] != nil {
            cell?.selectionStyle = .default
            cell?.accessoryType = .disclosureIndicator
        } else {
            cell?.selectionStyle = .none
           // cell?.accessoryType = .none
        }

        return cell!
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
        guard let index = rowDict["index"] as? Int else {
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
        guard let index = rowDict["index"] as? Int else {
            return
        }
        
        Preferences().indexForCourseToPresent = index
        
        let classDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "classDetailViewController")
        self.show(classDetailViewController, sender: self)
    }
}

extension ADay: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)]
        let str = NSLocalizedString("There is no class on this day.", comment: "")
        self.tableView.separatorStyle = .none
        return NSAttributedString(string: str, attributes: attr)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let image = UIImage(named: "brush_pencil.png")?.imageResize(sizeChange: CGSize(width: 85, height: 85))
        return image
    }
}

