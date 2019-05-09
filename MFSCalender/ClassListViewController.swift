//
//  ClassListViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/22.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import UICircularProgressRing


class classListController: UIViewController, UIViewControllerPreviewingDelegate {

    @IBOutlet var classListCollectionView: UICollectionView!
    let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path

    var majorClasslist = [[String: Any]]()
    var minorClassList = [[String: Any]]()
    var isShowingGrade = false


    override func viewDidLoad() {
        super.viewDidLoad()
        self.classListCollectionView.delegate = self
        self.classListCollectionView.dataSource = self

        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        if let classList = NSArray(contentsOfFile: path) {
            sortClasses(classList: classList)
        }
        
        if self.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: classListCollectionView)
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Show Grade", style: .plain, target: self, action: #selector(showOrHideGrade))
        
//        if #available(iOS 11.0, *) {
//            setLargeTitle(on: self)
//        }
    }
    
    @objc func showOrHideGrade() {
        if !isShowingGrade {
            self.navigationItem.rightBarButtonItem!.title = "Hide Grade"
            isShowingGrade = true
        } else {
            self.navigationItem.rightBarButtonItem!.title = "Show Grade"
            isShowingGrade = false
        }
        
        DispatchQueue.main.async {
            self.classListCollectionView.reloadData()
        }
    }

    func sortClasses(classList: NSArray) {
        let notImportantClasses = ["Study Hall", "Assembly", "Break", "1st Period Prep", "Advisor", "USCoun", "US Dean", "Lunch", "Capstone"]

        majorClasslist = []
        minorClassList = []

        for items in classList {
            var classObject = items as! [String: Any]
            var isMinorClass = false

            guard let className = classObject["className"] as? String else {
                continue
            }

            for notImportantClass in notImportantClasses {
                if className.contains(notImportantClass) {
                    minorClassList.append(classObject)
                    isMinorClass = true
                    break
                }
            }

            if !isMinorClass {
                majorClasslist.append(classObject)
            }
        }
    }
    
    func updateClassList() {
        
    }
    
    func classObjectAt(indexPath: IndexPath) -> [String: Any]? {
        switch indexPath.section {
        case 0:
            if majorClasslist.indices.contains(indexPath.row) {
                return majorClasslist[indexPath.row]
            } else {
                return nil
            }
        default:
            if minorClassList.indices.contains(indexPath.row) {
                return minorClassList[indexPath.row]
            } else {
                return nil
            }
        }
    }
}

extension classListController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return majorClasslist.count
        case 1:
            return minorClassList.count
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard var classObject = classObjectAt(indexPath: indexPath) else {
            return UICollectionViewCell()
        }
        
        var cell: ClassListCell!
        
        if !isShowingGrade {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "classListViewCell", for: indexPath) as! classListViewCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "classListViewCellWithGrade", for: indexPath) as! ClassListViewWithGradeCell
            let grade = Float(classObject["cumgrade"] as? String ?? "0") ?? 0.0
            let cellWithRing = cell as! ClassListViewWithGradeCell
            cellWithRing.gradeRing.font = UIFont.boldSystemFont(ofSize: 24)
            DispatchQueue.main.async {
                cellWithRing.gradeRing.startProgress(to: CGFloat(grade), duration: 1.0)
            }
        }
        
        cell.title.text = classObject["className"] as? String
        
        if let sectionId = ClassView().getLeadSectionID(classDict: classObject) {
            print(sectionId)
            let imagePath = path.appending("/\(sectionId)_profile.png")
            if let backgroundImage = UIImage(contentsOfFile: imagePath) {
                cell.backgroundImage.isHidden = false
                cell.darkCover.isHidden = false
                cell.backgroundImage.image = backgroundImage
            } else {
                cell.backgroundImage.isHidden = true
                cell.darkCover.isHidden = true
            }
            
            cell.backgroundImage.contentMode = .scaleAspectFill
        }
        
        return cell

        
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard var classObject = classObjectAt(indexPath: indexPath) else { return }
        
        Preferences().indexForCourseToPresent = classObject["index"] as? Int ?? 0
        let vc = storyboard!.instantiateViewController(withIdentifier: "classDetailViewController")
        show(vc, sender: self)
    }
    
    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = classListCollectionView.indexPathForItem(at: location) else {
            return nil
        }
        
        if let cell = classListCollectionView.cellForItem(at: indexPath) {
           previewingContext.sourceRect = cell.frame
        }
        
        guard var classObject = classObjectAt(indexPath: indexPath) else { return nil }
        Preferences().indexForCourseToPresent = classObject["index"] as? Int ?? 0
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "classDetailViewController")
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ClassListCell

        cell.title.textColor = UIColor.gray

        UIView.animate(withDuration: 0.3, animations: {
            cell.backgroundImage.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ClassListCell

        cell.title.textColor = UIColor.white

        UIView.animate(withDuration: 0.3, animations: {
            cell.backgroundImage.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "classListHeaderViewCell", for: indexPath) as! classListHeaderViewCell
        if indexPath.section == 0 {
            view.textLabel.text = "Frequently Used"
        } else {
            view.textLabel.text = "Others"
        }

        return view
    }
}

extension classListController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewSize = Layout().squareSize()
        if isShowingGrade {
            return CGSize(width: viewSize, height: viewSize * 1.5)
        } else {
            return CGSize(width: viewSize, height: viewSize)
        }
    }
}

class classListViewCell: UICollectionViewCell, ClassListCell {
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var darkCover: UIView!
    @IBOutlet var contentRect: UIView!
}

class ClassListViewWithGradeCell: UICollectionViewCell, ClassListCell {
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var darkCover: UIView!
    @IBOutlet var title: UILabel!
    @IBOutlet var contentRect: UIView!
    @IBOutlet var gradeRing: UICircularProgressRing!
}

protocol ClassListCell: UICollectionViewCell {
    var backgroundImage: UIImageView! { get set }
    var title: UILabel! { get set }
    var darkCover: UIView! { get set }
    var contentRect: UIView! { get set }
}

class classListHeaderViewCell: UICollectionReusableView {
    @IBOutlet var textLabel: UILabel!
}
