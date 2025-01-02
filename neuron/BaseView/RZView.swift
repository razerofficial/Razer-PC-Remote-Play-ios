/*
 * Copyright (C) 2024 Razer Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit

@IBDesignable class RZView: UIView {
    fileprivate enum Direction: String {
        case vertical
        case horizontal
    }
    fileprivate var gradientLayer: CAGradientLayer!
    fileprivate var p_gradientFromColor: UIColor = UIColor.clear
    fileprivate var p_gradientEndColor: UIColor = UIColor.clear
    fileprivate var p_gradientDirection: Direction = .vertical
    @IBInspectable var cornerRadius: CGFloat {
        set {
            self.layer.cornerRadius = newValue
        }
        get {
            return self.layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor {
        set {
            self.layer.borderColor = newValue.cgColor
        }
        get {
            return UIColor.init(cgColor: self.layer.borderColor!)
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        set {
            self.layer.borderWidth = newValue
        }
        get {
            return self.layer.borderWidth
        }
    }

    @IBInspectable var gradientFromColor: UIColor {
        set {
            checkGradientLayer()
            p_gradientFromColor = newValue
            gradientLayer.colors = [p_gradientFromColor.cgColor, p_gradientEndColor.cgColor]
        }
        get {
            return p_gradientFromColor
        }
    }

    @IBInspectable var gradientEndColor: UIColor {
        set {
            checkGradientLayer()
            p_gradientEndColor = newValue
            gradientLayer.colors = [p_gradientFromColor.cgColor, p_gradientEndColor.cgColor]
        }
        get {
            return p_gradientEndColor
        }
    }

    @IBInspectable var gradientDirection: String {
        set {
            checkGradientLayer()
            if let direc = Direction(rawValue: newValue) {
                p_gradientDirection = direc
            } else {
                p_gradientDirection = .vertical
            }
            switch p_gradientDirection {
            case .vertical:
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 0, y: 1)
            case .horizontal:
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 1, y: 0)
            }
        }
        get {
            return p_gradientDirection.rawValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = self.bounds
    }
}
// MARK: - Not UI func
extension RZView {
    fileprivate func checkGradientLayer() {
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.bounds
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
    }
}
