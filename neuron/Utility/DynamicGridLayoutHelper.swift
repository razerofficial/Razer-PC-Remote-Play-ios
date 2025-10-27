/*
 * Copyright (C) 2025 Razer Inc.
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

// dynamic layout for cell size, number of rows
struct DynamicGridLayoutHelper {
    
    // Calculate the current horizontal scaling value
    static func currentHScale(viewWidth: CGFloat, designWidth: CGFloat = DesignWidth) -> CGFloat {
        let width = viewWidth > 0 ? viewWidth : UIScreen.screenWidth
        return width / designWidth
    }

    // Calculate how many cells can fit in a row
    static func dynamicRowLimit(
        viewWidth: CGFloat,
        cellBaseWidth: CGFloat,
        spacing: CGFloat,
        minCells: Int = 1,
        maxCells: Int = 4,
        margin: CGFloat = 100,
        designWidth: CGFloat = DesignWidth
    ) -> Int {
        let width = viewWidth > 0 ? viewWidth : UIScreen.screenWidth
        let availableWidth = width - margin
        
        // calculate cells per row based on fixed cell width
        let fixedCellWidth = cellBaseWidth
        let fixedCalculatedCellsPerRow = (availableWidth + spacing) / (fixedCellWidth + spacing)
        let fixedCellsPerRow = Int(fixedCalculatedCellsPerRow)

        // calculate the min number of cells required width
        let minCellsRequiredWidth = CGFloat(minCells) * fixedCellWidth + CGFloat(minCells - 1) * spacing
        
        if minCellsRequiredWidth <= availableWidth {
            let actualRequiredWidth = CGFloat(fixedCellsPerRow) * fixedCellWidth + CGFloat(fixedCellsPerRow - 1) * spacing
            let finalCellsPerRow = actualRequiredWidth <= availableWidth ? fixedCellsPerRow : max(1, fixedCellsPerRow - 1)
            let result = max(minCells, min(maxCells, finalCellsPerRow))
            
            print("DynamicRowLimit Debug (Fixed Cell Size): viewWidth: \(width) cellWidth (fixed): \(fixedCellWidth) availableWidth: \(availableWidth) minCellsRequiredWidth: \(minCellsRequiredWidth) final result: \(result)")
            
            return result
        } else {
            // cells need to be scaled
            let hScale = currentHScale(viewWidth: width, designWidth: designWidth)
            let scaledCellWidth = cellBaseWidth * hScale
            let scaledCalculatedCellsPerRow = (availableWidth + spacing) / (scaledCellWidth + spacing)
            let scaledCellsPerRow = Int(scaledCalculatedCellsPerRow)
            
            let actualRequiredWidth = CGFloat(scaledCellsPerRow) * scaledCellWidth + CGFloat(scaledCellsPerRow - 1) * spacing
            let finalCellsPerRow = actualRequiredWidth <= availableWidth ? scaledCellsPerRow : max(1, scaledCellsPerRow - 1)
            let result = max(minCells, min(maxCells, finalCellsPerRow))

            print("🔍 DynamicRowLimit Debug (Scaled Cell Size): viewWidth : \(width) cellWidth (scaled): \(scaledCellWidth) availableWidth: \(availableWidth) minCellsRequiredWidth: \(minCellsRequiredWidth) hScale: \(hScale) final result: \(result)")
            
            return result
        }
    }

    // Determine if cells need to be scaled    
    static func shouldScaleCells(
        viewWidth: CGFloat,
        cellBaseWidth: CGFloat,
        spacing: CGFloat,
        margin: CGFloat,
        minCells: Int = 1,
        designWidth: CGFloat = DesignWidth
    ) -> Bool {
        let width = viewWidth > 0 ? viewWidth : UIScreen.screenWidth
        let availableWidth = width - margin
        let minCellsRequiredWidth = CGFloat(minCells) * cellBaseWidth + CGFloat(minCells - 1) * spacing
        return minCellsRequiredWidth > availableWidth
    }

    // Calculate dynamic cell size
    static func dynamicCellSize(
        viewWidth: CGFloat,
        cellBaseWidth: CGFloat,
        cellBaseHeight: CGFloat,
        spacing: CGFloat,
        margin: CGFloat,
        minCells: Int = 1,
        designWidth: CGFloat = DesignWidth
    ) -> CGSize {
        if shouldScaleCells(viewWidth: viewWidth, cellBaseWidth: cellBaseWidth, spacing: spacing, margin: margin, minCells: minCells, designWidth: designWidth) {
            let currentWidth = viewWidth > 0 ? viewWidth : UIScreen.screenWidth
            let windowScale = currentWidth / designWidth
            let screenScale = UIScreen.screenWidth / designWidth
            let finalScale = windowScale / screenScale
            return CGSize(width: cellBaseWidth * finalScale, height: cellBaseHeight * finalScale)
        } else {
            return CGSize(width: cellBaseWidth, height: cellBaseHeight)
        }
    }
    
    // Calculate dynamic width (for game detail page)
    static func dynamicWidth(
        viewWidth: CGFloat,
        baseWidth: CGFloat,
        designWidth: CGFloat = DesignWidth
    ) -> CGFloat {
        let width = viewWidth > 0 ? viewWidth : UIScreen.screenWidth
        return min(baseWidth, width * 0.4) // assume max 40% of view width
    }
    
    // Calculate dynamic search bar width to avoid being too wide on large screens
    static func dynamicSearchBarWidth(
        viewWidth: CGFloat,
        baseWidth: CGFloat = 200,
        minWidth: CGFloat = 30,
        designWidth: CGFloat = DesignWidth
    ) -> CGFloat {
        let currentWidth = viewWidth > 0 ? viewWidth : UIScreen.screenWidth
        
        let screenWidth = UIScreen.screenWidth
        let windowScale = currentWidth / screenWidth
        
        if windowScale < 1.0 {
            let scaledWidth = baseWidth * windowScale
            return max(minWidth, scaledWidth)
        } else {
            print("baseWidth: currentWidth: \(currentWidth) windowScale: \(windowScale), baseWidth: \(baseWidth)")
            return baseWidth
        }
    }
}

// game cell layout configuration
struct DynamicGridConfig {
    let cellBaseWidth: CGFloat
    let cellBaseHeight: CGFloat
    let spacing: CGFloat
    let margin: CGFloat
    let minCells: Int
    let maxCells: Int
    
    // for Host Cells in DashboardView
    static let hostCells = DynamicGridConfig(
        cellBaseWidth: 155, // HostCellWidth
        cellBaseHeight: 165, // HostCellHeight
        spacing: 20, // HHostCellSpace
        margin: 50, // DeviceLeftSpace * 2 + some buffer
        minCells: 1,
        maxCells: IsIpad() ? 6 : 4 // HostRowLimit
    )
    
    // for More Games View
//    static let moreGames = DynamicGridConfig(
//        cellBaseWidth: CGFloat(160 * HScale), // default value from DashboardMoreGamesView
//        cellBaseHeight: CGFloat(90 * HScale),  // default value from DashboardMoreGamesView
//        spacing: HMoreGamesCellSpace,
//        margin: 40,
//        minCells: 1,
//        maxCells: 4
//    )
//    
//    // for Manage Games View
//    static let manageGames = DynamicGridConfig(
//        cellBaseWidth: CGFloat(100 * HScale), // default value from DashboardManageGamesView
//        cellBaseHeight: CGFloat(100 * HScale), // default value from DashboardManageGamesView
//        spacing: HManageGamesCellSpace,
//        margin: 30, 
//        minCells: 1,
//        maxCells: 4
//    )
    
    func rowLimit(for viewWidth: CGFloat) -> Int {
        return DynamicGridLayoutHelper.dynamicRowLimit(
            viewWidth: viewWidth,
            cellBaseWidth: cellBaseWidth,
            spacing: spacing,
            minCells: minCells,
            maxCells: maxCells,
            margin: margin
        )
    }
    
    func cellSize(for viewWidth: CGFloat) -> CGSize {
        return DynamicGridLayoutHelper.dynamicCellSize(
            viewWidth: viewWidth,
            cellBaseWidth: cellBaseWidth,
            cellBaseHeight: cellBaseHeight,
            spacing: spacing,
            margin: margin,
            minCells: minCells
        )
    }
}
