// Copyright (c) 2016 Izeni
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom
// the Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
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
        case Preload // We want to preload the adjacent pages.
        case Visible // Only load view controllers we'll actually see.
    }
    
    // How many adjacent, non-visible view controllers to keep in memory.
    public var preloadDistance: UInt = 1
    
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
        return visiblePageIndexes.first
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
        let visibleFrame = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        return (0..<viewControllers.count).filter({
            CGRectIntersectsRect(self.frameForViewControllerAtIndex($0), visibleFrame)
        })
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
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let previouslyVisible = self.currentlyVisibleIndex()
        updateLayout(size)
        self.updateContentOffsetAfterRotation(previouslyVisible)
        self.updatePageIndex()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout(view.frame.size)
    }
    
    public func updateLayout(size: CGSize) {
        // viewDidLayoutSubviews() gets called multiple times. We shouldn't do anything unless the size changes to avoid unwanted side effects.
        if scrollView.frame.size != size {
            scrollView.frame.size = size
            updateViewControllers(.Visible)
        }
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
        assert(scrollView.frame.size != CGSizeZero, "Can't properly calculate dimensions with zero size.")
        for it in viewControllers.enumerate() {
            removeViewControllerAtIndex(it.index)
        }
        viewControllers = []
        for _ in 0..<(delegate?.numberOfViewControllers() ?? 0) {
            viewControllers.append(nil)
        }
        updateViewControllers(.Preload)
    }
    
    public func updateViewControllers(area: UpdateArea) {
        assert(delegate == nil || delegate!.numberOfViewControllers() == viewControllers.count, "You changed number of view controllers without calling reloadData(). Please call reloadData() immediately after changing the count.")
        let preloadArea: [Int]
        let visibleArea = visiblePageIndexes
        if visibleArea.isEmpty {
            preloadArea = []
        } else {
            let left = max(0, visibleArea.first! - Int(preloadDistance))
            let right = min(viewControllers.count - 1, visibleArea.last! + Int(preloadDistance))
            preloadArea = [Int](left...right)
        }
        
        // When scrolling, only ever add visible view controllers.
        for index in area == .Preload ? preloadArea : visibleArea {
            addViewControllerAtIndex(index)
        }
        
        // When removing, only ever consider view controllers outside of the preload area, which is >= visible area.
        for index in Set(0..<viewControllers.count).subtract(preloadArea) {
            removeViewControllerAtIndex(index)
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
            viewControllers[pageIndex] = nil
            vc.willMoveToParentViewController(nil)
            vc.view.removeFromSuperview()
            vc.didMoveToParentViewController(nil)
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
        updateViewControllers(.Visible)
        delegate?.scrollProgressUpdated?()
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updatePageIndex()
        updateViewControllers(.Preload)
    }
}