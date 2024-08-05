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

struct TextFieldProperties {
    var contents: String
    var position: CGPoint
    var xOffset = 0.0
    var yOffset = 0.0
    var textSize = 36.0
}

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
    @State var width: CGFloat = 100 {
        didSet {
            print("foo")
        }
    }
    @State var left = false
    @State var textFields: [String: TextFieldProperties] = [:]
    @State var textFieldKeys: [String] = []
    @State var processing = false
    
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
                    ZStack {
                        let videoHeight = width * 16 / 9 - max(40, width * 16 / 9 * 0.1)
                        VideoPlayer(player: player).frame(width: videoHeight * 9.0 / 16.0, height: videoHeight).opacity((processing ? 0 : 1))
                        if processing {
                            ProgressView()
                        }
                    }
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
                    Spacer().frame(width: 10)
                    Button(action: {
                        let newFieldId = UUID().uuidString
                        textFields[newFieldId] = TextFieldProperties(contents: "Add text here", position: CGPoint(x: width / 2, y: height / 2))
                        textFieldKeys.append(newFieldId)
                    }, label: {
                        Image(systemName: "character.textbox").resizable().scaledToFit()
                    }).frame(width: 40, height: 40)
                    Spacer().frame(maxWidth: .infinity)
                    Button(action: {
                        processing = true
                        Task {
                            outputUrl.wrappedValue = try await addText(currentUrl)
                            if !left {
                                navPath.wrappedValue.removeLast()
                                left = true
                            }
                        }
                    }, label: {
                        Image(systemName: "checkmark").resizable().scaledToFit()
                    }).frame(width: 40, height: 40)
                    Spacer().frame(width: 10)
                }.frame(width: width, height: 40)
            }.frame(maxHeight: .infinity).ignoresSafeArea(.all).background {
                GeometryReader{ reader in
                    Color.clear.preference(key: EditClipViewSize.self, value: reader.frame(in: .global).size)
                }.onPreferenceChange(EditClipViewSize.self) { size in
                    print(width)
                    height = size.height
                    width = size.width
                }
            }
            ForEach (textFieldKeys, id: \.self) {textFieldKey in
                TightTextField(contents: Binding(get: {
                    return textFields[textFieldKey]?.contents ?? ""
                }, set: { newValue in
                    textFields[textFieldKey]!.contents = newValue
                }), textSize: Binding(get: {
                    return textFields[textFieldKey]?.textSize ?? 36.0
                }, set: { newValue in
                    textFields[textFieldKey]?.textSize = newValue
                }))
                .position(CGPoint(x: textFields[textFieldKey]!.position.x + textFields[textFieldKey]!.xOffset, y: textFields[textFieldKey]!.position.y + textFields[textFieldKey]!.yOffset)).simultaneousGesture(DragGesture().onChanged({ dragValue in
                    textFields[textFieldKey]!.xOffset = dragValue.location.x - dragValue.startLocation.x
                    textFields[textFieldKey]!.yOffset = dragValue.location.y - dragValue.startLocation.y
                    print("foo the bar!")

                }).onEnded({ finalValue in
                    textFields[textFieldKey]!.xOffset = finalValue.location.x - finalValue.startLocation.x
                    textFields[textFieldKey]!.yOffset = finalValue.location.y - finalValue.startLocation.y
                    textFields[textFieldKey]!.position.x += textFields[textFieldKey]!.xOffset
                    textFields[textFieldKey]!.position.y += textFields[textFieldKey]!.yOffset
                    textFields[textFieldKey]!.xOffset = 0.0
                    textFields[textFieldKey]!.yOffset = 0.0
                })).opacity((processing ? 0 : 1))
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
        }.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }.preferredColorScheme(.dark).ignoresSafeArea()
