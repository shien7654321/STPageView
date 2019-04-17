//
//  STPageView.swift
//  STPageView
//
//  Created by Suta on 2017/4/14.
//  Copyright © 2017年 Suta. All rights reserved.
//

import UIKit

@objc public protocol STPageViewDelegate {
    @objc optional func pageView(_ pageView: STPageView, didSelect controller: UIViewController)
}

public class STPageView: UIView, UIScrollViewDelegate {
    
    public private(set) var controllers = [UIViewController]() {
        didSet {
            didSetControllers(oldValue)
        }
    }
    public var page = 0 {
        didSet {
            if page == 0 || controllers.isEmpty {
                didSetPage(oldValue)
            } else {
                guard page >= 0 && page < controllers.count else {
                    if oldValue >= 0 && oldValue < controllers.count {
                        page = oldValue
                    } else {
                        page = 0
                    }
                    return
                }
                didSetPage(oldValue)
            }
        }
    }
    public weak var delegate: STPageViewDelegate?
    public private(set) var scrollView: UIScrollView!
    private var scrollContainerView: UIView!
    private var setPageBySelf = false
    private var shouldResetPage = true
    private var currentPage = 0
    private var buildedUI = false
    
    // MARK: -
    
    deinit {
        removeObserver()
    }
    
    override private init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        buildUI()
    }
    
    private convenience init() {
        self.init(frame: .zero)
    }
    
    convenience public init(controllers: [UIViewController]) {
        self.init()
        defer {
            self.controllers = controllers
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
        buildUI()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if let myController = myController() {
            if myController.automaticallyAdjustsScrollViewInsets {
                myController.automaticallyAdjustsScrollViewInsets = false
            }
        }
        setupControllers()
        if shouldResetPage {
            shouldResetPage = false
            page = Int(page)
        }
    }
    
    // MARK: - Public
    
    public func setPage(_ newPage: Int, animated: Bool = false) {
        guard newPage >= 0 && newPage < controllers.count else {
            return
        }
        setPageBySelf = true
        page = newPage
        let scrollViewContentOffsetX = CGFloat(page) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: scrollViewContentOffsetX, y: scrollView.contentOffset.y) , animated: animated)
    }
    
    public func resetControllers(_ controllers: [UIViewController]) {
        self.controllers = controllers
        setPageBySelf = true
        page = 0
    }
    
    public func insertController(_ controller: UIViewController, atIndex index: Int) {
        guard index >= 0 && index <= controllers.count else {
            return
        }
        controllers.insert(controller, at: index)
        updateScrollContainerViewWidthConstraint()
        if let myController = myController() {
            
            
            myController.addChild(controller)
            scrollContainerView.insertSubview(controller.view, at: index)
            
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            let controllerViewFirstConstraint = NSLayoutConstraint(item: controller.view!, attribute: .top, relatedBy: .equal, toItem: controller.view.superview, attribute: .top, multiplier: 1, constant: 0)
            let controllerViewSecondConstraint = NSLayoutConstraint(item: controller.view!, attribute: .bottom, relatedBy: .equal, toItem: controller.view.superview, attribute: .bottom, multiplier: 1, constant: 0)
            let controllerViewThirdConstraint = NSLayoutConstraint(item: controller.view!, attribute: .width, relatedBy: .equal, toItem: controller.view.superview, attribute: .width, multiplier: 1 / CGFloat(controllers.isEmpty ? 1 : controllers.count), constant: 0)
            var controllerViewFourthConstraint: NSLayoutConstraint?
            if index == 0 {
                controllerViewFourthConstraint = NSLayoutConstraint(item: controller.view!, attribute: .leading, relatedBy: .equal, toItem: controller.view.superview, attribute: .leading, multiplier: 1, constant: 0)
            } else {
                let previousController = controllers[index - 1]
                controllerViewFourthConstraint = NSLayoutConstraint(item: controller.view!, attribute: .leading, relatedBy: .equal, toItem: previousController.view, attribute: .trailing, multiplier: 1, constant: 0)
            }
            scrollContainerView.addConstraint(controllerViewFirstConstraint)
            scrollContainerView.addConstraint(controllerViewSecondConstraint)
            scrollContainerView.addConstraint(controllerViewThirdConstraint)
            if let constaint = controllerViewFourthConstraint {
                scrollContainerView.addConstraint(constaint)
            }
        }
        for i in index + 1 ..< controllers.count {
            let theController = controllers[i]
            var widthConstraint: NSLayoutConstraint?
            var leadingConstraint: NSLayoutConstraint?
            for constraint in theController.view.superview!.constraints {
                if (constraint.firstItem?.isEqual(theController.view))! && constraint.firstAttribute == .leading {
                    leadingConstraint = constraint
                    if widthConstraint != nil && leadingConstraint != nil {
                        break
                    }
                } else if (constraint.firstItem?.isEqual(theController.view))! && constraint.firstAttribute == .width {
                    widthConstraint = constraint
                    if widthConstraint != nil && leadingConstraint != nil {
                        break
                    }
                }
            }
            if widthConstraint != nil {
                theController.view.superview!.removeConstraint(widthConstraint!)
                widthConstraint = NSLayoutConstraint(item: theController.view!, attribute: .width, relatedBy: .equal, toItem: theController.view.superview, attribute: .width, multiplier: 1 / CGFloat(controllers.isEmpty ? 1 : controllers.count), constant: 0)
                scrollContainerView.addConstraint(widthConstraint!)
            }
            if leadingConstraint != nil {
                theController.view.superview!.removeConstraint(leadingConstraint!)
                if i == 0 {
                    leadingConstraint = NSLayoutConstraint(item: theController.view!, attribute: .leading, relatedBy: .equal, toItem: theController.view.superview, attribute: .leading, multiplier: 1, constant: 0)
                } else {
                    let previousController = controllers[i - 1]
                    leadingConstraint = NSLayoutConstraint(item: theController.view!, attribute: .leading, relatedBy: .equal, toItem: previousController.view, attribute: .trailing, multiplier: 1, constant: 0)
                }
                if let constaint = leadingConstraint {
                    scrollContainerView.addConstraint(constaint)
                }
            }
        }
        if page >= index {
            setPage(page + 1)
        }
    }
    
    public func removeController(_ controller: UIViewController) {
        guard controllers.contains(controller) else {
            return
        }
        let index = controllers.firstIndex(of: controller)!
        for i in index + 1 ..< controllers.count {
            let theController = controllers[i]
            var widthConstraint: NSLayoutConstraint?
            var leadingConstraint: NSLayoutConstraint?
            for constraint in theController.view.superview!.constraints {
                if (constraint.firstItem?.isEqual(theController.view))! && constraint.firstAttribute == .leading {
                    leadingConstraint = constraint
                    if widthConstraint != nil && leadingConstraint != nil {
                        break
                    }
                } else if (constraint.firstItem?.isEqual(theController.view))! && constraint.firstAttribute == .width {
                    widthConstraint = constraint
                    if widthConstraint != nil && leadingConstraint != nil {
                        break
                    }
                }
            }
            if widthConstraint != nil {
                theController.view.superview!.removeConstraint(widthConstraint!)
                widthConstraint = NSLayoutConstraint(item: theController.view!, attribute: .width, relatedBy: .equal, toItem: theController.view.superview, attribute: .width, multiplier: 1 / CGFloat(controllers.count - 1 > 0 ? 1 : controllers.count - 1), constant: 0)
                scrollContainerView.addConstraint(widthConstraint!)
            }
            if leadingConstraint != nil {
                theController.view.superview!.removeConstraint(leadingConstraint!)
                if i == 1 {
                    leadingConstraint = NSLayoutConstraint(item: theController.view!, attribute: .leading, relatedBy: .equal, toItem: theController.view.superview, attribute: .leading, multiplier: 1, constant: 0)
                } else {
                    let previousController = controllers[i - 2]
                    leadingConstraint = NSLayoutConstraint(item: theController.view!, attribute: .leading, relatedBy: .equal, toItem: previousController.view, attribute: .trailing, multiplier: 1, constant: 0)
                }
                if let constaint = leadingConstraint {
                    scrollContainerView.addConstraint(constaint)
                }
            }
        }
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        controllers.remove(at: index)
        updateScrollContainerViewWidthConstraint()
        if page >= index && page >= controllers.count {
            let newPage = max(page - 1, 0)
            setPage(newPage)
        }
    }
    
    // MARK: - Private
    
    private func configure() {
        addObserver()
    }
    
    private func buildUI() {
        
        guard !buildedUI else {
            return
        }
        buildedUI = true
        
        scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        addSubview(scrollView);
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let scrollViewFirstConstraintArray = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scrollView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["scrollView" : scrollView!])
        let scrollViewSecondConstraintArray = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[scrollView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["scrollView" : scrollView!])
        addConstraints(scrollViewFirstConstraintArray)
        addConstraints(scrollViewSecondConstraintArray)
        
        scrollContainerView = UIView()
        scrollView.addSubview(scrollContainerView)
        scrollContainerView.translatesAutoresizingMaskIntoConstraints = false
        let scrollContainerViewFirstConstraint = NSLayoutConstraint(item: scrollContainerView!, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1, constant: 0)
        let scrollContainerViewSecondConstraint = NSLayoutConstraint(item: scrollContainerView!, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1, constant: 0)
        let scrollContainerViewThirdConstraint = NSLayoutConstraint(item: scrollContainerView!, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1, constant: 0)
        let scrollContainerViewFourthConstraint = NSLayoutConstraint(item: scrollContainerView!, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1, constant: 0)
        let scrollContainerViewFifthConstraint = NSLayoutConstraint(item: scrollContainerView!, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 1, constant: 0)
        let scrollContainerViewSixthConstraint = NSLayoutConstraint(item: scrollContainerView!, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: CGFloat(controllers.isEmpty ? 1 : controllers.count), constant: 0)
        scrollView.addConstraint(scrollContainerViewFirstConstraint)
        scrollView.addConstraint(scrollContainerViewSecondConstraint)
        scrollView.addConstraint(scrollContainerViewThirdConstraint)
        scrollView.addConstraint(scrollContainerViewFourthConstraint)
        scrollView.addConstraint(scrollContainerViewFifthConstraint)
        scrollView.addConstraint(scrollContainerViewSixthConstraint)
        
    }
    
    private func myController() -> UIViewController? {
        var controller: UIViewController?
        var responder = next
        while responder != nil {
            if responder! is UIViewController {
                controller = responder as? UIViewController
                break
            }
            responder = responder?.next
        }
        return controller
    }
    
    private func setupControllers() {
        guard !controllers.isEmpty && scrollContainerView.subviews.count == 0 else {
            return
        }
        if let myController = myController() {
            for (index, controller) in controllers.enumerated() {
                myController.addChild(controller)
                scrollContainerView.addSubview(controller.view)
                controller.view.translatesAutoresizingMaskIntoConstraints = false
                let controllerViewFirstConstraint = NSLayoutConstraint(item: controller.view!, attribute: .top, relatedBy: .equal, toItem: controller.view.superview, attribute: .top, multiplier: 1, constant: 0)
                let controllerViewSecondConstraint = NSLayoutConstraint(item: controller.view!, attribute: .bottom, relatedBy: .equal, toItem: controller.view.superview, attribute: .bottom, multiplier: 1, constant: 0)
                let controllerViewThirdConstraint = NSLayoutConstraint(item: controller.view!, attribute: .width, relatedBy: .equal, toItem: controller.view.superview, attribute: .width, multiplier: 1 / CGFloat(controllers.isEmpty ? 1 : controllers.count), constant: 0)
                var controllerViewFourthConstraint: NSLayoutConstraint?
                if index == 0 {
                    controllerViewFourthConstraint = NSLayoutConstraint(item: controller.view!, attribute: .leading, relatedBy: .equal, toItem: controller.view.superview, attribute: .leading, multiplier: 1, constant: 0)
                } else {
                    let previousController = controllers[index - 1]
                    controllerViewFourthConstraint = NSLayoutConstraint(item: controller.view!, attribute: .leading, relatedBy: .equal, toItem: previousController.view, attribute: .trailing, multiplier: 1, constant: 0)
                }
                scrollContainerView.addConstraint(controllerViewFirstConstraint)
                scrollContainerView.addConstraint(controllerViewSecondConstraint)
                scrollContainerView.addConstraint(controllerViewThirdConstraint)
                if let constaint = controllerViewFourthConstraint {
                    scrollContainerView.addConstraint(constaint)
                }
            }
        }
    }
    
    private func updateScrollContainerViewWidthConstraint() {
        var scrollContainerViewWidthConstraint: NSLayoutConstraint?
        for constraint in scrollContainerView.superview!.constraints {
            if (constraint.firstItem?.isEqual(scrollContainerView))! && constraint.firstAttribute == .width {
                scrollContainerViewWidthConstraint = constraint
                break
            }
        }
        guard scrollContainerViewWidthConstraint != nil else {
            return
        }
        scrollView.removeConstraint(scrollContainerViewWidthConstraint!)
        scrollContainerViewWidthConstraint = NSLayoutConstraint(item: scrollContainerView!, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: CGFloat(controllers.isEmpty ? 1 : controllers.count), constant: 0)
        scrollView.addConstraint(scrollContainerViewWidthConstraint!)
    }
    
    // MARK: - Observe
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillChangeStatusBarOrientation(_:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
    }
    
    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleApplicationWillChangeStatusBarOrientation(_ sender: Notification) {
        shouldResetPage = true
    }
    
    // MARK: - getter & setter
    
    private func didSetControllers(_ oldValue: [UIViewController]) {
        for oldController in oldValue {
            if let oldControllerViewSuperview = oldController.view.superview {
                if oldControllerViewSuperview.isEqual(scrollContainerView) {
                    oldController.view.removeFromSuperview()
                    oldController.removeFromParent()
                }
            }
        }
        updateScrollContainerViewWidthConstraint()
        setupControllers()
        if oldValue.isEmpty && !controllers.isEmpty  {
            setPageBySelf = true
            page = 0
            delegate?.pageView?(self, didSelect: controllers[page])
        } else if !oldValue.isEmpty && controllers.isEmpty {
            setPageBySelf = true
            page = 0
        } else if page >= controllers.count {
            page = 0
        }
    }
    
    private func didSetPage(_ oldValue: Int) {
        if setPageBySelf {
            setPageBySelf = false
        } else {
            setPage(page)
        }
        if page != oldValue && controllers.count > page {
            delegate?.pageView?(self, didSelect: controllers[page])
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width + 10
        currentPage = Int(floor(Double((scrollView.contentOffset.x - pageWidth / 2) / pageWidth))) + 1
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let pageWidth = scrollView.frame.width + 10
        var newPage: Int = 0
        if velocity.x == 0 {
            newPage = Int(floor((Double(targetContentOffset.pointee.x) - Double(pageWidth) / 2) / Double(pageWidth))) + 1
        } else {
            newPage = velocity.x > 0 ? currentPage + 1 : currentPage - 1
            newPage = max(0, newPage)
            newPage = min(controllers.count - 1, newPage)
            if CGFloat(newPage) > scrollView.contentSize.width / pageWidth {
                newPage = (Int)(ceil(Double(scrollView.contentSize.width / pageWidth)) - 1)
            }
        }
        targetContentOffset.pointee = CGPoint(x: CGFloat(newPage) * pageWidth, y: targetContentOffset.pointee.y)
        setPageBySelf = true
        page = newPage
        
    }

}
