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

struct BlurView: UIViewRepresentable {
    typealias UIViewType = UIVisualEffectView
    var style : UIBlurEffect.Style = .systemUltraThinMaterialDark
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

//struct BlurView_Previews: PreviewProvider {
//    static var previews: some View {
//        BlurView(style: .light)
//    }
//}

struct GlassEffectView : View {
    
    var sizeWidth:CGFloat = .infinity
    var sizeHeight:CGFloat = .infinity
    var radius:CGFloat = 1.0
    var color:Color = Color.black.opacity(0.2)
    
    var body: some View {
        Button.init(action: {
            
        }, label: {
            color.frame(width:sizeWidth,height:sizeHeight, alignment: .center)
                .compatibleGlassEffect(radius: radius)
        })
        //.compatibleGlassEffect(radius: radius)
        .cornerRadius(radius)
        .clipped()
        .disabled(true)
        .animation(.none)
    }
}
