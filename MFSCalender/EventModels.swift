//
//  EventModels.swift
//  MFSMobile
//
//  Created by 戴元平 on 2/5/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation
import JZCalendarWeekView

class DefaultEvent: JZBaseEvent {
    
    var location: String
    var title: String
    
    
    init(id: String, title: String, startDate: Date, endDate: Date, location: String) {
        self.location = location
        self.title = title
        
        // If you want to have you custom uid, you can set the parent class's id with your uid or UUID().uuidString (In this case, we just use the base class id)
        super.init(id: id, startDate: startDate, endDate: endDate)
    }
    
    override func copy(with zone: NSZone?) -> Any {
        return DefaultEvent(id: id, title: title, startDate: startDate, endDate: endDate, location: location)
    }
}

class DefaultViewModel: NSObject {
    
    private let firstDate = Date().add(component: .hour, value: 1)
    private let secondDate = Date().add(component: .day, value: 1)
    private let thirdDate = Date().add(component: .day, value: 2)
    
    lazy var events = [DefaultEvent(id: "0", title: "One", startDate: firstDate, endDate: firstDate.add(component: .hour, value: 1), location: "Melbourne"),
                       DefaultEvent(id: "1", title: "Two", startDate: secondDate, endDate: secondDate.add(component: .hour, value: 4), location: "Sydney"),
                       DefaultEvent(id: "2", title: "Three", startDate: thirdDate, endDate: thirdDate.add(component: .hour, value: 2), location: "Tasmania"),
                       DefaultEvent(id: "3", title: "Four", startDate: thirdDate, endDate: thirdDate.add(component: .hour, value: 26), location: "Canberra")]
    
    lazy var eventsByDate = JZWeekViewHelper.getIntraEventsByDate(originalEvents: events)
    
    var currentSelectedData: OptionsSelectedData!
}

extension Date {
    
    func add(component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self)!
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}

struct OptionsSelectedData {
    
    var viewType: ViewType
    var date: Date
    var numOfDays: Int
    var scrollType: JZScrollType
    var firstDayOfWeek: DayOfWeek?
    var hourGridDivision: JZHourGridDivision
    var scrollableRange: (startDate: Date?, endDate: Date?)
    
    init(viewType: ViewType, date: Date, numOfDays: Int, scrollType: JZScrollType, firstDayOfWeek: DayOfWeek?, hourGridDivision: JZHourGridDivision, scrollableRange: (Date?, Date?)) {
        self.viewType = viewType
        self.date = date
        self.numOfDays = numOfDays
        self.scrollType = scrollType
        self.firstDayOfWeek = firstDayOfWeek
        self.hourGridDivision = hourGridDivision
        self.scrollableRange = scrollableRange
    }
}

enum ViewType: String {
    case defaultView = "Default JZBaseWeekView"
    case customView = "Custom JZBaseWeekView"
    case longPressView = "JZLongPressWeekView"
}

class DefaultWeekView: JZBaseWeekView {
    
    override func registerViewClasses() {
        super.registerViewClasses()
        
        self.collectionView.register(UINib(nibName: EventCell.className, bundle: nil), forCellWithReuseIdentifier: EventCell.className)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EventCell.className, for: indexPath) as! EventCell
        cell.configureCell(event: getCurrentEvent(with: indexPath) as! DefaultEvent)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedEvent = getCurrentEvent(with: indexPath) as! DefaultEvent
        ToastUtil.toastMessageInTheMiddle(message: selectedEvent.title)
    }
}

class EventCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var borderView: UIView!
    var event: DefaultEvent!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupBasic()
    }
    
    func setupBasic() {
        self.clipsToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 5
        layer.shadowOpacity = 0
        locationLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        self.backgroundColor = UIColor(hex: 0xEEF7FF)
        borderView.backgroundColor = UIColor(hex: 0x0899FF)
    }
    
    func configureCell(event: DefaultEvent) {
        self.event = event
        locationLabel.text = event.location
        titleLabel.text = event.title
    }
    
}

extension NSObject {
    
    class var className: String {
        return String(describing: self)
    }
}

open class ToastUtil {
    
    static private let defaultLabelSidesPadding: CGFloat = 20
    
    static private let defaultMidFont = UIFont.systemFont(ofSize: 13)
    static private let defaultMidBgColor = UIColor(hex: 0xE8E8E8)
    static private let defaultMidTextColor = UIColor.darkGray
    static private let defaultMidHeight: CGFloat = 40
    static private let defaultMidMinWidth: CGFloat = 80
    static private let defaultMidToBottom: CGFloat = 20 + UITabBarController().tabBar.frame.height
    
    static private let defaultExistTime: TimeInterval = 1.5
    static private let defaultShowTime: TimeInterval = 0.5
    
    static private var toastView: UIView!
    static private var toastLabel: UILabel!
    
    public static func toastMessageInTheMiddle(message: String, bgColor: UIColor? = nil, existTime: TimeInterval? = nil) {
        guard let currentWindow = UIApplication.shared.delegate?.window!, toastView == nil else { return }
        
        toastView = UIView()
        toastView.backgroundColor = defaultMidBgColor
        toastView.alpha = 0
        toastView.layer.cornerRadius = defaultMidHeight/2
        toastView.clipsToBounds = true
        addToastLabel(message: message)
        
        currentWindow.addSubview(toastView)
        var bottomYAnchor: NSLayoutYAxisAnchor
        // Support iPhone X
        if #available(iOS 11.0, *) {
            bottomYAnchor = currentWindow.safeAreaLayoutGuide.bottomAnchor
        } else {
            bottomYAnchor = currentWindow.bottomAnchor
        }
        toastView.setAnchorCenterHorizontallyTo(view: currentWindow, heightAnchor: defaultMidHeight, bottomAnchor: (bottomYAnchor, -defaultMidToBottom))
        toastView.widthAnchor.constraint(greaterThanOrEqualToConstant: defaultMidMinWidth).isActive = true
        
