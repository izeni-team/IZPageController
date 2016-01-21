//
//  TestPageController.swift
//  IZPageController
//
//  Created by Christopher Bryan Henderson on 1/17/16.
//  Copyright © 2016 Izeni. All rights reserved.
//

import UIKit

class TestPageController: IZPageController, IZPageControllerDelegate {
    var dualView: Bool {
        return scrollView.frame.width >= 320 * 2 // 320 points is width of iPhone 4s/5/5s, the skinniest devices supported as of 2016.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func numberOfViewControllers() -> Int {
        return 4
    }

    func viewControllerAtIndex(index: Int) -> UIViewController {
        let vc = UIViewController()
        switch index {
        case 0:
            vc.view.backgroundColor = .redColor()
        case 1:
            vc.view.backgroundColor = .blueColor()
        case 2:
            vc.view.backgroundColor = .greenColor()
        case 3:
            vc.view.backgroundColor = .yellowColor()
        default:
            vc.view.backgroundColor = .lightGrayColor()
        }
        vc.view.backgroundColor = vc.view.backgroundColor!.colorWithAlphaComponent(0.5)
        return vc
    }
    
    override func sizeOfViewController() -> CGSize {
        if dualView {
            return CGSize(width: scrollView.frame.width / 2, height: scrollView.frame.height)
        } else {
            return scrollView.frame.size
        }
    }
    
    override func updateContentOffsetAfterRotation(previousIndex: Int) {
        if dualView {
            super.updateContentOffsetAfterRotation(previousIndex - previousIndex % 2)
        } else {
            super.updateContentOffsetAfterRotation(previousIndex)
        }
    }
    
    func pageIndexChanged() {
        
    }
}