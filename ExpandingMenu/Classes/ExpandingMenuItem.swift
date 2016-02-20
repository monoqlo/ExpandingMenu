//
//  ExpandingMenuButtonItem.swift
//
//  Created by monoqlo on 2015/07/17.
//  Copyright (c) 2015年 monoqlo All rights reserved.
//

import UIKit

public class ExpandingMenuItem: UIButton {
    
    var index: Int = 0
    weak var delegate: ExpandingMenuButton?
    private(set) var titleButton:UIButton?
    private var frontImageView: UIImageView
    private var tappedAction: (() -> Void)?
    
    // MARK: - Initializer
    public init(size: CGSize?, title: String?, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        
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
        
        // Configure images
        //
        setImage(backgroundImage, forState: UIControlState.Normal)
        setImage(backgroundHighlightedImage, forState: UIControlState.Highlighted)
        
        self.frontImageView.center = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        addSubview(self.frontImageView)
        
        // Add an action for the item
        //
        addTarget(self, action: "tapped", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Configure title button
        //
        if let title = title {
            let button = UIButton()
            button.setTitle(title, forState: UIControlState.Normal)
            button.sizeToFit()
            
            button.addTarget(self, action: "tapped", forControlEvents: UIControlEvents.TouchUpInside)
            
            self.titleButton = button
        }
    }
    
    public convenience init(image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    public convenience init(title: String, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: nil, title: title, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    public convenience init(size: CGSize, image: UIImage, highlightedImage: UIImage, backgroundImage: UIImage?, backgroundHighlightedImage: UIImage?, itemTapped: (() -> Void)?) {
        self.init(size: size, title: nil, image: image, highlightedImage: highlightedImage, backgroundImage: backgroundImage, backgroundHighlightedImage: backgroundHighlightedImage, itemTapped: itemTapped)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.frontImageView = UIImageView()
        
        super.init(coder: aDecoder)
    }
    
    // MARK: - Tapped Action
    func tapped() {
        self.delegate?.menuItemTapped(self)
        self.tappedAction?()
    }
}
