//
//  ExpandingMenuButton.swift
//
//  Created by monoqlo on 2015/07/21.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit
import AudioToolbox

public struct AnimationOptions : OptionSet {
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

open class ExpandingMenuButton: UIView, UIGestureRecognizerDelegate {
    
    public enum ExpandingDirection {
        case top
        case bottom
    }
    
    public enum MenuTitleDirection {
        case left
        case right
    }
    
    // MARK: Public Properties
    open var menuItemMargin: CGFloat = 16.0
    
    open var allowSounds: Bool = true {
        didSet {
            self.configureSounds()
        }
    }
    
    open var expandingSoundPath: String = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "expanding", ofType: "caf") ?? "" {
        didSet {
            self.configureSounds()
        }
    }
    
    open var foldSoundPath: String = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "fold", ofType: "caf") ?? "" {
        didSet {
            self.configureSounds()
        }
    }
    
    open var selectedSoundPath: String = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "selected", ofType: "caf") ?? "" {
        didSet {
            self.configureSounds()
        }
    }
    
    open var bottomViewColor: UIColor = UIColor.black {
        didSet {
            self.bottomView.backgroundColor = bottomViewColor
        }
    }
    
    open var bottomViewAlpha: CGFloat = 0.618
    
    open var titleTappedActionEnabled: Bool = true
    
    open var expandingDirection: ExpandingDirection = ExpandingDirection.top
    open var menuTitleDirection: MenuTitleDirection = MenuTitleDirection.left
    
    open var enabledExpandingAnimations: AnimationOptions = .Default
    open var enabledFoldingAnimations: AnimationOptions = .Default
    
    open var willPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    open var didPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    open var willDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    open var didDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    
    // MARK: Private Properties
    fileprivate var defaultCenterPoint: CGPoint = CGPoint.zero
    
    fileprivate var itemButtonImages: [UIImage] = []
    fileprivate var itemButtonHighlightedImages: [UIImage] = []
    
    fileprivate var centerImage: UIImage?
    fileprivate var centerHighlightedImage: UIImage?
    
    fileprivate var expandingSize: CGSize = UIScreen.main.bounds.size
    fileprivate var foldedSize: CGSize = CGSize.zero
    
    fileprivate var bottomView: UIView = UIView()
    fileprivate var centerButton: UIButton = UIButton()
    fileprivate var menuItems: [ExpandingMenuItem] = []
    
    fileprivate var foldSound: SystemSoundID = 0
    fileprivate var expandingSound: SystemSoundID = 0
    fileprivate var selectedSound: SystemSoundID = 0
    
    fileprivate var isExpanding: Bool = false
    fileprivate var isAnimating: Bool = false
    
    
    // MARK: - Initializer
    public init(frame: CGRect, centerImage: UIImage, centerHighlightedImage: UIImage) {
        super.init(frame: frame)
        
        func configureViewsLayoutWithButtonSize(_ centerButtonSize: CGSize) {
            // Configure menu button frame
            //
            self.foldedSize = centerButtonSize
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.foldedSize.width, height: self.foldedSize.height);
            
            // Congifure center button
            //
            self.centerButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: centerButtonSize.width, height: centerButtonSize.height))
            self.centerButton.setImage(self.centerImage, for: UIControlState())
            self.centerButton.setImage(self.centerHighlightedImage, for: UIControlState.highlighted)
            self.centerButton.addTarget(self, action: #selector(centerButtonTapped), for: UIControlEvents.touchDown)
            self.centerButton.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
            self.addSubview(self.centerButton)
            
            // Configure bottom view
            //
            self.bottomView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.expandingSize.width, height: self.expandingSize.height))
            self.bottomView.backgroundColor = self.bottomViewColor
            self.bottomView.alpha = 0.0
            
            // Make bottomView's touch can delay superView witch like UIScrollView scrolling
            //
            self.bottomView.isUserInteractionEnabled = true;
            let tapGesture = UIGestureRecognizer()
            tapGesture.delegate = self
            self.bottomView.addGestureRecognizer(tapGesture)
        }
        
        // Configure enter and highlighted center image
        //
        self.centerImage = centerImage
        self.centerHighlightedImage = centerHighlightedImage
        
        if frame == CGRect.zero {
            configureViewsLayoutWithButtonSize(self.centerImage?.size ?? CGSize.zero)
        } else {
            configureViewsLayoutWithButtonSize(frame.size)
            self.defaultCenterPoint = self.center
        }
        
        self.configureSounds()
    }
    
    public convenience init(centerImage: UIImage, centerHighlightedImage: UIImage) {
        self.init(frame: CGRect.zero, centerImage: centerImage, centerHighlightedImage: centerHighlightedImage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Configure Menu Items
    open func addMenuItems(_ menuItems: [ExpandingMenuItem]) {
        self.menuItems += menuItems
    }
    
    // MARK: - Menu Item Tapped Action
    open func menuItemTapped(_ item: ExpandingMenuItem) {
        self.willDismissMenuItems?(self)
        self.isAnimating = true
        
        let selectedIndex: Int = item.index
        
        if self.allowSounds == true {
            AudioServicesPlaySystemSound(self.selectedSound)
        }
        
        // Excute the explode animation when the item is seleted
        //
        UIView.animate(withDuration: 0.0618 * 5.0, animations: { () -> Void in
            item.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
            item.alpha = 0.0
        })
        
        // Excute the dismiss animation when the item is unselected
        //
        for (index, item) in self.menuItems.enumerated() {
            // Remove title button
            //
            if let titleButton = item.titleButton {
                UIView.animate(withDuration: 0.15, animations: { () -> Void in
                    titleButton.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        titleButton.removeFromSuperview()
                })
            }
            
            if index == selectedIndex {
                continue
            }
            
            UIView.animate(withDuration: 0.0618 * 2.0, animations: { () -> Void in
                item.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            })
        }
        
        self.resizeToFoldedFrame { () -> Void in
            self.isAnimating = false
            self.didDismissMenuItems?(self)
        }
    }
    
    // MARK: - Center Button Action
    @objc fileprivate func centerButtonTapped() {
        if self.isAnimating == false {
            if self.isExpanding == true {
                self.foldMenuItems()
            } else {
                self.expandMenuItems()
            }
        }
    }
    
    // MARK: - Configure Sounds
    fileprivate func configureSounds() {
        if self.allowSounds == true {
            let expandingSoundUrl = URL(fileURLWithPath: self.expandingSoundPath)
            AudioServicesCreateSystemSoundID(expandingSoundUrl as CFURL, &self.expandingSound)
            
            let foldSoundUrl = URL(fileURLWithPath: self.foldSoundPath)
            AudioServicesCreateSystemSoundID(foldSoundUrl as CFURL, &self.foldSound)
            
            let selectedSoundUrl = URL(fileURLWithPath: self.selectedSoundPath)
            AudioServicesCreateSystemSoundID(selectedSoundUrl as CFURL, &self.selectedSound)
        } else {
            AudioServicesDisposeSystemSoundID(self.expandingSound)
            AudioServicesDisposeSystemSoundID(self.foldSound)
            AudioServicesDisposeSystemSoundID(self.selectedSound)
        }
    }
    
    // MARK: - Calculate The Distance From Center Button
    fileprivate func makeDistanceFromCenterButton(_ itemSize: CGSize, lastDisance: CGFloat, lastItemSize: CGSize) -> CGFloat {
        return lastDisance + itemSize.height / 2.0 + self.menuItemMargin + lastItemSize.height / 2.0
    }
    
    // MARK: - Caculate The Item's End Point
    fileprivate func makeEndPoint(_ itemExpandRadius: CGFloat, angle: CGFloat) -> CGPoint {
        switch self.expandingDirection {
        case .top:
            return CGPoint(
                x: self.centerButton.center.x + CGFloat(cosf((Float(angle) + 1.0) * Float(M_PI))) * itemExpandRadius,
                y: self.centerButton.center.y + CGFloat(sinf((Float(angle) + 1.0) * Float(M_PI))) * itemExpandRadius
            )
        case .bottom:
            return CGPoint(
                x: self.centerButton.center.x + CGFloat(cosf(Float(angle) * Float(M_PI))) * itemExpandRadius,
                y: self.centerButton.center.y + CGFloat(sinf(Float(angle) * Float(M_PI))) * itemExpandRadius
            )
        }
    }
    
    // MARK: - Fold Menu Items
    fileprivate func foldMenuItems() {
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
            
            item.layer.add(foldAnimation, forKey: "foldAnimation")
            item.center = self.centerButton.center
            
            // Remove title button
            //
            if let titleButton = item.titleButton {
                UIView.animate(withDuration: 0.15, animations: { () -> Void in
                    titleButton.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        titleButton.removeFromSuperview()
                })
            }
        }
        
        self.bringSubview(toFront: self.centerButton)
        
        // Resize the ExpandingMenuButton's frame to the foled frame and remove the item buttons
        //
        self.resizeToFoldedFrame { () -> Void in
            self.isAnimating = false
            self.didDismissMenuItems?(self)
        }
    }
    
    fileprivate func resizeToFoldedFrame(completion: (() -> Void)?) {
        if self.enabledFoldingAnimations.contains(.MenuButtonRotation) == true {
            UIView.animate(withDuration: 0.0618 * 3, delay: 0.0618 * 2, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                self.centerButton.transform = CGAffineTransform(rotationAngle: 0.0)
                }, completion: nil)
        } else {
            self.centerButton.transform = CGAffineTransform(rotationAngle: 0.0)
        }
        
        UIView.animate(withDuration: 0.15, delay: 0.35, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
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
    
    fileprivate func makeFoldAnimation(startingPoint: CGPoint, backwardPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
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
        let path: CGMutablePath = CGMutablePath()
        
        if self.enabledFoldingAnimations.contains([.MenuItemMoving, .MenuItemBound]) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if self.enabledFoldingAnimations.contains(.MenuItemMoving) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if self.enabledFoldingAnimations.contains(.MenuItemBound) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if self.enabledFoldingAnimations.contains(.MenuItemFade) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
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
    fileprivate func expandMenuItems() {
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
        UIView.animate(withDuration: 0.0618 * 3, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            self.bottomView.alpha = self.bottomViewAlpha
            }, completion: nil)
        
        // 4. Excute the center button rotation animation
        //
        if self.enabledExpandingAnimations.contains(.MenuButtonRotation) == true {
            UIView.animate(withDuration: 0.1575, animations: { () -> Void in
                self.centerButton.transform = CGAffineTransform(rotationAngle: CGFloat(-0.5 * M_PI))
            })
        } else {
            self.centerButton.transform = CGAffineTransform(rotationAngle: CGFloat(-0.5 * M_PI))
        }
        
        // 5. Excute the expanding animation
        //
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize: CGSize = self.centerButton.bounds.size
        
        for (index, item) in self.menuItems.enumerated() {
            item.delegate = self
            item.index = index
            item.transform = CGAffineTransform(translationX: 1.0, y: 1.0)
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
            
            item.layer.add(expandingAnimation, forKey: "expandingAnimation")
            item.center = endPoint
            
            // 3. Add Title Button
            //
            item.titleTappedActionEnabled = self.titleTappedActionEnabled
            
            if let titleButton = item.titleButton {
                titleButton.center = endPoint
                let margin: CGFloat = item.titleMargin
                
                let originX: CGFloat
                
                switch self.menuTitleDirection {
                case .left:
                    originX = endPoint.x - item.bounds.width / 2.0 - margin - titleButton.bounds.width
                case .right:
                    originX = endPoint.x + item.bounds.width / 2.0 + margin;
                }
                
                var titleButtonFrame: CGRect = titleButton.frame
                titleButtonFrame.origin.x = originX
                titleButton.frame = titleButtonFrame
                titleButton.alpha = 0.0
                
                self.insertSubview(titleButton, belowSubview: self.centerButton)
                
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
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
    
    fileprivate func makeExpandingAnimation(startingPoint: CGPoint, farPoint: CGPoint, nearPoint: CGPoint, endPoint: CGPoint) -> CAAnimationGroup {
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
        let path: CGMutablePath = CGMutablePath()
        
        if self.enabledExpandingAnimations.contains([.MenuItemMoving, .MenuItemBound]) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 0.7, 1.0]
        } else if self.enabledExpandingAnimations.contains(.MenuItemMoving) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 1.0]
        } else if self.enabledExpandingAnimations.contains(.MenuItemBound) == true {
            path.move(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if self.enabledExpandingAnimations.contains(.MenuItemFade) {
            path.move(to: CGPoint(x: endPoint.x, y: endPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
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
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Tap the bottom area, excute the fold animation
        self.foldMenuItems()
    }
    
    // MARK: - UIGestureRecognizer Delegate
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
