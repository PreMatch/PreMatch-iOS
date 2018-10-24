//
//  AboutViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 10/23/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit

fileprivate extension CABasicAnimation {
    class func gradientAnimation(toColors: [CGColor], forDelegate: CAAnimationDelegate) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.toValue = toColors
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        animation.duration = 1.5
        animation.delegate = forDelegate
        return animation
    }
}

fileprivate func randomColor() -> CGColor {
    return UIColor(
        red: CGFloat(drand48()),
        green: CGFloat(drand48()),
        blue: CGFloat(drand48()), alpha: 1).cgColor
}

class AboutViewController: UIViewController {

    let prematchPrimary = UIColor(red: 3/0xFF, green: 0xA9/0xFF, blue: 0xF4/0xFF, alpha: 0.8).cgColor
    let prematchSecondary = UIColor(red: 0, green: 0x96/0xFF, blue: 0x88/0xFF, alpha: 0.8).cgColor
    let accent = UIColor(red: 0xC6/0xFF, green: 0x28/0xFF, blue: 0x28/0xFF, alpha: 0.8).cgColor
    
    let gradient = CAGradientLayer()
    var currentColors: [CGColor] = []
    
    //MARK: Properties
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var gradientLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupGradient()
    }
    
    func setupGradient() {
        
        currentColors = [prematchPrimary, accent, prematchSecondary]
        gradient.colors = currentColors
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.drawsAsynchronously = true
        
        gradient.frame = gradientView.bounds
        gradientView.layer.addSublayer(gradient)
        gradientView.mask = gradientLabel
        
        animateGradient()
    }
    
    func animateGradient() {
        currentColors = [randomColor(), randomColor(), randomColor()]
        
        let animation = CABasicAnimation.gradientAnimation(
            toColors: currentColors, forDelegate: self)
        
        gradient.add(animation, forKey: "animateGradient")
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

}

extension AboutViewController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            gradient.colors = currentColors
            animateGradient()
        }
    }
}
