# IZPageController

[![CI Status](http://img.shields.io/travis/Taylor/IZPageController.svg?style=flat)](https://travis-ci.org/Taylor/IZPageController)
[![Version](https://img.shields.io/cocoapods/v/IZPageController.svg?style=flat)](http://cocoapods.org/pods/IZPageController)
[![License](https://img.shields.io/cocoapods/l/IZPageController.svg?style=flat)](http://cocoapods.org/pods/IZPageController)
[![Platform](https://img.shields.io/cocoapods/p/IZPageController.svg?style=flat)](http://cocoapods.org/pods/IZPageController)

## Requirements

## Installation

IZPageController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "IZPageController"
```

## Author

Taylor, tallred@izeni.com

## License

IZPageController is available under the MIT license. See the LICENSE file for more info.

## Example

```Swift
import UIKit
import IZPageController

class ViewController: IZPageController, IZPageControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    var dualView: Bool {
        return scrollView.frame.width >= 320 * 2
    }

    func numberOfViewControllers() -> Int {
        return 4
    }

    func viewController(at index: Int) -> UIViewController {
        let vc = UIViewController()
        switch index {
        case 0:
            vc.view.backgroundColor = .red
        case 1:
            vc.view.backgroundColor = .blue
        case 2:
            vc.view.backgroundColor = .green
        case 3:
            vc.view.backgroundColor = .yellow
        default:
            vc.view.backgroundColor = .lightGray
        }
        vc.view.backgroundColor = vc.view.backgroundColor!.withAlphaComponent(0.5)
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
            super.updateContentOffsetAfterRotation(previousIndex: previousIndex - previousIndex % 2)
        } else {
            super.updateContentOffsetAfterRotation(previousIndex: previousIndex)
        }
    }
}
```
