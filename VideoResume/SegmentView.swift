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
    
    let segments: [String]
    @State var segmentUrls: [String:URL] = [:]
    @State var videoStates: [String:[String]] = [:]

    
    
    var body: some View {
        ScrollView {
            ForEach(segments, id: \.self) { segment in
                VStack {
                    Text(segment)
                    if segmentUrls[segment] == nil {
                        RoundedRectangle(cornerRadius: 5).strokeBorder(style: .init(lineWidth: 1, dash: [12, 12])).frame(height: 60).overlay {
                                Button("record section") {
                                    try! AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .defaultToSpeaker)
                                    navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                        segmentUrls[segment]
                                    }, set: { newUrl in
                                        segmentUrls[segment] = newUrl
                                        videoStates[segment] = []
                                    }), promptText: segment))
                                }
                        }
                    } else {
                        HStack {
                            Spacer().frame(minWidth: 10, maxWidth: .infinity)
                            Button(action: {
                                navPath.wrappedValue.append(EditClipView(navPath: navPath, outputUrl: Binding(get: {
                                    segmentUrls[segment]!
                                }, set: { newUrl in
                                    segmentUrls[segment] = newUrl
                                    videoStates[segment] = []
                                })))
                            }) {
                                Image(systemName: "scissors").resizable()
                            }.frame(width: 30, height: 30)
                            Spacer().frame(minWidth: 10, maxWidth: .infinity)
                            VideoPlayer(player: AVPlayer(url: segmentUrls[segment]!)).frame(width: 200, height: 200 * 16/9).ignoresSafeArea(.all).id(segmentUrls[segment])
                            Spacer().frame(minWidth: 10, maxWidth: .infinity)
                            Button(action: {
                                navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                    segmentUrls[segment]
                                }, set: { newUrl in
                                    videoStates[segment] = []
                                    segmentUrls[segment] = newUrl
                                }), promptText: segment))
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath").resizable()
                            }.frame(width: 30, height: 30)
                            Spacer().frame(minWidth: 10, maxWidth: .infinity)
                        }
                    }
//                    Text(String(describing: segmentUrls[segment]))
                    if segmentUrls[segment] != nil {
                        Button(action: {
                            PHPhotoLibrary.shared().performChanges {
                                let options = PHAssetResourceCreationOptions()
                                options.shouldMoveFile = true
                                let creationRequest = PHAssetCreationRequest.forAsset()
                                creationRequest.addResource(with: .video, fileURL: segmentUrls[segment]!, options: options)
                                videoStates[segment]?.append("exported")
                            }
                        }, label: {
                            if videoStates[segment]!.contains(["exported"]) {
                                Text("Export again").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                            } else {
                                Text("Export").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                            }
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                        if !videoStates[segment]!.contains(["background-free"]) {
                            Button(action: {
                                Task {
                                    let inputUrl = "dlb://" + UUID().uuidString + ".mov"
                                    print(inputUrl)
                                    do {
                                        let dolbyAuthorizer = DolbyAuthorizer()
                                        let signedUrlDict = try await Poster.postFor([String: String].self, requestURL: URL(string: "https://api.dolby.com/media/input")!, postContent: GetSignedUrlRequest(url: inputUrl), authorizer: dolbyAuthorizer)
                                        print(signedUrlDict)
                                        try await Poster.putFile(segmentUrls[segment]!, destination: URL(string: signedUrlDict["url"]!)!)
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
                                        videoStates[segment] = ["background-free"]
                                        segmentUrls[segment] = newPermanentDirectory
                                    } catch {
                                        print(error)
                                    }
                                }
                            }, label: {
                                Text("Remove background noise").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                            }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                        }
                    }
                    Spacer().frame(height:20)
                }
            }
            
        }.navigationDestination(for: RecordView.self) { newView in
            newView
        }.navigationDestination(for: EditClipView.self) { newView in
            newView
        }
    }
}

#Preview {
    var navPath = NavigationPath()
    return SegmentView(navPath: Binding(get: {
        navPath
    }, set: { newNavPath in
        navPath = newNavPath
    }), segments: ["intro", "job 1", "job 2", "job3", "call to action"])
}
