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

import SwiftUI
import UIKit

extension SettingsNavigationSplitView {
    // in ios 18, sometimes navigation back btn won't show afer screen rotation, so we need force update it
    func updateBackButtonState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3 sec delay for stable nav bar state
            applyBackButtonIfNeeded()
        }
    }

    private func leadingGroupItems(_ item: UINavigationItem?) -> [UIBarButtonItem] {
        // Flatten leadingItemGroups into bar button items.
        #if !os(tvOS)
        guard #available(iOS 16.0, *), let item else { return [] }
        var items: [UIBarButtonItem] = []
        for group in item.leadingItemGroups {
            if !group.barButtonItems.isEmpty {
                items.append(contentsOf: group.barButtonItems)
            } else if let rep = group.representativeItem {
                items.append(rep)
            }
        }
        return items
        #else
        return []
        #endif
    }

    private func leadingBarButtonCandidates(_ item: UINavigationItem) -> [UIBarButtonItem] {
        var candidates: [UIBarButtonItem] = []
        if let leftItem = item.leftBarButtonItem {
            candidates.append(leftItem)
        }
        if let leftItems = item.leftBarButtonItems {
            candidates.append(contentsOf: leftItems)
        }
        candidates.append(contentsOf: leadingGroupItems(item))
        return candidates
    }

    // Use customView if present; otherwise use the UIKit view.
    private func barButtonItemView(_ item: UIBarButtonItem) -> UIView? {
        if let customView = item.customView {
            return customView
        }
        return item.value(forKey: "view") as? UIView
    }

    // Check the view is attached, visible, and inside the nav bar.
    private func isViewVisibleInNavBar(_ view: UIView, navBar: UINavigationBar) -> Bool {
        guard view.window != nil else {
            Logger.debug("[backbtncheck] isViewVisibleInNavBar: window is nil")
            return false
        }
        var current: UIView? = view
        while let currentView = current {
            if currentView.isHidden {
                Logger.debug("[backbtncheck] isViewVisibleInNavBar: hidden view \(currentView)")
                return false
            }
            if currentView.alpha < 0.01 {
                Logger.debug("[backbtncheck] isViewVisibleInNavBar: alpha too low \(currentView.alpha)")
                return false
            }
            current = currentView.superview
        }
        let frameInBar = view.convert(view.bounds, to: navBar)
        if frameInBar.width <= 1 || frameInBar.height <= 1 {
            Logger.debug("[backbtncheck] isViewVisibleInNavBar: frame too small \(frameInBar)")
            return false
        }
        if !frameInBar.intersects(navBar.bounds) {
            Logger.debug("[backbtncheck] isViewVisibleInNavBar: frame not intersecting navBar bounds frame=\(frameInBar) bounds=\(navBar.bounds)")
            return false
        }
        return true
    }

    private func isVisibleLeadingBarButton(_ item: UINavigationItem?, in navBar: UINavigationBar) -> Bool {
        guard let item else {
            Logger.debug("[backbtncheck] isVisibleLeadingBarButton: item is nil")
            return false
        }
        var seen = Set<ObjectIdentifier>()
        let candidates = leadingBarButtonCandidates(item)
        var checkedCount = 0
        var attachedCount = 0
        var nilViewCount = 0
        for barItem in candidates {
            let id = ObjectIdentifier(barItem)
            guard !seen.contains(id) else { continue }
            seen.insert(id)
            guard let view = barButtonItemView(barItem) else {
                nilViewCount += 1
                continue
            }
            checkedCount += 1
            let attached = view.superview != nil
            if attached {
                attachedCount += 1
            }
            let visible = attached && isViewVisibleInNavBar(view, navBar: navBar)
            if visible {
                return true
            }
        }
        Logger.debug("[backbtncheck] isVisibleLeadingBarButton: candidates=\(candidates.count) checked=\(checkedCount) attached=\(attachedCount) nilViews=\(nilViewCount) visible=false")
        return false
    }

    //BIA-2320, native ios 18's issue, back btn won't show after rotation in regular/compact mode detail view
    private func applyBackButtonIfNeeded() {
        #if os(tvOS)
        return
        #else
        guard let nav = detailNavigationController else {
            Logger.debug("[backbtncheck] applyBackButtonIfNeeded: nav controller is nil")
            return
        }
        let viewControllersState = viewModel.getViewControllersCountState()
        let navDepth = nav.viewControllers.count
        let shouldExpectBackButton = isInDetailView
            && navDepth > 1
            && (viewControllersState == .regularPushPage || viewControllersState == .compactPushPage)
        if !shouldExpectBackButton {
            Logger.debug("[backbtncheck] applyBackButtonIfNeeded: shouldExpectBackButton=\(shouldExpectBackButton) isInDetailView=\(isInDetailView) navDepth=\(navDepth) state=\(viewControllersState)")
            return
        }
        guard !nav.isNavigationBarHidden, !nav.navigationBar.isHidden else {
            Logger.debug("[backbtncheck] applyBackButtonIfNeeded: navBar hidden nav.isNavigationBarHidden=\(nav.isNavigationBarHidden) navBar.isHidden=\(nav.navigationBar.isHidden)")
            return
        }

        var topItem = nav.navigationBar.topItem ?? nav.topViewController?.navigationItem

        let candidatesCount = topItem.map { leadingBarButtonCandidates($0).count } ?? 0
        let hasBackItem = nav.viewControllers.count > 1
            && topItem?.hidesBackButton != true
            && nav.navigationBar.backItem != nil
        let hasLeading = candidatesCount > 0 || hasBackItem
        Logger.debug("[backbtncheck] applyBackButtonIfNeeded: topItem=\(String(describing: topItem)) candidatesCount=\(candidatesCount) hasBackItem=\(hasBackItem) hasLeading=\(hasLeading) hidesBackButton=\(topItem?.hidesBackButton ?? false)")
        if isVisibleLeadingBarButton(topItem, in: nav.navigationBar) {
            Logger.debug("[backbtncheck] applyBackButtonIfNeeded: NO, visible leading bar button already present")
            return
        }

        if hasLeading {
            nav.navigationBar.setNeedsLayout()
            nav.navigationBar.layoutIfNeeded()
            if isVisibleLeadingBarButton(topItem, in: nav.navigationBar) {
                Logger.debug("[backbtncheck] applyBackButtonIfNeeded: NO, visible after relayout hasLeading=\(hasLeading)")
                return
            }
        }

        backButtonTarget.action = { handleSplitViewBackButtonTap() }
        let item = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: backButtonTarget,
            action: #selector(NavigationBarButtonTarget.handleTap)
        )
        item.accessibilityIdentifier = "SettingsSplitView.CustomBack"
        topItem?.leftBarButtonItem = item
        nav.navigationBar.setNeedsLayout()
        nav.navigationBar.layoutIfNeeded()
        Logger.debug("[backbtncheck] applyBackButtonIfNeeded: custom back button applied")
        #endif
    }
}
