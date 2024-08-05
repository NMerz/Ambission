//
//  TightTextfield.swift
//  Ambission
//
//  Created by Nathan Merz on 8/2/24.
//

import Foundation
import SwiftUI

struct TightTextField: View {
    
    @Binding var contents: String
    @State var width: CGFloat = 50.0
    @Binding var textSize: CGFloat
    @State var currentMagnification = 1.0
    
    var body: some View {
        ZStack {
            Text(contents).opacity(0).background(GeometryReader{ reader in
                Color.clear.onChange(of: contents) {
                    print("reader size %f", reader.size)
                    width = reader.size.width
                }.onAppear() {
                    print("reader size %f", reader.size)
                    width = reader.size.width
                }.onChange(of: currentMagnification) {
                    print("reader size %f", reader.size)
                    width = reader.size.width
                }
            }).font(.system(size: textSize * currentMagnification)).ignoresSafeArea().fixedSize()
            TextField("", text: $contents).frame(width: width).font(.system(size: textSize * currentMagnification))
        }.simultaneousGesture(MagnifyGesture().onChanged({ gestureValue in
            currentMagnification = gestureValue.magnification
            print("bar the foo")
        }).onEnded({ finalValue in
            textSize *= finalValue.magnification
            currentMagnification = 1.0
        }))
    }
}

