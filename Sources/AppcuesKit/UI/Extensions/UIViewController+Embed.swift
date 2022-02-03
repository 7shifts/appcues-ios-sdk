//
//  UIViewController+Embed.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIViewController {
    func embedChildViewController(_ childVC: UIViewController, inSuperview superview: UIView, atIndex index: Int? = nil) {
        addChild(childVC)
        if let index = index {
            superview.insertSubview(childVC.view, at: index)
        } else {
            superview.addSubview(childVC.view)
        }
        childVC.view.pin(to: superview)
        childVC.didMove(toParent: self)
    }

    func unembedChildViewController(_ childVC: UIViewController) {
        guard childVC.parent == self else { return }
        childVC.willMove(toParent: nil)
        childVC.removeFromParent()
        childVC.view.removeFromSuperview()
    }
}
