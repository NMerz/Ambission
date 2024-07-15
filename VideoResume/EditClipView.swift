//
//  EditClipView.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/9/24.
//

import Foundation
import SwiftUI
import AVFoundation
import AVKit

struct EditClipView: View, Hashable {
    static func == (lhs: EditClipView, rhs: EditClipView) -> Bool {
        lhs.outputUrl.wrappedValue == rhs.outputUrl.wrappedValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(outputUrl.wrappedValue)
    }
    
    @State var navPath: Binding<NavigationPath>
    @State var outputUrl: Binding<URL>
    @State var currentUrl: URL
    @State var player: AVPlayer
    @State var pastUrls: [URL] = []
    @State var displaySideChoice: Bool = false
    @State var height: CGFloat = 200
    @State var width: CGFloat = 100
    @State var left = false
    
    init(navPath: Binding<NavigationPath>, outputUrl: Binding<URL>) {
        self.navPath = navPath
        self.outputUrl = outputUrl
        self.currentUrl = outputUrl.wrappedValue
        player = AVPlayer(url: outputUrl.wrappedValue)
    }
    
    func cutVideo(start: CMTime, end: CMTime) async {
        let exportSession = AVAssetExportSession(asset: AVAsset(url: currentUrl), presetName: AVAssetExportPresetPassthrough)!
        let newRange = CMTimeRange(start: start, end: end)
        exportSession.timeRange = newRange
        exportSession.outputURL = FileManager().temporaryDirectory.appending(path: UUID().uuidString + "." + currentUrl.pathExtension)
        exportSession.outputFileType = .mov
        await exportSession.export()
        pastUrls.append(currentUrl)
        currentUrl = exportSession.outputURL!
        player = AVPlayer(url: currentUrl)
        displaySideChoice = false
    }
    
    var body: some View {
        ZStack {
            VStack (alignment: .center, spacing: 0) {
                HStack {
                    Spacer().frame(maxWidth: .infinity)
                    VideoPlayer(player: player).frame(width: width, height: width * 16 / 9 - max(40, width * 16 / 9 * 0.1))
                    Spacer().frame(maxWidth: .infinity)
                }
                HStack {
                    Spacer().frame(width: 10)
                    if pastUrls.count > 0 {
                        Button(action: {
                            currentUrl = pastUrls.removeLast()
                            player = AVPlayer(url: currentUrl)
                        }, label: {
                            Image(systemName: "arrowshape.turn.up.backward.fill").resizable().scaledToFit()
                        }).frame(width: 40, height: 40)
                        Spacer().frame(maxWidth: .infinity)
                    }
                    Button(action: {
                        displaySideChoice = true
                    }, label: {
                        Image(systemName: "scissors").resizable().scaledToFit()
                    }).frame(width: 40, height: 40)
                    Spacer().frame(maxWidth: .infinity)
                    Button(action: {
                        outputUrl.wrappedValue = currentUrl
                        if !left {
                            navPath.wrappedValue.removeLast()
                            left = true
                        }
                    }, label: {
                        Image(systemName: "checkmark").resizable().scaledToFit()
                    }).frame(width: 40, height: 40)
                    Spacer().frame(width: 10)
                }.frame(width: width, height: 40)
            }.ignoresSafeArea(.all).background {
                GeometryReader{ reader in
                    Color.clear.preference(key: EditClipViewSize.self, value: reader.frame(in: .global).size)
                }.onPreferenceChange(EditClipViewSize.self) { size in
                    height = size.height
                    width = size.width
                }
            }
            if displaySideChoice {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).frame(maxWidth: .infinity, maxHeight: .infinity).foregroundStyle(Color(uiColor: .systemBackground).opacity(0.8))
                    VStack {
                        Text("Which side of the cut should be kept?").font(.system(size: 32))
                        HStack {
                            Spacer().frame(width: 10)
                            Button(action: {
                                let originalStart = CMTime(seconds: 0, preferredTimescale: 1000)
                                Task {
                                    await cutVideo(start: originalStart, end: player.currentTime())
                                }
                            }, label: {
                                Text("Keep before")
                            })
                            Spacer().frame(maxWidth: .infinity)
                            Button(action: {
                                Task {
                                    await cutVideo(start: player.currentTime(), end: player.currentItem!.duration)
                                }
                            }, label: {
                                Text("Keep after")
                            })
                            Spacer().frame(width: 10)
                        }
                        Button(action: {
                            displaySideChoice = false
                        }, label: {
                            Text("Cancel")
                        })
                    }
                }.frame(width: width * 0.8, height: 200)
            }
        }.preferredColorScheme(.dark)
//            .toolbar(.hidden, for: .navigationBar)
    }
}


struct EditClipViewSize: PreferenceKey {
    static var defaultValue: CGSize = CGSize()
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let nextSize = nextValue()
        value.width += nextSize.width
        value.height += nextSize.height
    }
    
    typealias Value = CGSize
}
