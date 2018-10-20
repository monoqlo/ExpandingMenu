//
//  ExpandingMenuButtonItem.swift
//
//  Created by monoqlo on 2015/07/17.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit

open class ExpandingMenuItem: UIView {
    
    @objc open var title: String? {
        get { return self.titleButton?.titleLabel?.text }
        set {
            if let title = newValue {
                if let titleButton = self.titleButton {
                    #if swift(>=4.2)
                    titleButton.setTitle(title, for: UIControl.State())
                    #else
                    titleButton.setTitle(title, for: UIControlState())
                    #endif
                } else {
                    self.titleButton = self.createTitleButton(title, titleColor: self.titleColor)
                }
                self.titleButton?.sizeToFit()
            } else {
                self.titleButton = nil
            }
        }
    }
    
    @objc open var titleMargin: CGFloat = 5.0
    
    #if swift(>=4.2)
    @objc open var titleColor: UIColor? {
        get { return self.titleButton?.titleColor(for: UIControl.State()) }
        set { self.titleButton?.setTitleColor(newValue, for: UIControl.State()) }
    }
    #else
    @objc open var titleColor: UIColor? {
        get { return self.titleButton?.titleColor(for: UIControlState()) }
        set { self.titleButton?.setTitleColor(newValue, for: UIControlState()) }
    }
    #endif
    
    @objc var titleTappedActionEnabled: Bool = true {
        didSet {
            self.titleButton?.isUserInteractionEnabled = titleTappedActionEnabled
        }
    }
    
    var index: Int = 0
    weak var delegate: ExpandingMenuButton?
    fileprivate(set) var titleButton: UIButton?
    fileprivate var frontImageView: UIImageView
    fileprivate var tappedAction: (() -> Void)?
    
    // MARK: - Initializer
    public init(size: CGSize?, title: String? = nil, titleColor: UIColor? = nil, image: UIImage, highlightedImage: UIImage?, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        
        // Initialize properties
        //
        self.frontImageView = UIImageView(image: image, highlightedImage: highlightedImage)
        self.tappedAction = itemTapped
        
        // Configure frame
        //
        let itemFrame: CGRect
        if let itemSize = size , itemSize != CGSize.zero {
            itemFrame = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height)
        } else {
            if let bgImage = backgroundImage , backgroundHighlightedImage != nil {
                itemFrame = CGRect(x: 0.0, y: 0.0, width: bgImage.size.width, height: bgImage.size.height)
            } else {
                itemFrame = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
            }
        }
        
        super.init(frame: itemFrame)
        
        // Configure base button
        //
        let baseButton = UIButton()
        #if swift(>=4.2)
        baseButton.setImage(backgroundImage, for: UIControl.State())
        #else
        baseButton.setImage(backgroundImage, for: UIControlState())
        #endif
        baseButton.setImage(backgroundHighlightedImage, for: .highlighted)
        baseButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(baseButton)
        
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: baseButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        
        
        // Add an action for the item
        //
        baseButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        // Configure front images
        //
        self.frontImageView.contentMode = .center
        self.frontImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.frontImageView)
        
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.frontImageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        
        // Configure title button
        //
        if let title = title {
            self.titleButton = self.createTitleButton(title, titleColor: titleColor)
        }
    }
    
    @objc public convenience init(image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    @objc public convenience init(title: String, titleColor: UIColor? = nil, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: title, titleColor: titleColor, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    @objc public convenience init(size: CGSize, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: size, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.frontImageView = UIImageView()
        
        super.init(coder: aDecoder)
    }
    
    // MARK: - Title Button
    fileprivate func createTitleButton(_ title: String, titleColor: UIColor? = nil) -> UIButton {
        let button = UIButton()
        #if swift(>=4.2)
        button.setTitle(title, for: UIControl.State())
        button.setTitleColor(titleColor, for: UIControl.State())
        #else
        button.setTitle(title, for: UIControlState())
        button.setTitleColor(titleColor, for: UIControlState())
        #endif
        button.sizeToFit()
        
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        return button
    }
    
    // MARK: - Tapped Action
    @objc func tapped() {
        self.delegate?.menuItemTapped(self)
        self.tappedAction?()
    }
}
