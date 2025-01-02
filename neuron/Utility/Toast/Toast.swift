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

class Toast {
    private static var toastView: UIView?
    private static var label: UILabel?

    // 显示 Toast 消息
    class func show(text: String, duration: TimeInterval = 2.0, in view: UIView? = nil) {
        // 如果已经有 Toast 在显示，则移除它
        hide()

        // 获取要添加 Toast 的视图，默认为 keyWindow
        let targetView: UIView
        if let view = view {
            targetView = view
        } else if let window = UIApplication.shared.keyWindow {
            targetView = window
        } else {
            print("无法找到合适的视图来显示 Toast")
            return
        }

        // 创建新的 Toast 视图
        let toastView = UIView(frame: CGRect.zero)
        toastView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true

        // 创建 Label 来显示消息
        let label = UILabel(frame: CGRect.zero)
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false

        // 添加 Label 到 Toast 视图
        toastView.addSubview(label)

        // 设置约束
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -8)
        ])

        // 计算 Toast 的大小
        let maxSize = CGSize(width: targetView.bounds.width - 32, height: 500)
        let expectedSize = label.sizeThatFits(maxSize)
        toastView.frame.size = CGSize(width: min(expectedSize.width + 32, maxSize.width), height: expectedSize.height + 16)

        // 设置 Toast 的位置
        toastView.center = CGPoint(x: targetView.bounds.midX, y: targetView.bounds.maxY - toastView.bounds.height/2.0 - 30.0)

        // 添加 Toast 到视图
        targetView.addSubview(toastView)

        // 保存引用
        self.toastView = toastView
        self.label = label

        // 延迟移除 Toast
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.hide()
        }
    }

    // 隐藏当前显示的 Toast
    class func hide() {
        if let toastView = self.toastView {
            toastView.removeFromSuperview()
        }
        self.toastView = nil
        self.label = nil
    }
}
