//
//  PreviewView.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/11/24.
//

import Foundation
import SwiftUI
import AVKit

struct PreviewView: View, Hashable {
    static func == (lhs: PreviewView, rhs: PreviewView) -> Bool {
        lhs.outputUrl == rhs.outputUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(outputUrl)
    }
    
    @State var navPath: Binding<NavigationPath>
    let outputUrl: URL
    
    var body: some View {
        ZStack {
            VideoPlayer(player: AVPlayer(url: outputUrl)).ignoresSafeArea(.all)
            VStack() {
                Spacer().frame(maxHeight: .infinity)
                ShareLink(item: outputUrl, label: {
                    Image(systemName: "square.and.arrow.up").resizable()
                }).frame(width: 30, height: 30)
                Spacer().frame(height: 10)
            }
        }
    }
}