//            .toolbar(.hidden, for: .navigationBar)
    }
    // AVVideoCompositionCoreAnimationTool crashes in the simulator, but it works on device: https://forums.developer.apple.com/forums/thread/133681
    func addText(_ addTo: URL) async throws -> URL {
        if textFieldKeys.isEmpty {
            return addTo
        }
        let asset = AVURLAsset(url: addTo)
        let composition = AVMutableComposition()
        
        let compositionTrack = composition.addMutableTrack(
          withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let assetTrack = try await asset.loadTracks(withMediaType: .video).first!

        let timeRange = try await CMTimeRange(start: .zero, duration: asset.load(.duration))
        try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
        compositionTrack.preferredTransform = try await assetTrack.load(.preferredTransform)
        let audioTrack2 = composition.addMutableTrack(
            withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioInput = try await asset.loadTracks(withMediaType: .audio).first!
        try audioTrack2?.insertTimeRange(timeRange, of: audioInput, at: .zero)

        try await print(asset.load(.duration))
        
        var preferredTransform = try await assetTrack.load(.preferredTransform)

        var expectedSize = composition.naturalSize
        if abs(preferredTransform.decomposed().rotation) == .pi / 2 {
            expectedSize = CGSize(width: composition.naturalSize.height, height: composition.naturalSize.width)
        }
               
                let mergedLayer = CALayer()
        mergedLayer.frame = CGRect(origin: .zero, size: expectedSize)
                let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: expectedSize)
                let videoLayer = CALayer()
                videoLayer.frame = CGRect(origin: .zero, size: expectedSize)
        overlayLayer.masksToBounds = true
        mergedLayer.addSublayer(videoLayer)
        mergedLayer.addSublayer(overlayLayer)

        for textFieldKey in textFieldKeys {
            let subtitleLayer = CATextLayer()
            let sourcePosition = textFields[textFieldKey]!.position
            print(sourcePosition)
            print(width)
            print(height)
            let displayedVideoHeight = width * 16 / 9 - max(40, width * 16 / 9 * 0.1)
            let displayedVideoWidth = displayedVideoHeight * 9.0 / 16.0
            print(displayedVideoWidth)
            print(displayedVideoHeight)
            let textOffset = (textFields[textFieldKey]?.textSize ?? 36.0) * 0.5
            let topGap = (height - 40 - displayedVideoHeight) / 2
            print((-sourcePosition.y - textOffset + topGap))
            subtitleLayer.frame = CGRect(origin: CGPoint(x: (sourcePosition.x - (width - displayedVideoWidth) / 2) / displayedVideoWidth * expectedSize.width - expectedSize.width, y: (-sourcePosition.y + textOffset + topGap) / displayedVideoHeight * expectedSize.height), size: CGSize(width: expectedSize.width * 2, height: expectedSize.height)) //origin is upper left corner of frame
            print(subtitleLayer.frame)
            subtitleLayer.foregroundColor = UIColor.white.cgColor
            print((textFields[textFieldKey]?.textSize ?? 36.0))
            print((textFields[textFieldKey]?.textSize ?? 36.0) * expectedSize.height / displayedVideoHeight)
            subtitleLayer.fontSize = (textFields[textFieldKey]?.textSize ?? 36.0) * expectedSize.height / displayedVideoHeight
            subtitleLayer.alignmentMode = .center
            //                subtitleLayer.add(captionAnimation, forKey: "opacity")
            subtitleLayer.string = textFields[textFieldKey]?.contents
            subtitleLayer.displayIfNeeded()
            overlayLayer.addSublayer(subtitleLayer)
            print(subtitleLayer)
        }
        
        let videoRotationComposition2 = AVMutableVideoComposition()
        videoRotationComposition2.animationTool = AVVideoCompositionCoreAnimationTool(
                  postProcessingAsVideoLayer: videoLayer,
                  in: mergedLayer)
        let compositionInstruction2 = AVMutableVideoCompositionInstruction()
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        print("nat size")
        print(composition.naturalSize)
        print(SegmentView.fixPreferredTransform(preferredTransform, inputSize: composition.naturalSize, desiredSize: expectedSize).decomposed())

        layerInstruction.setTransform(SegmentView.fixPreferredTransform(preferredTransform, inputSize: composition.naturalSize, desiredSize: expectedSize), at: .zero)
        compositionInstruction2.layerInstructions.append(layerInstruction)
        print("layer instructions")
        print(compositionInstruction2.layerInstructions)
        compositionInstruction2.timeRange = compositionTrack.timeRange
        videoRotationComposition2.instructions = [compositionInstruction2]
        videoRotationComposition2.renderSize = expectedSize
        videoRotationComposition2.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let exportSession2 = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        print("composition tracks")
        print(composition.tracks)
        print(composition.tracks.count)
        exportSession2.outputURL = FileManager().temporaryDirectory.appending(path: UUID().uuidString + ".mp4")
        exportSession2.outputFileType = .mp4
        exportSession2.videoComposition = videoRotationComposition2
        print("exporting")
        await exportSession2.export()
        
        
        return exportSession2.outputURL!
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
