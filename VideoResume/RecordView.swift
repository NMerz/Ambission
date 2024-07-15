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
    
    var body: some View {
        ZStack {
            if movieUrl != nil {
                VideoPlayer(player: player!).onAppear {
                    player?.play()
                }.ignoresSafeArea(.all)
            } else {
                if state != .settingUp {
                    VideoPreview(previewSource: cameraActor.previewSource).ignoresSafeArea(.all).overlay(.black.opacity(0.5))
                    Text(promptText).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center).font(.system(size: 500)).minimumScaleFactor(0.01).lineLimit(13).offset(y: -50).foregroundStyle(.white)
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
                                    state = .showResult
                                } else {
                                    recordingUrl = await cameraActor.startRecording()
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
        })
//        EmptyView().onAppear(perform: {
//            Task {
//                try await setUpCaptureSession()
//            }
//        })
    }
}
