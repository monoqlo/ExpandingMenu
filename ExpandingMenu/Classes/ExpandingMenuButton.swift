//
//  ExpandingMenuButton.swift
//
//  Created by monoqlo on 2015/07/21.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

public struct CustomAnimationOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let rotate = CustomAnimationOptions(rawValue: 1 << 0)
    public static let bound = CustomAnimationOptions(rawValue: 1 << 1)
    public static let move = CustomAnimationOptions(rawValue: 1 << 2)
    public static let fade = CustomAnimationOptions(rawValue: 1 << 3)
    public static let menuButtonRotate = CustomAnimationOptions(rawValue: 1 << 4)
    public static let `default`: CustomAnimationOptions = [rotate, bound, move, menuButtonRotate]
    public static let all: CustomAnimationOptions = [rotate, bound, move, fade, menuButtonRotate]
}

open class ExpandingMenuButton: UIView, UIGestureRecognizerDelegate {
    
    @objc public enum ExpandingDirection: Int {
        case top
        case bottom
    }
    
    @objc public enum MenuTitleDirection: Int {
        case left
        case right
    }
    
    @objc public enum HapticFeedbackStyle: Int {
        case light
        case medium
        case heavy
        case none
    }
    
    // MARK: Public Properties
    @objc open var menuItemMargin: CGFloat = 7.0
    @objc open var menuButtonHapticStyle: HapticFeedbackStyle = .medium
    @objc open var menuItemsHapticStyle: HapticFeedbackStyle = .light
    
    @objc open var playSound: Bool = true {
        didSet {
            self.configureSounds()
        }
    }
   
    @objc open var expandingSoundPath: String? {
        didSet {
            self.configureSounds()
        }
    }
    
    @objc open var foldSoundPath: String? {
        didSet {
            self.configureSounds()
        }
    }
    
    @objc open var selectedSoundPath: String? {
        didSet {
            self.configureSounds()
        }
    }
    
    @objc open var bottomViewColor: UIColor = UIColor.black {
        didSet {
            self.bottomView.backgroundColor = bottomViewColor
        }
    }
    
    @objc open var bottomViewAlpha: CGFloat = 0.618
    @objc open var titleTappedActionEnabled: Bool = true
    @objc open var expandingDirection: ExpandingDirection = .top
    @objc open var menuTitleDirection: MenuTitleDirection = .left
    open var expandingAnimations: CustomAnimationOptions = .default
    open var foldingAnimations: CustomAnimationOptions = .default
    @objc open var willPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    @objc open var didPresentMenuItems: ((ExpandingMenuButton) -> Void)?
    @objc open var willDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    @objc open var didDismissMenuItems: ((ExpandingMenuButton) -> Void)?
    
    // MARK: Private Properties
    fileprivate var defaultCenterPoint: CGPoint = .zero
    fileprivate var expandingSize: CGSize = UIScreen.main.bounds.size
    fileprivate var foldedSize: CGSize = CGSize.zero
    
    //Menu button
    fileprivate var menuButton: UIButton = UIButton()
    fileprivate var menuButtonImage: UIImage?
    fileprivate var menuButtonHighlightedImage: UIImage?
    fileprivate var menuButtonRotatedImage: UIImage?
    fileprivate var menuButtonRotatedHighlightedImage: UIImage?
    
    fileprivate var bottomView: UIView = UIView()
    fileprivate var menuItems: [ExpandingMenuItem] = []
    
    fileprivate var foldSound: SystemSoundID = 0
    fileprivate var expandingSound: SystemSoundID = 0
    fileprivate var selectedSound: SystemSoundID = 0

