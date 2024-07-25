//
//  PreviewView.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/11/24.
//

import Foundation
import SwiftUI
import AVKit
import PhotosUI

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
                HStack {
                    ShareLink(item: outputUrl, label: {
                        Image(systemName: "square.and.arrow.up").resizable().scaledToFit()
                    }).frame(width: 30, height: 30)
//                    Button {
//                        PHPhotoLibrary.shared().performChanges({
//                            let options = PHAssetResourceCreationOptions()
//                            options.shouldMoveFile = false
//                            let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: outputUrl)
//                        }, completionHandler: {foo, err in
//                            print(foo)
//                            print(err)
//                        })
//                    } label: {
//                        Image(systemName: "square.and.arrow.down").resizable().scaledToFit()
//                    }

                }
                Spacer().frame(height: 10)
            }
        }
    }
}
