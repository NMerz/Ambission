//
//  RecordView.swift
//  VideoResume
//
//  Created by Nathan Merz on 6/26/24.
//

import Foundation
import SwiftUI
import Photos
import AVKit
import PhotosUI


struct GetSignedUrlRequest: Codable {
    let url: String
}

struct DolbyIsolationChange: Codable {
    let enable: Bool
    let amount: Int
}

struct DoblySpeechChange: Codable {
    let isolation: DolbyIsolationChange
}

struct DolbyAudioChange: Codable {
    let speech: DoblySpeechChange
}

struct DolbyEnhanceRequest: Codable {
    let input: String
    let output: String
    let audio: DolbyAudioChange
}

protocol CanVerifyDone {
    func verifyDone() -> Bool
}

struct JobStatusResponse: Codable, CanVerifyDone {
    let status: String
    
    func verifyDone() -> Bool {
        return status == "Success"
    }
}

struct SegmentView: View, Hashable {
    static func == (lhs: SegmentView, rhs: SegmentView) -> Bool {
        lhs.segments == rhs.segments
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(segments)
    }
    
    @State var navPath: Binding<NavigationPath>
    
    @State var segments: [String]
    @State var segmentUrls: [String:URL] = [:]
    @State var videoStates: [String:[String]]
    @State var segmentText: [String: String]
    @State var processingFinal = false
    
    init(navPath: Binding<NavigationPath>, segmentText: [String: String]) {
        self.navPath = navPath
        var states: [String: [String]] = [:]
        var segments: [String] = []
        for keyVal in segmentText.keys {
            segments.append(keyVal)
            states[keyVal] = []
        }
        self.videoStates = states
        self.segments = segments.sorted()
        self.segmentText = segmentText
    }
    
