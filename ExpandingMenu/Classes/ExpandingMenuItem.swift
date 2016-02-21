//
//  ExpandingMenuButtonItem.swift
//
//  Created by monoqlo on 2015/07/17.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit

public class ExpandingMenuItem: UIView {
    
    public var title: String? {
        get {
            return self.titleButton?.titleLabel?.text
        }
        
        set {
            if let title = newValue {
                if let titleButton = self.titleButton {
                    titleButton.setTitle(title, forState: .Normal)
                } else {
                    self.titleButton = self.createTitleButton(title, titleColor: self.titleColor)
                }
                
                self.titleButton?.sizeToFit()
            } else {
                self.titleButton = nil
            }
        }
    }
    
    public var titleColor: UIColor? {
        get {
            return self.titleButton?.titleColorForState(.Normal)
        }
        
        set {
            self.titleButton?.setTitleColor(newValue, forState: .Normal)
        }
    }
    
    var titleTappedActionEnabled: Bool = true {
        didSet {
            self.titleButton?.userInteractionEnabled = titleTappedActionEnabled
        }
    }
    
    var index: Int = 0
    weak var delegate: ExpandingMenuButton?
    private(set) var titleButton:UIButton?
    private var frontImageView: UIImageView
    private var tappedAction: (() -> Void)?
    
    // MARK: - Initializer
    public init(size: CGSize?, title: String? = nil, titleColor: UIColor? = nil, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        
        // Initialize properties
        //
        self.frontImageView = UIImageView(image: image, highlightedImage: highlightedImage)
        self.tappedAction = itemTapped
        
        // Configure frame
        //
        let itemFrame: CGRect
        if let itemSize = size where itemSize != CGSizeZero {
            itemFrame = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height)
        } else {
            if let bgImage = backgroundImage where backgroundHighlightedImage != nil {
                itemFrame = CGRect(x: 0.0, y: 0.0, width: bgImage.size.width, height: bgImage.size.height)
            } else {
                itemFrame = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
            }
        }
        
        super.init(frame: itemFrame)
        
        // Configure base button
        //
        let baseButton = UIButton()
        baseButton.setImage(backgroundImage, forState: UIControlState.Normal)
        baseButton.setImage(backgroundHighlightedImage, forState: UIControlState.Highlighted)
        baseButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(baseButton)
        
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0))
        
        
        // Add an action for the item
        //
        baseButton.addTarget(self, action: "tapped", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Configure front images
        //
        self.frontImageView.contentMode = .Center
        self.frontImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.frontImageView)
        
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0))
        
        // Configure title button
        //
        if let title = title {
            self.titleButton = self.createTitleButton(title, titleColor: titleColor)
        }
    }
    
    public convenience init(image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    public convenience init(title: String, titleColor: UIColor? = nil, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: title, titleColor: titleColor, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    public convenience init(size: CGSize, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: size, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.frontImageView = UIImageView()
        
        super.init(coder: aDecoder)
    }
    
    // MARK: - Title Button
    private func createTitleButton(title: String, titleColor: UIColor? = nil) -> UIButton {
        let button = UIButton()
        button.setTitle(title, forState: .Normal)
        button.setTitleColor(titleColor, forState: .Normal)
        button.sizeToFit()
        
        button.addTarget(self, action: "tapped", forControlEvents: UIControlEvents.TouchUpInside)
        
        return button
    }
    
    // MARK: - Tapped Action
    func tapped() {
        self.delegate?.menuItemTapped(self)
        self.tappedAction?()
    }
}