    fileprivate var isExpanding: Bool = false
    fileprivate var isAnimating: Bool = false
    
    
    // MARK: - Initializer
    @objc public init(frame: CGRect, image: UIImage, highlightedImage: UIImage? = nil,  rotatedImage: UIImage, rotatedHighlightedImage: UIImage? = nil) {
        super.init(frame: frame)
        
        func configureViewsLayoutWithButtonSize(_ menuButtonSize: CGSize) {
            // Configure menu button frame
            //
            self.foldedSize = menuButtonSize
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.foldedSize.width, height: self.foldedSize.height);
            
            // Congifure center button
            //
            self.menuButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: menuButtonSize.width, height: menuButtonSize.height))
            self.menuButton.setImage(self.menuButtonImage, for: .normal)
            self.menuButton.setImage(self.menuButtonHighlightedImage, for: .highlighted)
            self.menuButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchDown)
            self.menuButton.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
            self.addSubview(self.menuButton)
            
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
            
            self.expandingSoundPath = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "expanding", ofType: "caf")
            self.foldSoundPath = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "fold", ofType: "caf")
            self.selectedSoundPath = Bundle(url: Bundle(for: ExpandingMenuButton.classForCoder()).url(forResource: "ExpandingMenu", withExtension: "bundle")!)?.path(forResource: "selected", ofType: "caf") 
        }
        
        // Configure enter and highlighted center image
        //
        self.menuButtonImage = image
        self.menuButtonHighlightedImage = highlightedImage
        self.menuButtonRotatedImage = rotatedImage
        self.menuButtonRotatedHighlightedImage = rotatedHighlightedImage
        
        if frame == CGRect.zero {
            configureViewsLayoutWithButtonSize(self.menuButtonImage?.size ?? CGSize.zero)
        } else {
            configureViewsLayoutWithButtonSize(frame.size)
            self.defaultCenterPoint = self.center
        }
        self.configureSounds()
    }
    
    @objc public convenience init(image: UIImage, rotatedImage: UIImage) {
        self.init(frame: CGRect.zero, image: image, rotatedImage: rotatedImage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Configure Menu Items
    @objc open func addMenuItems(_ menuItems: [ExpandingMenuItem]) {
        self.menuItems += menuItems
    }
    
    // MARK: - Menu Item Tapped Action
    @objc open func menuItemTapped(_ item: ExpandingMenuItem) {
        self.willDismissMenuItems?(self)
        self.isAnimating = true
        
        let selectedIndex: Int = item.index
        
        if self.playSound == true {
            AudioServicesPlaySystemSound(self.selectedSound)
        }
        
        if self.menuItemsHapticStyle != .none {
            self.generateHapticFeedback(self.menuItemsHapticStyle)
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
        if self.playSound == true {
            if let path = self.expandingSoundPath {
                AudioServicesCreateSystemSoundID(URL(fileURLWithPath: path) as CFURL, &self.expandingSound)
            }
            if let path = self.foldSoundPath {
                AudioServicesCreateSystemSoundID(URL(fileURLWithPath: path) as CFURL, &self.foldSound)
            }
            if let path = self.foldSoundPath {
                AudioServicesCreateSystemSoundID(URL(fileURLWithPath: path) as CFURL, &self.selectedSound)
            }
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
                x: self.menuButton.center.x + CGFloat(cosf((Float(angle) + 1.0) * Float.pi)) * itemExpandRadius,
                y: self.menuButton.center.y + CGFloat(sinf((Float(angle) + 1.0) * Float.pi)) * itemExpandRadius
            )
        case .bottom:
            return CGPoint(
                x: self.menuButton.center.x + CGFloat(cosf(Float(angle) * Float.pi)) * itemExpandRadius,
                y: self.menuButton.center.y + CGFloat(sinf(Float(angle) * Float.pi)) * itemExpandRadius
            )
        }
    }
    
    // MARK: - Fold Menu Items
    fileprivate func foldMenuItems() {
        self.willDismissMenuItems?(self)
        self.isAnimating = true
        
        if self.playSound == true {
            AudioServicesPlaySystemSound(self.foldSound)
        }
        
        if self.menuButtonHapticStyle != .none {
            self.generateHapticFeedback(self.menuButtonHapticStyle)
        }
        
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize: CGSize = self.menuButton.bounds.size
        
        for item in self.menuItems {
            let distance: CGFloat = self.makeDistanceFromCenterButton(item.bounds.size, lastDisance: lastDistance, lastItemSize: lastItemSize)
            lastDistance = distance
            lastItemSize = item.bounds.size
            let backwardPoint: CGPoint = self.makeEndPoint(distance + 5.0, angle: currentAngle / 180.0)
            
            let foldAnimation: CAAnimationGroup = self.makeFoldAnimation(startingPoint: item.center, backwardPoint: backwardPoint, endPoint: self.menuButton.center)
            
            item.layer.add(foldAnimation, forKey: "foldAnimation")
            item.center = self.menuButton.center
            
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
        #if swift(>=4.2)
        self.bringSubviewToFront(self.menuButton)
        #else
        self.bringSubview(toFront: self.menuButton)
        #endif
        
        // Resize the ExpandingMenuButton's frame to the foled frame and remove the item buttons
        //
        self.resizeToFoldedFrame { () -> Void in
            self.isAnimating = false
            self.didDismissMenuItems?(self)
        }
    }
    
    fileprivate func resizeToFoldedFrame(completion: (() -> Void)?) {
        if self.foldingAnimations.contains(.menuButtonRotate) == true {
            UIView.animate(withDuration: 0.0618 * 3, delay: 0.0618 * 2, options: .curveEaseIn, animations: { () -> Void in
                self.menuButton.transform = CGAffineTransform(rotationAngle: 0.0)
                self.menuButton.setImage(self.menuButtonImage, for: .normal)
                self.menuButton.setImage(self.menuButtonHighlightedImage, for: .highlighted)
                }, completion: nil)
        } else {
            self.menuButton.transform = CGAffineTransform(rotationAngle: 0.0)
        }
        
        UIView.animate(withDuration: 0.15, delay: 0.35, options: .curveLinear, animations: { () -> Void in
            self.bottomView.alpha = 0.0
            }, completion: { (finished) -> Void in
                // Remove the items from the superview
                //
                for item in self.menuItems {
                    item.removeFromSuperview()
                }
                
                self.frame = CGRect(x: 0.0, y: 0.0, width: self.foldedSize.width, height: self.foldedSize.height)
                self.center = self.defaultCenterPoint
                
                self.menuButton.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
                
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
        if self.foldingAnimations.contains(.rotate) == true {
            let rotationAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, Double.pi, Double.pi * 2.0]
            #if swift(>=4.2)
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
            #else
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            #endif
            rotationAnimation.duration = 0.35
            
            animationGroup.animations?.append(rotationAnimation)
        }
        
        // 2.Configure moving animation
        //
        let movingAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        
        // Create moving path
        //
        let path: CGMutablePath = CGMutablePath()
        
        if self.foldingAnimations.contains([.move, .bound]) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if self.foldingAnimations.contains(.move) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.75, 1.0]
        } else if self.foldingAnimations.contains(.bound) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: backwardPoint.x, y: backwardPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if self.foldingAnimations.contains(.fade) {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
        }
        
        movingAnimation.path = path
        movingAnimation.duration = 0.35
        
        animationGroup.animations?.append(movingAnimation)
        
        // 3.Configure fade animation
        //
        if self.foldingAnimations.contains(.fade) {
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
        
        if self.playSound == true {
            AudioServicesPlaySystemSound(self.expandingSound)
        }
        
        if self.menuButtonHapticStyle != .none {
            self.generateHapticFeedback(self.menuButtonHapticStyle)
        }
        
        // Configure center button expanding
        //
        // 1. Copy the current center point and backup default center point
        //
        self.menuButton.center = self.center
        self.defaultCenterPoint = self.center
        
        // 2. Resize the frame
        //
        self.frame = CGRect(x: 0.0, y: 0.0, width: self.expandingSize.width, height: self.expandingSize.height)
        self.center = CGPoint(x: self.expandingSize.width / 2.0, y: self.expandingSize.height / 2.0)
        
        self.insertSubview(self.bottomView, belowSubview: self.menuButton)
        
        // 3. Excute the bottom view alpha animation
        //
        UIView.animate(withDuration: 0.0618 * 3, delay: 0.0, options: .curveEaseIn, animations: { () -> Void in
            self.bottomView.alpha = self.bottomViewAlpha
            }, completion: nil)
        
        // 4. Excute the center button rotation animation
        //
        if self.expandingAnimations.contains(.menuButtonRotate) == true {
            UIView.animate(withDuration: 0.1575, animations: { () -> Void in
                self.menuButton.transform = CGAffineTransform(rotationAngle: CGFloat(-0.5 * Float.pi))
                self.menuButton.setImage(self.menuButtonRotatedImage, for: .normal)
                self.menuButton.setImage(self.menuButtonRotatedHighlightedImage, for: .highlighted)
            })
        } else {
            self.menuButton.transform = CGAffineTransform(rotationAngle: CGFloat(-0.5 * Float.pi))
        }
        
        // 5. Excute the expanding animation
        //
        let currentAngle: CGFloat = 90.0
        
        var lastDistance: CGFloat = 0.0
        var lastItemSize: CGSize = self.menuButton.bounds.size
        
        for (index, item) in self.menuItems.enumerated() {
            item.delegate = self
            item.index = index
            item.transform = CGAffineTransform(translationX: 1.0, y: 1.0)
            item.alpha = 1.0
            
            // 1. Add item to the view
            //
            item.center = self.menuButton.center
            
            self.insertSubview(item, belowSubview: self.menuButton)
            
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
                
                self.insertSubview(titleButton, belowSubview: self.menuButton)
                
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
        if self.expandingAnimations.contains(.rotate) == true {
            let rotationAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.values = [0.0, -Double.pi, -Double.pi * 1.5, -Double.pi  * 2.0]
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
        
        if self.expandingAnimations.contains([.move, .bound]) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 0.7, 1.0]
        } else if self.expandingAnimations.contains(.move) == true {
            path.move(to: CGPoint(x: startingPoint.x, y: startingPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.5, 1.0]
        } else if self.expandingAnimations.contains(.bound) == true {
            path.move(to: CGPoint(x: farPoint.x, y: farPoint.y))
            path.addLine(to: CGPoint(x: nearPoint.x, y: nearPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            
            movingAnimation.keyTimes = [0.0, 0.3, 0.5, 1.0]
        } else if self.expandingAnimations.contains(.fade) {
            path.move(to: CGPoint(x: endPoint.x, y: endPoint.y))
            path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
        }
        
        movingAnimation.path = path
        movingAnimation.duration = 0.3
        
        animationGroup.animations?.append(movingAnimation)
        
        // 3.Configure fade animation
        //
        if self.expandingAnimations.contains(.fade) {
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


extension ExpandingMenuButton {
    
    func generateHapticFeedback(_ style: HapticFeedbackStyle) {
        if style == .none {
            return
        }
        if #available(iOS 10.0, *) {
            if style == .light {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if style == .medium {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else if style == .heavy {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        } else {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
    }
    
}
