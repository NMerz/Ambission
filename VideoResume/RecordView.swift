//
//  RecordView.swift
//  VideoResume
//
//  Created by Nathan Merz on 6/28/24.
//

import Foundation
import SwiftUI
@preconcurrency import AVFoundation
import AVKit


//extension String: Error {
//    
//}

protocol PreviewSource: Sendable {
    // Connects a preview destination to this source.
    func connect(to target: PreviewTarget)
}

/// A protocol that passes the app's capture session to the `CameraPreview` view.
protocol PreviewTarget {
    // Sets the capture session on the destination.
    func setSession(_ session: AVCaptureSession)
}

/// The app's default `PreviewSource` implementation.
struct DefaultPreviewSource: PreviewSource {
    
    let session: AVCaptureSession
    
    init(session: AVCaptureSession) {
        self.session = session
    }
    
    func connect(to target: PreviewTarget) {
        target.setSession(session)
    }
}


struct VideoPreview: UIViewRepresentable {
    let previewSource: PreviewSource
    
    func makeUIView(context: Context) -> UIView {
        let newView = VideoView()
        previewSource.connect(to: newView)
        return newView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

class VideoView: UIView, PreviewTarget {
    func setSession(_ session: AVCaptureSession) {
        previewLayer.session = session
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
       layer as! AVCaptureVideoPreviewLayer
    }
}

struct RecordView: View, Hashable {
    static func == (lhs: RecordView, rhs: RecordView) -> Bool {
        lhs.movieUrl == rhs.movieUrl && lhs.promptText == rhs.promptText
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(movieUrl)
        hasher.combine(promptText)
    }
    
    
    enum RecordingState {
        case settingUp
        case ready
        case recording
        case showResult
    }
    
    @State var state: RecordingState = .settingUp
    @State var movieUrl: Optional<URL> = nil
    @State var recordingUrl: Optional<URL> = nil
    @State var navPath: Binding<NavigationPath>
    @State var outputUrl: Binding<Optional<URL>>
    let promptText: String
    let cameraActor = CameraActor.shared
    @State var player: AVPlayer?
    @State var size = 32.0
    @State var width:CGFloat = 100
    @State var height: CGFloat = 200
    @State var scrollingOffset: CGFloat = 0
    @State var textHeight: CGFloat = 20
    @State var scrollTime = 10.0
    
    var body: some View {
        ZStack {
            if movieUrl != nil {
                VideoPlayer(player: player!).onAppear {
                    player?.play()
                }.ignoresSafeArea(.all)
            } else {
                if state != .settingUp {
                    VideoPreview(previewSource: cameraActor.previewSource).ignoresSafeArea(.all).overlay(.black.opacity(0.5)).overlay {
                        Text(promptText).font(.system(size: size, design: .monospaced)).fixedSize(horizontal: false, vertical: true).frame(width: width, alignment: .topLeading).offset(y: textHeight / 2 - height / 2 + 30 - scrollingOffset).foregroundStyle(.white).background {
                            GeometryReader{ reader in
                                Color.clear.preference(key: RecordViewTextSize.self, value: reader.frame(in: .global).size)
                            }.onPreferenceChange(RecordViewTextSize.self) { size in
                                textHeight = size.height
                            }
                        } // Sizing is causing trouble here unless this is an overlay
                    }
                    
                    if state != .recording {
                        VStack {
                            HStack {
                                Text("A").font(.system(size: 18))
                                Slider(value: Binding(get: {
                                    return size / 192.0
                                }, set: { newSize in
                                    size = round(newSize * 192.0)
                                    print(size)
                                })).frame(width: 200, height: 30)
                                Text("A").font(.system(size: 24))
                            }
                            Spacer().frame(maxHeight: .infinity)
                        }
                        HStack {
                            Spacer().frame(maxWidth: .infinity)
                            VStack (alignment: .leading) {
                                Image(systemName: "tortoise").resizable().scaledToFit().frame(width: 30).foregroundStyle(.white)
                                Slider(value: Binding(get: {
                                    return 1 - (scrollTime - 1) / 29
                                }, set: { newSize in
                                    scrollTime = (1 - newSize) * 29 + 1
                                    print(scrollTime)
                                })).frame(width: 200, height: 30).rotationEffect(.init(degrees: 90)).fixedSize().frame(width: 30, height: 200)
                                Image(systemName: "hare").resizable().scaledToFit().frame(width: 30).foregroundStyle(.white)
                                Text(String.StringLiteralType(format: "%.1f\nsec", scrollTime)).frame(width: 40, alignment: .leading).foregroundStyle(.white)
                            }
                        }
                    }
                    VStack {
                        Spacer().frame(maxHeight: .infinity)
                        Button {
                            Task.detached(operation: {
                                if state == .recording {
                                    let finalUrl = try await cameraActor.stopRecording()
                                    await MainActor.run {
                                        player = AVPlayer(url: finalUrl)
                                        movieUrl = finalUrl
                                        print(movieUrl)
                                        print(player!.currentItem!.status.rawValue)
                                        print(player?.currentItem?.error)
                                    }
                                    scrollingOffset = 0
                                    state = .showResult
                                } else {
                                    recordingUrl = await cameraActor.startRecording()
                                    withAnimation(.linear(duration: scrollTime)) {
                                        scrollingOffset = textHeight
                                    }
                                    state = .recording
                                }
                            })
                        } label: {
                            if state == .recording {
                                Rectangle().frame(width: 60, height: 60).foregroundStyle(.red)
                            } else {
                                Circle().frame(width: 60, height: 60).foregroundStyle(.red)
                            }
                        }
                        Spacer().frame(height: 20)
                    }
                }
            }
            if state == .showResult {
                HStack{
                    Spacer().frame(width: 10)
                    Button {
                        state = .ready
                        movieUrl = nil
                    } label: {
                        Image(systemName: "x.circle").resizable().scaledToFit().contentShape(.circle)
                    }.frame(width: 60, height: 60)
                        
                    Spacer().frame(maxWidth: .infinity)
                    Button {
                        outputUrl.wrappedValue = movieUrl
                        navPath.wrappedValue.removeLast()
                    } label: {
                        Image(systemName: "checkmark.circle").resizable().scaledToFit().contentShape(.circle)
                    }.frame(width: 60, height: 60)
                    Spacer().frame(width: 10)
                }
            }
        }.onAppear(perform: {
            Task {
                try await cameraActor.setUpCaptureSession()
                state = .ready
            }
        }).background {
            GeometryReader{ reader in
                Color.clear.preference(key: RecordViewSize.self, value: reader.frame(in: .global).size)
            }.onPreferenceChange(RecordViewSize.self) { size in
                height = size.height
                width = size.width
            }
        }
    }
}


struct RecordViewSize: PreferenceKey {
    static var defaultValue: CGSize = CGSize()
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let nextSize = nextValue()
        value.width += nextSize.width
        value.height += nextSize.height
    }
    
    typealias Value = CGSize
}


struct RecordViewTextSize: PreferenceKey {
    static var defaultValue: CGSize = CGSize()
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let nextSize = nextValue()
        value.width += nextSize.width
        value.height += nextSize.height
    }
    
    typealias Value = CGSize
}
