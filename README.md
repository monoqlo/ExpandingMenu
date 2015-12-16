# ExpandingMenu

[![CI Status](http://img.shields.io/travis/monoqlo/ExpandingMenu.svg?style=flat)](https://travis-ci.org/monoqlo/ExpandingMenu)
[![Version](https://img.shields.io/cocoapods/v/ExpandingMenu.svg?style=flat)](http://cocoapods.org/pods/ExpandingMenu)
[![License](https://img.shields.io/cocoapods/l/ExpandingMenu.svg?style=flat)](http://cocoapods.org/pods/ExpandingMenu)
[![Platform](https://img.shields.io/cocoapods/p/ExpandingMenu.svg?style=flat)](http://cocoapods.org/pods/ExpandingMenu)

![Screenshot1](https://dl.dropboxusercontent.com/u/986626/github/ExpandingMenu/screenshot1.png)
![Screenshot2](https://dl.dropboxusercontent.com/u/986626/github/ExpandingMenu/screenshot2.png)

ExpandingMenu is written in Swift.

## Requirements

- iOS 8.0+
- Xcode 7.0+

## Installation

### CocoaPods

ExpandingMenu is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ExpandingMenu"
```

### Carthage

To integrate ExpandingMenu into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your `Cartfile`:

```ogdl
github "monoqlo/ExpandingMenu"
```

Run `carthage update` to build the framework and drag the built `ExpandingMenu.framework` into your Xcode project.


## Usage

```swift
import ExpandingMenu

let menuButtonSize: CGSize = CGSize(width: 64.0, height: 64.0)
let menuButton = ExpandingMenuButton(frame: CGRect(origin: CGPointZero, size: menuButtonSize), centerImage: UIImage(named: "chooser-button-tab")!, centerHighlightedImage: UIImage(named: "chooser-button-tab-highlighted")!)
menuButton.center = CGPointMake(self.view.bounds.width - 32.0, self.view.bounds.height - 72.0)
view.addSubview(menuButton)

let item1 = ExpandingMenuItem(size: menuButtonSize, title: "Music", image: UIImage(named: "chooser-moment-icon-music")!, highlightedImage: UIImage(named: "chooser-moment-icon-music-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            // Do some action
        }

・・・

let item5 = ExpandingMenuItem(size: menuButtonSize, title: "Sleep", image: UIImage(named: "chooser-moment-icon-sleep")!, highlightedImage: UIImage(named: "chooser-moment-icon-sleep-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            // Do some action
        }
        
menuButton.addMenuItems([item1, item2, item3, item4, item5])
```

## Author

monoqlo, monoqlo44@gmail.com

## License

ExpandingMenu is available under the MIT license. See the LICENSE file for more info.
