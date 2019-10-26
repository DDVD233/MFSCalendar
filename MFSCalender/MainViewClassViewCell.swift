//
//  MainViewClassViewCell.swift
//  MFSMobile
//
//  Created by 戴元平 on 10/23/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit

class classViewCell: UICollectionViewCell {
    var index: Int? = nil

    @IBOutlet weak var period: UILabel!

    @IBOutlet weak var className: UILabel!

    @IBOutlet weak var teacher: UILabel!

    @IBOutlet weak var roomNumber: UILabel!

    @IBOutlet var classViewButton: UIButton!
    
    @IBOutlet var mainView: UIView!
    

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
        if #available(iOS 13.0, *) {
            let hover = UIHoverGestureRecognizer(target: self, action: #selector(hovering(_:)))
            mainView.addGestureRecognizer(hover)
        }
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