        let delay = existTime ?? defaultExistTime
        UIView.animate(withDuration: defaultShowTime, delay: 0, options: .curveEaseInOut, animations: {
            toastView.alpha = 1
            toastLabel.alpha = 1
        }, completion: { _ in
            
            UIView.animate(withDuration: defaultShowTime, delay: delay, options: .curveEaseInOut, animations: {
                toastView.alpha = 0
                toastLabel.alpha = 0
            }, completion: { _ in
                toastView.removeFromSuperview()
                toastView = nil
            })
        })
    }
    
    private static func addToastLabel(message: String) {
        toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.font = defaultMidFont
        toastLabel.textColor = defaultMidTextColor
        toastLabel.textAlignment = .center
        toastLabel.alpha = 0
        toastView.addSubview(toastLabel)
        toastLabel.centerYAnchor.constraint(equalTo: toastView.centerYAnchor, constant: 0).isActive = true
        toastLabel.setAnchorCenterVerticallyTo(view: toastView, heightAnchor: defaultMidHeight, leadingAnchor: (toastView.leadingAnchor, defaultLabelSidesPadding), trailingAnchor: (toastView.trailingAnchor, -defaultLabelSidesPadding))
    }
}

// Anchor Constraints from JZiOSFramework
extension UIView {
    
    func setAnchorConstraintsEqualTo(widthAnchor: CGFloat?=nil, heightAnchor: CGFloat?=nil, centerXAnchor: NSLayoutXAxisAnchor?=nil, centerYAnchor: NSLayoutYAxisAnchor?=nil) {
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        if let width = widthAnchor{
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if let height = heightAnchor{
            self.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        if let centerX = centerXAnchor{
            self.centerXAnchor.constraint(equalTo: centerX).isActive = true
        }
        
        if let centerY = centerYAnchor{
            self.centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
    }
    
    // bottomAnchor & trailingAnchor should be negative
    func setAnchorConstraintsEqualTo(widthAnchor: CGFloat?=nil, heightAnchor: CGFloat?=nil, topAnchor: (NSLayoutYAxisAnchor,CGFloat)?=nil, bottomAnchor: (NSLayoutYAxisAnchor,CGFloat)?=nil, leadingAnchor: (NSLayoutXAxisAnchor,CGFloat)?=nil, trailingAnchor: (NSLayoutXAxisAnchor,CGFloat)?=nil) {
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        if let width = widthAnchor{
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if let height = heightAnchor{
            self.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        if let topY = topAnchor{
            self.topAnchor.constraint(equalTo: topY.0, constant: topY.1).isActive = true
        }
        
        if let botY = bottomAnchor{
            self.bottomAnchor.constraint(equalTo: botY.0, constant: botY.1).isActive = true
        }
        
        if let leadingX = leadingAnchor{
            self.leadingAnchor.constraint(equalTo: leadingX.0, constant: leadingX.1).isActive = true
        }
        
        if let trailingX = trailingAnchor{
            self.trailingAnchor.constraint(equalTo: trailingX.0, constant: trailingX.1).isActive = true
        }
    }
    
    func setAnchorCenterVerticallyTo(view: UIView, widthAnchor: CGFloat?=nil, heightAnchor: CGFloat?=nil, leadingAnchor: (NSLayoutXAxisAnchor,CGFloat)?=nil, trailingAnchor: (NSLayoutXAxisAnchor,CGFloat)?=nil) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        setAnchorConstraintsEqualTo(widthAnchor: widthAnchor, heightAnchor: heightAnchor, centerYAnchor: view.centerYAnchor)
        
        if let leadingX = leadingAnchor{
            self.leadingAnchor.constraint(equalTo: leadingX.0, constant: leadingX.1).isActive = true
        }
        
        if let trailingX = trailingAnchor{
            self.trailingAnchor.constraint(equalTo: trailingX.0, constant: trailingX.1).isActive = true
        }
    }
    
    func setAnchorCenterHorizontallyTo(view: UIView, widthAnchor: CGFloat?=nil, heightAnchor: CGFloat?=nil, topAnchor: (NSLayoutYAxisAnchor,CGFloat)?=nil, bottomAnchor: (NSLayoutYAxisAnchor,CGFloat)?=nil) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        setAnchorConstraintsEqualTo(widthAnchor: widthAnchor, heightAnchor: heightAnchor, centerXAnchor: view.centerXAnchor)
        
        if let topY = topAnchor{
            self.topAnchor.constraint(equalTo: topY.0, constant: topY.1).isActive = true
        }
        
        if let botY = bottomAnchor{
            self.bottomAnchor.constraint(equalTo: botY.0, constant: botY.1).isActive = true
        }
    }
    
    func setAnchorConstraintsFullSizeTo(view: UIView, padding: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: view.topAnchor, constant: padding).isActive = true
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding).isActive = true
        self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding).isActive = true
        self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding).isActive = true
    }
    
    func addSubviews(_ views: [UIView]) {
        views.forEach({ self.addSubview($0)})
    }
}

