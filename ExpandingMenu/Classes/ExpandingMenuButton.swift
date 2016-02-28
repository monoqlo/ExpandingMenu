//
//  ExpandingMenuButton.swift
//
//  Created by monoqlo on 2015/07/21.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit
import AudioToolbox

public struct AnimationOptions : OptionSetType {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public static let MenuItemRotation = AnimationOptions(rawValue: 1)
    public static let MenuItemBound = AnimationOptions(rawValue: 2)
    public static let MenuItemMoving = AnimationOptions(rawValue: 4)
    public static let MenuItemFade = AnimationOptions(rawValue: 8)
    
    public static let MenuButtonRotation = AnimationOptions(rawValue: 16)
    
    public static let Default: AnimationOptions = [MenuItemRotation, MenuItemBound, MenuItemMoving, MenuButtonRotation]
    public static let All: AnimationOptions = [MenuItemRotation, MenuItemBound, MenuItemMoving, MenuItemFade, MenuButtonRotation]
}

public class ExpandingMenuButton: UIView, UIGestureRecognizerDelegate {
    
    public enum ExpandingDirection {
        case Top
        case Bottom
    }
    
    public enum MenuTitleDirection {
        case Left
        case Right
    }
    
    // MARK: Public Properties
    public var menuItemMargin: CGFloat = 16.0
    
    public var allowSounds: Bool = true {
        didSet {
            self.configureSounds()
        }
    }
    
    public var expandingSoundPath: String = NSBundle(URL: NSBundle(forClass: ExpandingMenuButton.classForCoder()).URLForResource("ExpandingMenu", withExtension: "bundle")!)?.pathForResource("expanding", ofType: "caf") ?? "" {
        didSet {
            self.configureSounds()
        }
    }
    
    public var foldSoundPath: String = NSBundle(URL: NSBundle(forClass: ExpandingMenuButton.classForCoder()).URLForResource("ExpandingMenu", withExtension: "bundle")!)?.pathForResource("fold", ofType: "caf") ?? "" {
        didSet {
            self.configureSounds()
        }
    }
    
    public var selectedSoundPath: String = NSBundle(URL: NSBundle(forClass: ExpandingMenuButton.classForCoder()).URLForResource("ExpandingMenu", withExtension: "bundle")!)?.pathForResource("selected", ofType: "caf") ?? "" {
        didSet {
            self.configureSounds()
        }
    }
    
    public var bottomViewColor: UIColor = UIColor.blackColor() {
        didSet {
            self.bottomView.backgroundColor = bottomViewColor
        }
    }
    
    public var bottomViewAlpha: CGFloat = 0.618
    
    public var titleTappedActionEnabled: Bool = true
    
    public var expandingDirection: ExpandingDirection = ExpandingDirection.Top
    public var menuTitleDirection: MenuTitleDirection = MenuTitleDirection.Left
    
    public var enabledExpandingAnimations: AnimationOptions = .Default
    public var enabledFoldingAnimations: AnimationOptions = .Default
    
    public var willPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    public var didPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    public var willDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    public var didDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    
    // MARK: Private Properties
    private var defaultCenterPoint: CGPoint = CGPointZero
    
    private var itemButtonImages: [UIImage] = []
    private var itemButtonHighlightedImages: [UIImage] = []
    
    private var centerImage: UIImage?
    private var centerHighlightedImage: UIImage?
    
    private var expandingSize: CGSize = UIScreen.mainScreen().bounds.size
    private var foldedSize: CGSize = CGSizeZero
    
    private var bottomView: UIView = UIView()
    private var centerButton: UIButton = UIButton()
    private var menuItems: [ExpandingMenuItem] = []
    
    private var foldSound: SystemSoundID = 0
    private var expandingSound: SystemSoundID = 0
    private var selectedSound: SystemSoundID = 0
    
