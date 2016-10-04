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
    func viewController(at index: Int) -> UIViewController
    @objc optional func pageIndexChanged() // Called when scrollIndex == pageIndex && pageIndex != lastPageIndex. Called before scrollIndexChanged().
    @objc optional func scrollProgressUpdated() // Called on UIScrollView's didScroll. Called after pageIndexChanged().
}

public protocol IZPageViewControllerDelegate: class {
    
}

open class IZPageController: UIViewController, UIScrollViewDelegate {
    public enum UpdateArea {
        case preload // We want to preload the adjacent pages.
        case visible // Only load view controllers we'll actually see.
    }
    
    // How many adjacent, non-visible view controllers to keep in memory.
    open var preloadDistance: UInt = 1
    
    open let scrollView = UIScrollView()
    open var viewControllers = [UIViewController?]() // May decide to dealloc view controllers at own discretion
    open weak var delegate: IZPageControllerDelegate? {
        didSet {
            if delegate !== oldValue {
                reloadData()
            }
        }
    }
    
    open var previouslyReportedPageIndex: Int?
    open var pageIndex: Int? {
        return visiblePageIndexes.first
    }
    
    // 0.0 to 1.0. Might return negative or > 1.0
    open var scrollProgress: CGFloat {
        let maxOffset = scrollView.contentSize.width - scrollView.frame.width
        if maxOffset != 0 {
            return scrollView.contentOffset.x / maxOffset
        } else {
            return 0
        }
    }
    
    open var visiblePageIndexes: [Int] {
        let visibleFrame = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        return (0..<viewControllers.count).filter({
            self.frameForViewController(at: $0).intersects(visibleFrame)
        })
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.backgroundColor = .white
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let previouslyVisible = self.currentlyVisibleIndex()
        updateLayout(size: size)
        self.updateContentOffsetAfterRotation(previousIndex: previouslyVisible)
        self.updatePageIndex()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout(size: view.frame.size)
    }
    
    open func updateLayout(size: CGSize) {
        // viewDidLayoutSubviews() gets called multiple times. We shouldn't do anything unless the size changes to avoid unwanted side effects.
        if scrollView.frame.size != size {
            scrollView.frame.size = size
            updateViewControllers(area: .visible)
        }
    }
    
    open func currentlyVisibleIndex() -> Int {
        return visiblePageIndexes.first ?? 0
    }
    
    open func updateContentOffsetAfterRotation(previousIndex: Int) {
        var offset = frameForViewController(at: previousIndex).origin
        offset.x = min(max(offset.x, 0), scrollView.contentSize.width - scrollView.frame.width)
        offset.y = min(max(offset.y, 0), scrollView.contentSize.height - scrollView.frame.height)
        scrollView.setContentOffset(offset, animated: false)
    }
    
    open func reloadData() {
        assert(scrollView.frame.size != CGSize.zero, "Can't properly calculate dimensions with zero size.")
        for it in viewControllers.enumerated() {
            removeViewController(at: it.offset)
        }
        viewControllers = []
        for _ in 0..<(delegate?.numberOfViewControllers() ?? 0) {
            viewControllers.append(nil)
        }
        updateViewControllers(area: .preload)
    }
    
    open func updateViewControllers(area: UpdateArea) {
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
        for index in area == .preload ? preloadArea : visibleArea {
            addViewController(at: index)
        }
        
        // When removing, only ever consider view controllers outside of the preload area, which is >= visible area.
        for index in Set(0..<viewControllers.count).subtracting(preloadArea) {
            removeViewController(at: index)
        }
        
        // Update frames (i.e., on rotate device).
        for index in 0..<viewControllers.count {
            if let vc = viewControllers[index] {
                let shouldBe = frameForViewController(at: index)
                if vc.view.frame != shouldBe {
                    vc.view.frame = shouldBe
                }
            }
        }
        
        scrollView.contentSize = CGSize(width: CGFloat(viewControllers.count) * sizeOfViewController().width, height: scrollView.frame.height)
    }
    
    open func addViewController(at pageIndex: Int) {
        if pageIndex >= 0 && pageIndex < viewControllers.count && viewControllers[pageIndex] == nil, let vc = delegate?.viewController(at: pageIndex) {
            viewControllers[pageIndex] = vc
            vc.willMove(toParentViewController: self)
            self.addChildViewController(vc)
            scrollView.addSubview(vc.view)
            vc.view.frame = frameForViewController(at: pageIndex)
            vc.didMove(toParentViewController: self)
        }
    }
    
    open func removeViewController(at pageIndex: Int) {
        if pageIndex >= 0 && pageIndex < viewControllers.count, let vc = viewControllers[pageIndex] {
            viewControllers[pageIndex] = nil
            vc.willMove(toParentViewController: nil)
            vc.view.removeFromSuperview()
            vc.didMove(toParentViewController: nil)
        }
    }
    
    open func frameForViewController(at index: Int) -> CGRect {
        let size = sizeOfViewController()
        return CGRect(x: CGFloat(index) * sizeOfViewController().width, y: 0, width: size.width, height: size.height)
    }
    
    open func sizeOfViewController() -> CGSize {
        return scrollView.frame.size
    }
    
    open func scrollToViewController(at index : Int, animated : Bool) {
        
        let frame = frameForViewController(at: index)
        
        if animated {
            UIView.animate(withDuration: 0, animations: {
                self.scrollView.scrollRectToVisible(frame, animated: true)
                
                }, completion: { (success) in
                    if success {
                        self.updatePageIndex()
                    }
            })
        } else {
            scrollView.scrollRectToVisible(frame, animated: false)
            updatePageIndex()
        }
    }
    
    open func updatePageIndex() {
        if let pageIndex = pageIndex, previouslyReportedPageIndex != pageIndex {
            previouslyReportedPageIndex = pageIndex
            delegate?.pageIndexChanged?()
            previouslyReportedPageIndex = pageIndex
        }
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateViewControllers(area: .visible)
        delegate?.scrollProgressUpdated?()
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePageIndex()
        updateViewControllers(area: .preload)
    }
}
