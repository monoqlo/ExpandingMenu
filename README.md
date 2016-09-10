# ExpandingMenu

[![CI Status](http://img.shields.io/travis/monoqlo/ExpandingMenu.svg?style=flat)](https://travis-ci.org/monoqlo/ExpandingMenu)
[![Version](https://img.shields.io/cocoapods/v/ExpandingMenu.svg?style=flat)](http://cocoapods.org/pods/ExpandingMenu)
[![License](https://img.shields.io/cocoapods/l/ExpandingMenu.svg?style=flat)](http://cocoapods.org/pods/ExpandingMenu)
[![Platform](https://img.shields.io/cocoapods/p/ExpandingMenu.svg?style=flat)](http://cocoapods.org/pods/ExpandingMenu)

![demo](https://github.com/monoqlo/ExpandingMenu/blob/master/imgs/demo.gif)

ExpandingMenu is written in Swift.

## Requirements

- iOS 8.0+
- Xcode 8.0+

## Installation

### CocoaPods

You can install [CocoaPods](http://cocoapods.org) with the following command:

```bash
$ gem install cocoapods
```

To integrate ExpandingMenu into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'ExpandingMenu', '~> 0.3'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

You can install [Carthage](https://github.com/Carthage/Carthage) with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate ExpandingMenu into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "monoqlo/ExpandingMenu" ~> 0.3
```

Run `carthage update` to build the framework and drag the built `ExpandingMenu.framework` into your Xcode project.

### Manually
1. Download and drop ```/ExpandingMenu```folder in your project.  
2. Congratulations!  

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

## Customize

### ExpandingMenuButton

```swift
// Bottom dim view
menuButton.bottomViewColor = UIColor.redColor()
menuButton.bottomViewAlpha = 0.2

// Whether the tapped action fires when title are tapped
menuButton.titleTappedActionEnabled = false

// Menu item direction
menuButton.expandingDirection = .Bottom
menuButton.menuTitleDirection = .Right

// The action when the menu appears/disappears
menuButton.willPresentMenuItems = { (menu) -> Void in
    print("MenuItems will present.")
}

menuButton.didPresentMenuItems = { (menu) -> Void in
    print("MenuItems will present.")
}
        
menuButton.willDismissMenuItems = { (menu) -> Void in
    print("MenuItems dismissed.")
}

menuButton.didDismissMenuItems = { (menu) -> Void in
    print("MenuItems will present.")
}

// Expanding Animation
menuButton.enabledExpandingAnimations = [] // No animation

menuButton.enabledExpandingAnimations = AnimationOptions.All.exclusiveOr(.MenuItemRotation)

// Folding Animation
menuButton.enabledFoldingAnimations = .All

menuButton.enabledFoldingAnimations = [.MenuItemMoving, .MenuItemFade, .MenuButtonRotation]
```


### ExpandingMenuItem

```swift
// Title
item.title = "text"
item.titleColor = UIColor.redColor()

// Title margin to menu item
item.titleMargin = 4
```

## Author

monoqlo, monoqlo44@gmail.com

## License

ExpandingMenu is available under the MIT license. See the LICENSE file for more info.