    var body: some View {
        GeometryReader{ reader in
            if processingFinal {
                ProgressView()
            } else {
                VStack {
                    List($segments, id: \.self, editActions: .all) { segment in
                        VStack {
                            TextField("", text: Binding(get: {
                                print(segment.wrappedValue)
                                print(segmentText)
                                return segmentText[segment.wrappedValue]!
                            }, set: { newValue in
                                segmentText[segment.wrappedValue] = newValue
                            }), axis: .vertical)
                            if videoStates[segment.wrappedValue]!.contains(["processing"]) {
                                ProgressView()
                            } else {
                                if segmentUrls[segment.wrappedValue] == nil {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 5).strokeBorder(style: .init(lineWidth: 1, dash: [12, 12])).frame(height: 60).overlay {
                                            Button("record section") {
                                                try! AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .defaultToSpeaker)
                                                navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                                    segmentUrls[segment.wrappedValue]
                                                }, set: { newUrl in
                                                    segmentUrls[segment.wrappedValue] = newUrl
                                                    videoStates[segment.wrappedValue] = []
                                                }), promptText: segmentText[segment.wrappedValue]!))
                                            }.buttonStyle(PlainButtonStyle())
                                            
                                        }
                                        Spacer().frame(width: 10)
                                        PhotosPicker(selection: Binding(get: {
                                            print("unexpected get")
                                            return nil
                                        }, set: { newPick in
                                            videoStates[segment.wrappedValue] = []
                                            VideoModel(videoUrls: $segmentUrls, updateKey: segment.wrappedValue).newRecipeVideo = newPick
                                        }), matching: .videos, photoLibrary: .shared()) {
                                            Image(systemName: "square.and.arrow.down").resizable().scaledToFit()
                                        }.frame(width: 30, height: 30)
                                        Spacer().frame(width: 10)
                                    }
                                } else {
                                    HStack {
                                        Spacer().frame(width: 10)
                                        Button(action: {
                                            navPath.wrappedValue.append(EditClipView(navPath: navPath, outputUrl: Binding(get: {
                                                segmentUrls[segment.wrappedValue]!
                                            }, set: { newUrl in
                                                segmentUrls[segment.wrappedValue] = newUrl
                                                videoStates[segment.wrappedValue] = []
                                            })))
                                        }) {
                                            Image(systemName: "scissors").resizable()
                                        }.frame(width: 30, height: 30).buttonStyle(PlainButtonStyle())
                                        Spacer().frame(width: 10)
                                        VideoPlayer(player: AVPlayer(url: segmentUrls[segment.wrappedValue]!)).frame(width: 200, height: 200 * 16/9).ignoresSafeArea(.all).id(segmentUrls[segment.wrappedValue])
                                        Spacer().frame(width: 10)
                                        PhotosPicker(selection: Binding(get: {
                                            print("unexpected get")
                                            return nil
                                        }, set: { newPick in
                                            videoStates[segment.wrappedValue] = []
                                            VideoModel(videoUrls: $segmentUrls, updateKey: segment.wrappedValue).newRecipeVideo = newPick
                                        }), matching: .videos, photoLibrary: .shared()) {
                                            Image(systemName: "square.and.arrow.down").resizable().scaledToFit()
                                        }.frame(width: 30, height: 30)
                                        Spacer().frame(width: 10)
                                        Button(action: {
                                            navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                                segmentUrls[segment.wrappedValue]
                                            }, set: { newUrl in
                                                videoStates[segment.wrappedValue] = []
                                                segmentUrls[segment.wrappedValue] = newUrl
                                            }), promptText: segmentText[segment.wrappedValue]!))
                                        }) {
                                            Image(systemName: "arrow.triangle.2.circlepath").resizable()
                                        }.frame(width: 30, height: 30).buttonStyle(PlainButtonStyle())
                                        Spacer().frame(width: 10)
                                    }
                                }
                                //                    Text(String(describing: segmentUrls[segment]))
                                if segmentUrls[segment.wrappedValue] != nil {
                                    Button(action: {
                                        PHPhotoLibrary.shared().performChanges {
                                            let options = PHAssetResourceCreationOptions()
                                            options.shouldMoveFile = false
                                            let creationRequest = PHAssetCreationRequest.forAsset()
                                            creationRequest.addResource(with: .video, fileURL: segmentUrls[segment.wrappedValue]!, options: options)
                                            videoStates[segment.wrappedValue]?.append("exported")
                                        }
                                    }, label: {
                                        if videoStates[segment.wrappedValue]!.contains(["exported"]) {
                                            Text("Export again").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                                        } else {
                                            Text("Export").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                                        }
                                    }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label))).buttonStyle(PlainButtonStyle())
                                    if !videoStates[segment.wrappedValue]!.contains(["background-free"]) {
                                        Button(action: {
                                            Task {
                                                var existingStates: [String] = []
                                                if videoStates[segment.wrappedValue] != nil {
                                                    existingStates = videoStates[segment.wrappedValue]!
                                                }
                                                existingStates.append("processing")
                                                videoStates[segment.wrappedValue] = existingStates
                                                let inputUrl = "dlb://" + UUID().uuidString + ".mov"
                                                print(inputUrl)
                                                do {
                                                    let dolbyAuthorizer = DolbyAuthorizer()
                                                    let signedUrlDict = try await Poster.postFor([String: String].self, requestURL: URL(string: "https://api.dolby.com/media/input")!, postContent: GetSignedUrlRequest(url: inputUrl), authorizer: dolbyAuthorizer)
                                                    print(signedUrlDict)
                                                    try await Poster.putFile(segmentUrls[segment.wrappedValue]!, destination: URL(string: signedUrlDict["url"]!)!)
                                                    let outputUrl = "dlb://" + UUID().uuidString + ".mov"
                                                    let enhanceJobDict = try await Poster.postFor([String: String].self, requestURL:  URL(string: "https://api.dolby.com/media/enhance")!, postContent: DolbyEnhanceRequest(input: inputUrl, output: outputUrl, audio: DolbyAudioChange(speech: DoblySpeechChange(isolation: DolbyIsolationChange(enable: true, amount: 100)))), authorizer: dolbyAuthorizer)
                                                    print(enhanceJobDict)
                                                    let pollUrl = "https://api.dolby.com/media/enhance?job_id=" + enhanceJobDict["job_id"]!
                                                    try await Poll.monitor(URL(string: pollUrl)!, responseType: JobStatusResponse.self, authorizer: dolbyAuthorizer)
                                                    print("ready")
                                                    let newLocalUrl = try await Poster.downloadFile("https://api.dolby.com/media/output", params: ["url": outputUrl], authorizer: dolbyAuthorizer)
                                                    print(newLocalUrl)
                                                    let newPermanentDirectory = FileManager().temporaryDirectory.appending(path: UUID().uuidString + ".mov")
                                                    try FileManager().moveItem(at: newLocalUrl, to: newPermanentDirectory)
                                                    print(newPermanentDirectory)
                                                    videoStates[segment.wrappedValue] = ["background-free"]
                                                    segmentUrls[segment.wrappedValue] = newPermanentDirectory
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }, label: {
                                            Text("Remove background noise").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label))).buttonStyle(PlainButtonStyle())
                                    }
                                }
                                Spacer().frame(height:20)
                            }
                        }
                    }.listStyle(.plain).frame(height: max(200, reader.size.height - 50))
                    if segmentUrls.count > 0 {
                        Button(action: {
                            Task {
                                processingFinal = true
                                let finalMovie = AVMutableComposition()
                                var currentTime = CMTime.zero
                                let audioTrack = finalMovie.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(1))
                                let videoTrack = finalMovie.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID(2))
                                let videoRotationComposition = AVMutableVideoComposition()
                                let compositionInstruction = AVMutableVideoCompositionInstruction()
                                for segment in segments {
                                    if segmentUrls[segment] == nil {
                                        continue
                                    }
                                    let segmentMovie = AVURLAsset(url: segmentUrls[segment]!)
                                    let segmentDuration = try await segmentMovie.load(.duration)
                                    
                                    try audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: segmentDuration), of: try await segmentMovie.loadTracks(withMediaType: .audio)[0], at: currentTime)
                                    let segmentVideoTrack = try await segmentMovie.loadTracks(withMediaType: .video)[0]
                                    
                                    
                                    try videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: segmentDuration), of: segmentVideoTrack, at: currentTime)
                                    
                                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
                                    let preferredTransform = try await segmentVideoTrack.load(.preferredTransform)
                                    layerInstruction.setTransform(preferredTransform, at: currentTime)
                                    
                                    
                                    currentTime = CMTimeAdd(currentTime, segmentDuration)
                                    layerInstruction.setOpacity(0.0, at: currentTime)
                                    print(currentTime)
                                    compositionInstruction.layerInstructions.append(layerInstruction)
                                    print("layer instructions")
                                    print(compositionInstruction.layerInstructions)
                                }
                                compositionInstruction.timeRange = videoTrack!.timeRange
                                videoRotationComposition.instructions = [compositionInstruction]
                                videoRotationComposition.renderSize = CGSize(width: 1080, height: 1920)
                                
                                videoRotationComposition.frameDuration = CMTimeMake(value: 1, timescale: videoTrack!.naturalTimeScale)
                                
                                let exportSession = AVAssetExportSession(asset: finalMovie, presetName: AVAssetExportPreset1920x1080)!
                                exportSession.outputURL = FileManager().temporaryDirectory.appending(path: UUID().uuidString + ".mov")
                                exportSession.outputFileType = .mov
                                exportSession.videoComposition = videoRotationComposition
                                await exportSession.export()
                                processingFinal = false
                                navPath.wrappedValue.append(PreviewView(navPath: navPath, outputUrl: exportSession.outputURL!))
                            }
                        }, label: {
                            Text("Combine segments").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                        }).navigationDestination(for: PreviewView.self) { newView in
                            newView
                        }.padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    }
                }.navigationDestination(for: RecordView.self) { newView in
                    newView
                }.navigationDestination(for: EditClipView.self) { newView in
                    newView
                }
            }
        }
    }
}

