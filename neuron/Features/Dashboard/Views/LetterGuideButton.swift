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

let LetterGuideButtonRadius = 24.0
let LetterGuideButtonHeight = 48.0
let LetterGuideButtonAddSpace = 10.0
let LetterGuideButtonTrailingSpace = 18.0

enum ControllerButtonType {
    case Button_A
    case Button_B
    case Button_X
    case Button_Y
    case None
}

enum LetterCircleStyle {
    case Default
    case WhiteBG
    case BlackBG
    
    func getLetterCircleInfo(buttonType:ControllerButtonType) -> LetterCircleInfo {
        var letter = ""
        switch buttonType {
        case .Button_A:
            letter = "A"
        case .Button_B:
            letter = "B"
        case .Button_X:
            letter = "X"
        case .Button_Y:
            letter = "Y"
        case .None:
            letter = ""
        }
        
        switch self {
        case .Default:
            return LetterCircleInfo(letter: letter, letterColor: .Onyx, circleColor: .white)
        case .WhiteBG:
            return LetterCircleInfo(letter: letter, letterColor: .black, circleColor: .white)
        case .BlackBG:
            return LetterCircleInfo(letter: letter, letterColor: .white, circleColor: .black)
        }
    }
}

private struct LetterCircle: View {
    var letter:String = "A"
    var circleColor: Color = Color.red
    var letterColor: Color = Color.Onyx
    
    var body: some View {
        Text(letter)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(letterColor)
//            .sfProTextFont(weight: .bold, size: 16.0, textColor: letterColor)
            .frame(width: 28, height: 28, alignment: .center)
            .cornerRadius(14)
            .background(circleColor)
            .clipShape(Circle())
    }
}

struct LetterCircleInfo {
    var letter:String = "A"
    var circleColor: Color = Color.white
    var letterColor: Color = Color.Onyx
    
    init(letter:String, letterColor:Color, circleColor:Color) {
        self.letter = letter
        self.letterColor = letterColor
        self.circleColor = circleColor
    }
}

struct LetterGuideButton: View {
    var buttonType : ControllerButtonType = .Button_A
    var title:String = ""
    var backgroundColor : Color = Color.Onyx.opacity(0.5)
    var textColor : Color = Color.white
    //可以修改左右边距，不同UI需求不同，默认是10
    var addSpace : CGFloat = LetterGuideButtonAddSpace
    var trailingSpace : CGFloat = LetterGuideButtonTrailingSpace
    var action : (()->Void)? = nil
    var letterCircleStyle:LetterCircleStyle = .Default
    var isNeedStrokeBorder:Bool = false
    var blurStyle: UIBlurEffect.Style = .light
    
    var body: some View {
        
        let buttonInfo = letterCircleStyle.getLetterCircleInfo(buttonType: buttonType)
        
        return Button {
            if self.action != nil {
                self.action!()
            }
        } label: {
            HStack {
                if buttonType != .None {
                    LetterCircle(letter: buttonInfo.letter, circleColor: buttonInfo.circleColor, letterColor: buttonInfo.letterColor)
                    Spacer().frame(width: 8)
                }
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
//                    .sfProTextFont(weight: .medium, size: 17.0, textColor: textColor)
            }
            .frame(height: LetterGuideButtonHeight)
            .padding(.leading, addSpace)
            .padding(.trailing, trailingSpace)
            .background(backgroundColor)
            .cornerRadius(LetterGuideButtonRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LetterGuideButtonRadius)
                    .stroke(isNeedStrokeBorder ? Color.RazerGreen:Color.clear, lineWidth: 2)
            )
        }
        
    }
}

struct BlurLetterGuideButton: View {
    var buttonType : ControllerButtonType = .Button_A
    var title:String = ""
    var backgroundColor : Color = Color.Onyx.opacity(0.5)
    var textColor : Color = Color.white
    //可以修改左右边距，不同UI需求不同，默认是10
    var addSpace : CGFloat = 20.0
    var action : (()->Void)? = nil
    var letterCircleStyle:LetterCircleStyle = .Default
    var isNeedStrokeBorder:Bool = false
    var blurStyle: UIBlurEffect.Style = .light
    
    var body: some View {
        
        if #available(iOS 26.0, *) {
            LetterGuideButton(
                buttonType: buttonType,
                title: title,
                backgroundColor: backgroundColor,
                textColor: textColor,
                action: action,
                letterCircleStyle: letterCircleStyle,
                isNeedStrokeBorder: isNeedStrokeBorder)
            .compatibleGlassTouchEffect()
        } else {
            
            LetterGuideButton(
                buttonType: buttonType,
                title: title,
                backgroundColor: backgroundColor,
                textColor: textColor,
                action: action,
                letterCircleStyle: letterCircleStyle,
                isNeedStrokeBorder: isNeedStrokeBorder)
            .background(BlurView(style: blurStyle))
            .cornerRadius(LetterGuideButtonRadius)
        }
    }
    
}
//#if PREVIEW
//struct LetterGuideButton_Previews: PreviewProvider {
//    static var previews: some View {
//        LetterGuideButton()
//    }
//}
//#endif