    private var isExpanding: Bool = false
    private var isAnimating: Bool = false
    
    
    // MARK: - Initializer
    public init(frame: CGRect, centerImage: UIImage, centerHighlightedImage: UIImage) {
        super.init(frame: frame)
        
        func configureViewsLayoutWithButtonSize(centerButtonSize: CGSize) {
            // Configure menu button frame
            //
            self.foldedSize = centerButtonSize
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.foldedSize.width, height: self.foldedSize.height);
            
            // Congifure center button
            //
            self.centerButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: centerButtonSize.width, height: centerButtonSize.height))
            self.centerButton.setImage(self.centerImage, forState: UIControlState.Normal)
            self.centerButton.setImage(self.centerHighlightedImage, forState: UIControlState.Highlighted)
            self.centerButton.addTarget(self, action: "centerButtonTapped", forControlEvents: UIControlEvents.TouchDown)
            self.centerButton.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
            self.addSubview(self.centerButton)
            
            // Configure bottom view
            //
            self.bottomView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.expandingSize.width, height: self.expandingSize.height))
            self.bottomView.backgroundColor = self.bottomViewColor
            self.bottomView.alpha = 0.0
            
            // Make bottomView's touch can delay superView witch like UIScrollView scrolling
            //
            self.bottomView.userInteractionEnabled = true;
            let tapGesture = UIGestureRecognizer()
            tapGesture.delegate = self
            self.bottomView.addGestureRecognizer(tapGesture)
        }
        
        // Configure enter and highlighted center image
        //
        self.centerImage = centerImage
        self.centerHighlightedImage = centerHighlightedImage
        
        if frame == CGRectZero {
            configureViewsLayoutWithButtonSize(self.centerImage?.size ?? CGSizeZero)
        } else {
            configureViewsLayoutWithButtonSize(frame.size)
            self.defaultCenterPoint = self.center
        }
        
        self.configureSounds()
    }
    
    public convenience init(centerImage: UIImage, centerHighlightedImage: UIImage) {
        self.init(frame: CGRectZero, centerImage: centerImage, centerHighlightedImage: centerHighlightedImage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Configure Menu Items
    public func addMenuItems(menuItems: [ExpandingMenuItem]) {
        self.menuItems += menuItems
    }
    
    // MARK: - Menu Item Tapped Action
    public func menuItemTapped(item: ExpandingMenuItem) {
        self.willDismissMenuItems?(self)
        self.isAnimating = true
        
        let selectedIndex: Int = item.index
        
        if self.allowSounds == true {
            AudioServicesPlaySystemSound(self.selectedSound)
        }
        
        // Excute the explode animation when the item is seleted
        //
        UIView.animateWithDuration(0.0618 * 5.0, animations: { () -> Void in
            item.transform = CGAffineTransformMakeScale(3.0, 3.0)
            item.alpha = 0.0
        })
        
        // Excute the dismiss animation when the item is unselected
        //
        for (index, item) in self.menuItems.enumerate() {
            // Remove title button
            //
            if let titleButton = item.titleButton {
                UIView.animateWithDuration(0.15, animations: { () -> Void in
                    titleButton.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        titleButton.removeFromSuperview()
                })
            }
            
            if index == selectedIndex {
                continue
            }
            
            UIView.animateWithDuration(0.0618 * 2.0, animations: { () -> Void in
                item.transform = CGAffineTransformMakeScale(0.0, 0.0)
            })
        }
        
        self.resizeToFoldedFrame { () -> Void in
            self.isAnimating = false
            self.didDismissMenuItems?(self)
        }
    }
    
    // MARK: - Center Button Action
    @objc private func centerButtonTapped() {
        if self.isAnimating == false {
            if self.isExpanding == true {
                self.foldMenuItems()
            } else {
                self.expandMenuItems()
            }
        }
    }
    
    // MARK: - Configure Sounds
    private func configureSounds() {
        if self.allowSounds == true {
            let expandingSoundUrl = NSURL(fileURLWithPath: self.expandingSoundPath)
            AudioServicesCreateSystemSoundID(expandingSoundUrl, &self.expandingSound)
            
            let foldSoundUrl = NSURL(fileURLWithPath: self.foldSoundPath)
            AudioServicesCreateSystemSoundID(foldSoundUrl, &self.foldSound)
            
            let selectedSoundUrl = NSURL(fileURLWithPath: self.selectedSoundPath)
            AudioServicesCreateSystemSoundID(selectedSoundUrl, &self.selectedSound)
        } else {
            AudioServicesDisposeSystemSoundID(self.expandingSound)
            AudioServicesDisposeSystemSoundID(self.foldSound)
            AudioServicesDisposeSystemSoundID(self.selectedSound)
        }
    }
    
    // MARK: - Calculate The Distance From Center Button
    private func makeDistanceFromCenterButton(itemSize: CGSize, lastDisance: CGFloat, lastItemSize: CGSize) -> CGFloat {
        return lastDisance + itemSize.height / 2.0 + self.menuItemMargin + lastItemSize.height / 2.0
    }
    
    // MARK: - Caculate The Item's End Point
    private func makeEndPoint(itemExpandRadius: CGFloat, angle: CGFloat) -> CGPoint {
        switch self.expandingDirection {
        case .Top:
            return CGPoint(
                x: self.centerButton.center.x + CGFloat(cosf((Float(angle) + 1.0) * Float(M_PI))) * itemExpandRadius,
                y: self.centerButton.center.y + CGFloat(sinf((Float(angle) + 1.0) * Float(M_PI))) * itemExpandRadius
            )
        case .Bottom:
            return CGPoint(
                x: self.centerButton.center.x + CGFloat(cosf(Float(angle) * Float(M_PI))) * itemExpandRadius,
                y: self.centerButton.center.y + CGFloat(sinf(Float(angle) * Float(M_PI))) * itemExpandRadius
            )
        }
    }
    
    // MARK: - Fold Menu Items
    private func foldMenuItems() {
        self.willDismissMenuItems?(self)
        self.isAnimating = true
        
        if self.allowSounds == true {
            AudioServicesPlaySystemSound(self.foldSound)
        }
        
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize: CGSize = self.centerButton.bounds.size
        
        for item in self.menuItems {
            let distance: CGFloat = self.makeDistanceFromCenterButton(item.bounds.size, lastDisance: lastDistance, lastItemSize: lastItemSize)
            lastDistance = distance
            lastItemSize = item.bounds.size
            let backwardPoint: CGPoint = self.makeEndPoint(distance + 5.0, angle: currentAngle / 180.0)
            
            let foldAnimation: CAAnimationGroup = self.makeFoldAnimation(startingPoint: item.center, backwardPoint: backwardPoint, endPoint: self.centerButton.center)
            
            item.layer.addAnimation(foldAnimation, forKey: "foldAnimation")
            item.center = self.centerButton.center
            
            // Remove title button
            //
            if let titleButton = item.titleButton {
                UIView.animateWithDuration(0.15, animations: { () -> Void in
                    titleButton.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        titleButton.removeFromSuperview()
                })
            }
        }
        
        self.bringSubviewToFront(self.centerButton)
        
        // Resize the ExpandingMenuButton's frame to the foled frame and remove the item buttons
        //
        self.resizeToFoldedFrame { () -> Void in
            self.isAnimating = false
            self.didDismissMenuItems?(self)
        }
    }
    
    private func resizeToFoldedFrame(completion completion: (() -> Void)?) {
        if self.enabledFoldingAnimations.contains(.MenuButtonRotation) == true {
            UIView.animateWithDuration(0.0618 * 3, delay: 0.0618 * 2, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                self.centerButton.transform = CGAffineTransformMakeRotation(0.0)
                }, completion: nil)
        } else {
            self.centerButton.transform = CGAffineTransformMakeRotation(0.0)
        }
        
        UIView.animateWithDuration(0.15, delay: 0.35, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            self.bottomView.alpha = 0.0
            }, completion: { (finished) -> Void in
                // Remove the items from the superview
                //
                for item in self.menuItems {
                    item.removeFromSuperview()
                }
                
                self.frame = CGRect(x: 0.0, y: 0.0, width: self.foldedSize.width, height: self.foldedSize.height)
                self.center = self.defaultCenterPoint
                
                self.centerButton.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
                
                self.bottomView.removeFromSuperview()
                
                completion?()
        })
        
        self.isExpanding = false
    }
    
    private func makeFoldAnimation(startingPoint startingPoint: CGPoint, backwardPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.animations = []
        animationGroup.duration = 0.35
        
        // 1.Configure rotation animation
        //
        if self.enabledFoldingAnimations.contains(.MenuItemRotation) == true {
            let rotationAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, M_PI, M_PI * 2.0]
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            rotationAnimation.duration = 0.35
            
            animationGroup.animations?.append(rotationAnimation)
        }
        
        // 2.Configure moving animation
        //
        let movingAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        
        // Create moving path
        //
        let path: CGMutablePathRef = CGPathCreateMutable()
        
        if self.enabledFoldingAnimations.contains([.MenuItemMoving, .MenuItemBound]) == true {
            CGPathMoveToPoint(path, nil, startingPoint.x, startingPoint.y)
            CGPathAddLineToPoint(path, nil, backwardPoint.x, backwardPoint.y)
            CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if self.enabledFoldingAnimations.contains(.MenuItemMoving) == true {
            CGPathMoveToPoint(path, nil, startingPoint.x, startingPoint.y)
            CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if self.enabledFoldingAnimations.contains(.MenuItemBound) == true {
            CGPathMoveToPoint(path, nil, startingPoint.x, startingPoint.y)
            CGPathAddLineToPoint(path, nil, backwardPoint.x, backwardPoint.y)
            CGPathAddLineToPoint(path, nil, startingPoint.x, startingPoint.y)
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if self.enabledFoldingAnimations.contains(.MenuItemFade) {
            CGPathMoveToPoint(path, nil, startingPoint.x, startingPoint.y)
            CGPathAddLineToPoint(path, nil, startingPoint.x, startingPoint.y)
        }
        
        movingAnimation.path = path
        movingAnimation.duration = 0.35
        
        animationGroup.animations?.append(movingAnimation)
        
        // 3.Configure fade animation
        //
        if self.enabledFoldingAnimations.contains(.MenuItemFade) {
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [1.0, 0.0]
            fadeAnimation.keyTimes = [0.0, 0.75, 1.0]
            fadeAnimation.duration = 0.35
            animationGroup.animations?.append(fadeAnimation)
        }
        
        return animationGroup
    }
    
    
    // MARK: - Expand Menu Items
    private func expandMenuItems() {
        self.willPresentMenuItems?(self)
        self.isAnimating = false
        
        if self.allowSounds == true {
            AudioServicesPlaySystemSound(self.expandingSound)
        }
        
        // Configure center button expanding
        //
        // 1. Copy the current center point and backup default center point
        //
        self.centerButton.center = self.center
        self.defaultCenterPoint = self.center
        
        // 2. Resize the frame
        //
        self.frame = CGRect(x: 0.0, y: 0.0, width: self.expandingSize.width, height: self.expandingSize.height)
        self.center = CGPoint(x: self.expandingSize.width / 2.0, y: self.expandingSize.height / 2.0)
        
        self.insertSubview(self.bottomView, belowSubview: self.centerButton)
        
        // 3. Excute the bottom view alpha animation
        //
        UIView.animateWithDuration(0.0618 * 3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.bottomView.alpha = self.bottomViewAlpha
            }, completion: nil)
        
        // 4. Excute the center button rotation animation
        //
        if self.enabledExpandingAnimations.contains(.MenuButtonRotation) == true {
            UIView.animateWithDuration(0.1575, animations: { () -> Void in
                self.centerButton.transform = CGAffineTransformMakeRotation(CGFloat(-0.5 * M_PI))
            })
        } else {
            self.centerButton.transform = CGAffineTransformMakeRotation(CGFloat(-0.5 * M_PI))
        }
        
        // 5. Excute the expanding animation
        //
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize: CGSize = self.centerButton.bounds.size
        
        for (index, item) in self.menuItems.enumerate() {
            item.delegate = self
            item.index = index
            item.transform = CGAffineTransformMakeTranslation(1.0, 1.0)
            item.alpha = 1.0
            
            // 1. Add item to the view
            //
            item.center = self.centerButton.center
            
            self.insertSubview(item, belowSubview: self.centerButton)
            
            // 2. Excute expand animation
            //
            let distance: CGFloat = self.makeDistanceFromCenterButton(item.bounds.size, lastDisance: lastDistance, lastItemSize: lastItemSize)
            lastDistance = distance
            lastItemSize = item.bounds.size
            let endPoint: CGPoint = self.makeEndPoint(distance, angle: currentAngle / 180.0)
            let farPoint: CGPoint = self.makeEndPoint(distance + 10.0, angle: currentAngle / 180.0)
            let nearPoint: CGPoint = self.makeEndPoint(distance - 5.0, angle: currentAngle / 180.0)
            
            let expandingAnimation: CAAnimationGroup = self.makeExpandingAnimation(startingPoint: item.center, farPoint: farPoint, nearPoint: nearPoint, endPoint: endPoint)
            
            item.layer.addAnimation(expandingAnimation, forKey: "expandingAnimation")
            item.center = endPoint
            
            // 3. Add Title Button
            //
            item.titleTappedActionEnabled = self.titleTappedActionEnabled
            
            if let titleButton = item.titleButton {
                titleButton.center = endPoint
                let margin: CGFloat = 8.0
                
                let originX: CGFloat
                
                switch self.menuTitleDirection {
                case .Left:
                    originX = endPoint.x - item.bounds.width / 2.0 - margin - titleButton.bounds.width
                case .Right:
                    originX = endPoint.x + item.bounds.width / 2.0 + margin;
                }
                
                var titleButtonFrame: CGRect = titleButton.frame
                titleButtonFrame.origin.x = originX
                titleButton.frame = titleButtonFrame
                titleButton.alpha = 0.0
                
                self.insertSubview(titleButton, belowSubview: self.centerButton)
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    titleButton.alpha = 1.0
                })
            }
        }
        
        // Configure the expanding status
        //
        self.isExpanding = true
        self.isAnimating = false
        
        self.didPresentMenuItems?(self)
    }
    
    private func makeExpandingAnimation(startingPoint startingPoint: CGPoint, farPoint: CGPoint, nearPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.animations = []
        animationGroup.duration = 0.3
        
        // 1.Configure rotation animation
        //
        if self.enabledExpandingAnimations.contains(.MenuItemRotation) == true {
            let rotationAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, -M_PI, -M_PI * 1.5, -M_PI * 2.0]
            rotationAnimation.duration = 0.3
            rotationAnimation.keyTimes = [0.0, 0.3, 0.6, 1.0]
            
            animationGroup.animations?.append(rotationAnimation)
        }
        
        // 2.Configure moving animation
        //
        let movingAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        
        // Create moving path
        //
        let path: CGMutablePathRef = CGPathCreateMutable()
        
        if self.enabledExpandingAnimations.contains([.MenuItemMoving, .MenuItemBound]) == true {
            CGPathMoveToPoint(path, nil, startingPoint.x, startingPoint.y)
            CGPathAddLineToPoint(path, nil, farPoint.x, farPoint.y)
            CGPathAddLineToPoint(path, nil, nearPoint.x, nearPoint.y)
            CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
            
            movingAnimation.keyTimes = [0.0, 0.5, 0.7, 1.0]
        } else if self.enabledExpandingAnimations.contains(.MenuItemMoving) == true {
            CGPathMoveToPoint(path, nil, startingPoint.x, startingPoint.y)
            CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
            
            movingAnimation.keyTimes = [0.0, 0.5, 1.0]
        } else if self.enabledExpandingAnimations.contains(.MenuItemBound) == true {
            CGPathMoveToPoint(path, nil, farPoint.x, farPoint.y)
            CGPathAddLineToPoint(path, nil, nearPoint.x, nearPoint.y)
            CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if self.enabledExpandingAnimations.contains(.MenuItemFade) {
            CGPathMoveToPoint(path, nil, endPoint.x, endPoint.y)
            CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
        }
        
        movingAnimation.path = path
        movingAnimation.duration = 0.3
        
        animationGroup.animations?.append(movingAnimation)
        
        // 3.Configure fade animation
        //
        if self.enabledExpandingAnimations.contains(.MenuItemFade) {
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [0.0, 1.0]
            fadeAnimation.duration = 0.3
            animationGroup.animations?.append(fadeAnimation)
        }
        
        return animationGroup
    }
    
    // MARK: - Touch Event
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Tap the bottom area, excute the fold animation
        self.foldMenuItems()
    }
    
    // MARK: - UIGestureRecognizer Delegate
    override public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