#Preview {
    var navPath = NavigationPath()
    return SegmentView(navPath: Binding(get: {
        navPath
    }, set: { newNavPath in
        navPath = newNavPath
    }), segmentText: ["1": "intro", "2": "job 1", "3": "job 2", "4": "job3", "5": "call to action"])
}



class VideoModel {
    var videoUrls: Binding<[String: URL]>
    var updateKey: String
    
    var newRecipeVideo: Optional<PhotosPickerItem> {
        didSet {
            if newRecipeVideo == nil {
                return
            }
            Task {
                let upLoadableRecipeVideo = try await newRecipeVideo!.loadTransferable(type: UploadableVideo.self)
                if upLoadableRecipeVideo == nil {
                    return
                }
                await MainActor.run {
                    videoUrls.wrappedValue[updateKey] = upLoadableRecipeVideo!.videoUrl
                }
            }
        }
    }
    
    class VideoSaveError: Error {
        
    }
    
    struct UploadableVideo: Transferable {
        let videoUrl: URL
        
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(importedContentType: .movie) { movieFile in
                let movieFile = movieFile.file
                let baseDir = FileManager().temporaryDirectory
                let pathAvailableOutsideClosure = baseDir.appendingPathComponent(UUID().uuidString + "." + movieFile.pathExtension)
                print(pathAvailableOutsideClosure)
                do {
                    try FileManager.default.copyItem(at: movieFile, to: pathAvailableOutsideClosure)
                } catch {
                    print(error)
                    throw VideoSaveError()
                }
                
                
                return self.init(videoUrl: pathAvailableOutsideClosure)
            }
        }
    }
    init(videoUrls: Binding<[String: URL]>, updateKey: String) {
        self.videoUrls = videoUrls
        self.updateKey = updateKey
        self.newRecipeVideo = nil
    }
}
