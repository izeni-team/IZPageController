//
//  IZPageController.swift
//  IZPageController
//
//  Created by Christopher Bryan Henderson on 1/17/16.
//  Copyright © 2016 Izeni. All rights reserved.
//

import UIKit

@objc public protocol IZPageControllerDelegate: class {
    func numberOfViewControllers() -> Int
    func viewControllerAtIndex(index: Int) -> UIViewController
    optional func pageIndexChanged() // Called when scrollIndex == pageIndex && pageIndex != lastPageIndex. Called before scrollIndexChanged().
    optional func scrollProgressUpdated() // Called on UIScrollView's didScroll. Called after pageIndexChanged().
}

public protocol IZPageViewControllerDelegate: class {
    
}

public class IZPageController: UIViewController, UIScrollViewDelegate {
    public enum UpdateArea {
        case Preload
        case Visible
    }
    
    public let scrollView = UIScrollView()
    public var viewControllers = [UIViewController?]() // May decide to dealloc view controllers at own discretion
    public weak var delegate: IZPageControllerDelegate? {
        didSet {
            if delegate !== oldValue {
                reloadData()
            }
        }
    }
    
    public var previouslyReportedPageIndex: Int?
    public var pageIndex: Int? {
        if viewControllers.isEmpty {
            return nil
        } else {
            return Int(pageIndexAtX(scrollView.contentOffset.x))
        }
    }
    
    // 0.0 to 1.0. Might return negative or > 1.0
    public var scrollProgress: CGFloat {
        let maxOffset = scrollView.contentSize.width - scrollView.frame.width
        if maxOffset != 0 {
            return scrollView.contentOffset.x / maxOffset
        } else {
            return 0
        }
    }
    
    public var visiblePageIndexes: [Int] {
        return indexesIntersecting(CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size))
    }
    
    public func pageIndexAtX(x: CGFloat) -> CGFloat {
        if scrollView.frame.width != 0 && viewControllers.count > 0 {
            return max(x / sizeOfViewController().width, 0)
        } else {
            return 0
        }
    }
    
    public func indexesIntersecting(frame: CGRect) -> [Int] {
        return (0..<viewControllers.count).filter({ CGRectIntersectsRect(self.frameForViewControllerAtIndex($0), frame) })
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.backgroundColor = .whiteColor()
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let previouslyVisible = self.currentlyVisibleIndex()
        scrollView.frame.size = view.frame.size
        updateViewControllers(add: false, remove: false, area: .Visible)
        self.updateContentOffsetAfterRotation(previouslyVisible)
        self.updatePageIndex()
    }
    
    public func currentlyVisibleIndex() -> Int {
        return visiblePageIndexes.first ?? 0
    }
    
    public func updateContentOffsetAfterRotation(previousIndex: Int) {
        var offset = frameForViewControllerAtIndex(previousIndex).origin
        offset.x = min(max(offset.x, 0), scrollView.contentSize.width - scrollView.frame.width)
        offset.y = min(max(offset.y, 0), scrollView.contentSize.height - scrollView.frame.height)
        scrollView.setContentOffset(offset, animated: false)
    }
    
    public func reloadData() {
        for it in viewControllers.enumerate() {
            removeViewControllerAtIndex(it.index)
        }
        viewControllers = (0..<(delegate?.numberOfViewControllers() ?? 0)).map({ _ in nil })
        updateViewControllers(add: true, remove: true, area: .Preload)
    }
    
    public func preloadArea() -> CGRect {
        return CGRect(x: scrollView.contentOffset.x - scrollView.frame.width, y: 0, width: scrollView.frame.width * 3, height: scrollView.frame.height)
    }
    
    public func updateViewControllers(add add: Bool, remove: Bool, area: UpdateArea) {
        assert(delegate == nil || delegate!.numberOfViewControllers() == viewControllers.count, "You changed number of view controllers without calling reloadData(). Please call reloadData() immediately after changing the count.")
        if add || remove {
            let indexesOfInterest: [Int]
            switch area {
            case .Preload:
                indexesOfInterest = indexesIntersecting(preloadArea())
            case .Visible:
                indexesOfInterest = visiblePageIndexes
            }
            
            if add {
                for index in indexesOfInterest {
                    addViewControllerAtIndex(index)
                }
            }
            if remove {
                for index in Set(0..<viewControllers.count).subtract(indexesOfInterest) {
                    removeViewControllerAtIndex(index)
                }
            }
        }
        
        // Update frames (i.e., on rotate device).
        for index in 0..<viewControllers.count {
            if let vc = viewControllers[index] {
                let shouldBe = frameForViewControllerAtIndex(index)
                if vc.view.frame != shouldBe {
                    vc.view.frame = shouldBe
                }
            }
        }
        
        scrollView.contentSize = CGSize(width: CGFloat(viewControllers.count) * sizeOfViewController().width, height: scrollView.frame.height)
    }
    
    public func addViewControllerAtIndex(pageIndex: Int) {
        if pageIndex >= 0 && pageIndex < viewControllers.count && viewControllers[pageIndex] == nil, let vc = delegate?.viewControllerAtIndex(pageIndex) {
            viewControllers[pageIndex] = vc
            vc.willMoveToParentViewController(self)
            self.addChildViewController(vc)
            scrollView.addSubview(vc.view)
            vc.view.frame = frameForViewControllerAtIndex(pageIndex)
            vc.didMoveToParentViewController(self)
        }
    }
    
    public func removeViewControllerAtIndex(pageIndex: Int) {
        if pageIndex >= 0 && pageIndex < viewControllers.count, let vc = viewControllers[pageIndex] {
            vc.willMoveToParentViewController(nil)
            vc.view.removeFromSuperview()
            vc.didMoveToParentViewController(nil)
            viewControllers[pageIndex] = nil
        }
    }
    
    public func frameForViewControllerAtIndex(index: Int) -> CGRect {
        let size = sizeOfViewController()
        return CGRect(x: CGFloat(index) * sizeOfViewController().width, y: 0, width: size.width, height: size.height)
    }
    
    public func sizeOfViewController() -> CGSize {
        return scrollView.frame.size
    }
    
    public func updatePageIndex() {
        if let pageIndex = pageIndex where previouslyReportedPageIndex != pageIndex {
            previouslyReportedPageIndex = pageIndex
            delegate?.pageIndexChanged?()
            previouslyReportedPageIndex = pageIndex
        }
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        updateViewControllers(add: true, remove: false, area: .Visible)
        delegate?.scrollProgressUpdated?()
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updatePageIndex()
        updateViewControllers(add: true, remove: true, area: .Preload)
    }
}