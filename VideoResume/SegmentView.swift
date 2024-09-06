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
import FirebaseStorage

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
        lhs.videoModel.segments == rhs.videoModel.segments && lhs.videoModel.segmentUrls == rhs.videoModel.segmentUrls && lhs.videoStates == rhs.videoStates && lhs.processingFinal == rhs.processingFinal
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(videoModel.segments)
        hasher.combine(videoModel.segmentUrls)
        hasher.combine(videoStates)
    }
    
    @State var navPath: Binding<NavigationPath>
    @Environment(\.modelContext) var modelContext

    @State var videoStates: [String:[String]]
    @State var processingFinal = false
    @State var videoModel: CreatedVideo
    @State var addSubtitles: Bool = false
    @State var offsetSegment: String? = nil
    @State var offset = 0.0
    
    init(navPath: Binding<NavigationPath>, videoModel: CreatedVideo) {
        self.navPath = navPath
        var states: [String: [String]] = [:]
        for keyVal in videoModel.segments {
            states[keyVal] = []
        }
        self.videoModel = videoModel
        self.videoStates = states
        if localMode {
            functions.useEmulator(withHost: "http://127.0.0.1", port: 5001)
        }
    }
    
    static func exportSegment(_ toExport: URL?) {
        if toExport == nil {
            return
        }
        let tempPathForPHPPhotoToDestroy = FileManager().temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + toExport!.pathExtension)
        print(tempPathForPHPPhotoToDestroy)
        do {
            try FileManager.default.copyItem(at: toExport!, to: tempPathForPHPPhotoToDestroy)
        } catch {
            print(error)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = false
            let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: tempPathForPHPPhotoToDestroy)
        }, completionHandler: {foo, err in
            print(foo)
            print(err)
        })
    }
    
    var body: some View {
        GeometryReader{ reader in
            if processingFinal {
                ProgressView()
            } else {
                VStack {
                    ScrollView {
                        ForEach($videoModel.segments, id: \.self) { segment in
                            ZStack {
                                VStack {
                                    HStack (alignment: .top) {
                                        Spacer().frame(width: 10)
                                        Group {
                                            if videoModel.segmentUrls[segment.wrappedValue] != nil {
                                                if (videoStates[segment.wrappedValue] ?? []).contains(["processing"]) {
                                                    RoundedRectangle(cornerRadius: 10.0).stroke(AMBISSION_ORANGE).foregroundStyle(Color.clear).overlay {
                                                        ProgressView()
                                                    }.frame(width: 100, height: 100 * 16/9)
                                                } else {
                                                    VStack {
                                                        VideoPlayer(player: AVPlayer(url: videoModel.segmentUrls[segment.wrappedValue]!)).frame(width: 100, height: 100 * 16/9).ignoresSafeArea(.all).id(videoModel.segmentUrls[segment.wrappedValue]).overlay {
                                                            VStack {
                                                                Spacer().frame(maxHeight: .infinity)
                                                                HStack (spacing: 0) {
                                                                    Spacer().frame(width: 5)
                                                                    Button(action: {
                                                                        Task {
                                                                            navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                                                                videoModel.segmentUrls[segment.wrappedValue]
                                                                            }, set: { newUrl in
                                                                                videoStates[segment.wrappedValue] = ["exported"]
                                                                                videoModel.segmentUrls[segment.wrappedValue] = newUrl
                                                                                SegmentView.exportSegment(newUrl)
                                                                            }), promptText: videoModel.segmentTexts[segment.wrappedValue] ?? ""))
                                                                        }
                                                                    }, label: {
                                                                        Image(systemName: "arrow.clockwise").resizable().scaledToFit().frame(width: 15, height: 15)
                                                                    }).tint(AMBISSION_ORANGE).buttonStyle(BorderedProminentButtonStyle())
                                                                    Spacer().frame(maxWidth: .infinity)
                                                                    Button(action: {
                                                                        videoModel.segmentUrls.removeValue(forKey: segment.wrappedValue)
                                                                        videoStates.removeValue(forKey: segment.wrappedValue)
                                                                    }, label: {
                                                                        Image(systemName: "trash").resizable().scaledToFit().frame(width: 15, height: 15)
                                                                    }).tint(AMBISSION_ORANGE).buttonStyle(BorderedProminentButtonStyle())
                                                                    Spacer().frame(width: 5)
                                                                }
                                                                Spacer().frame(height: 5)
                                                            }
                                                        }
                                                        Button(action: {
                                                            navPath.wrappedValue.append(EditClipView(navPath: navPath, outputUrl: Binding(get: {
                                                                videoModel.segmentUrls[segment.wrappedValue]!
                                                            }, set: { newUrl in
                                                                videoStates[segment.wrappedValue] = []
                                                                videoModel.segmentUrls[segment.wrappedValue] = newUrl
                                                            })))
                                                        }) {
                                                            RoundedRectangle(cornerRadius: 10.0).foregroundStyle(BUTTON_PURPLE).overlay {
                                                                VStack {
                                                                    Spacer().frame(height: 5)
                                                                    Image(systemName: "scissors").resizable().rotationEffect(Angle(degrees: -90)).scaledToFit().foregroundStyle(Color.white)
                                                                    Spacer().frame(height: 5)
                                                                }
                                                            }
                                                        }.frame(width: 100, height: 33).buttonStyle(PlainButtonStyle())
                                                    }
                                                }
                                            } else {
                                                VStack {
                                                    RoundedRectangle(cornerRadius: 10.0).stroke(AMBISSION_ORANGE).foregroundStyle(Color.clear).overlay {
                                                        RoundedRectangle(cornerRadius: 10.0).overlay(
                                                            Image(systemName: "video").foregroundStyle(Color.white).frame(width: 40, height: 40)
                                                        ).foregroundStyle(AMBISSION_ORANGE).frame(width: 50, height: 50)
                                                    }.onTapGesture {
                                                        try! AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .defaultToSpeaker)
                                                        navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                                            videoModel.segmentUrls[segment.wrappedValue]
                                                        }, set: { newUrl in
                                                            videoStates[segment.wrappedValue] = ["exported"]
                                                            videoModel.segmentUrls[segment.wrappedValue] = newUrl
                                                            SegmentView.exportSegment(newUrl)
                                                        }), promptText: videoModel.segmentTexts[segment.wrappedValue] ?? ""))
                                                    }.frame(width: 100, height: 100 * 16/9)
                                                    AddVideoView(videoStates: $videoStates, segment: segment, videoModel: $videoModel)
                                                }
                                            }
                                        }
                                        VStack (alignment: .trailing) {
                                            Rectangle().foregroundStyle(Color.white).overlay {
                                                HStack {
                                                    Spacer().frame(width: 20)
                                                    TextField("", text: Binding(get: {
                                                        //                                print(segment.wrappedValue)
                                                        //                                print(videoModel.segmentTexts)
                                                        return videoModel.segmentTexts[segment.wrappedValue] ?? ""
                                                    }, set: { newValue in
                                                        videoModel.segmentTexts[segment.wrappedValue] = newValue
                                                        videoModel.updateCombinedFromSegments()
                                                    }), axis: .vertical).font(.system(size: 14))
                                                    Spacer().frame(width: 20)
                                                }
                                            }.frame(height: 100 * 16/9)
                                            if !(videoStates[segment.wrappedValue] ?? []).contains(["background-free"]) {
                                                RoundedRectangle(cornerRadius: 10.0).foregroundStyle(AMBISSION_ORANGE).overlay {
                                                    Text("Remove background noise").bold().foregroundStyle(Color.white).fixedSize()
                                                }.background(RoundedRectangle(cornerRadius: 10.0).foregroundStyle(AMBISSION_ORANGE)).frame(height: 33).onTapGesture {
                                                    Task {
                                                        await removeBackground(forSegment: segment.wrappedValue)
                                                    }
                                                }.disabled(videoModel.segmentUrls[segment.wrappedValue] == nil)
                                            }
                                            
                                        }
                                        Spacer().frame(width: 10)
                                    }
                                    //                            Button(action: {
                                    //                                navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                    //                                    videoModel.segmentUrls[segment.wrappedValue]
                                    //                                }, set: { newUrl in
                                    //                                    videoStates[segment.wrappedValue] = ["exported"]
                                    //                                    videoModel.segmentUrls[segment.wrappedValue] = newUrl
                                    //                                    SegmentView.exportSegment(newUrl)
                                    //                                }), promptText: videoModel.segmentTexts[segment.wrappedValue] ?? ""))
                                    //                            }) {
                                    //                                Image(systemName: "arrow.triangle.2.circlepath").resizable()
                                    //                            }.frame(width: 30, height: 30).buttonStyle(PlainButtonStyle())
                                    Rectangle().frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1).foregroundStyle(AMBISSION_ORANGE)
                                }.offset(x: (segment.wrappedValue == offsetSegment ? offset : 0))

                            
                            Button {
                                videoModel.segments.remove(at: videoModel.segments.firstIndex(of: segment.wrappedValue)!)
                                offset = 0
                            } label: {
                                Rectangle().foregroundStyle(Color.red).overlay {
                                    Image(systemName: "trash").resizable().scaledToFit().foregroundStyle(Color.white).frame(width: 60).offset(x: -50.0)
                                }.frame(minWidth: 200, maxWidth: 200, maxHeight: .infinity)
                            }.offset(x: reader.size.width / 2 + 100.0 + (segment.wrappedValue == offsetSegment ? offset : 0))
                            }.gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        offsetSegment = segment.wrappedValue
                                        offset = gesture.translation.width
                                        if offset > 50 {
                                            offset = .zero
                                            offsetSegment = nil
                                        }
                                    }
                                    .onEnded { _ in
                                        if offset < -200 {
                                            videoModel.segments.remove(at: videoModel.segments.firstIndex(of: segment.wrappedValue)!)
                                            offset = 0
                                            offsetSegment = nil
                                        }
                                        else if offset < -20 {
                                            offset = -100
                                        } else {
                                            offset = 0
                                        }
                                    }
                            )
                        }
                        HStack (alignment: .top) {
                            Spacer().frame(width: 10)
                            RoundedRectangle(cornerRadius: 10.0).stroke(AMBISSION_ORANGE).foregroundStyle(Color.clear).overlay {
                                RoundedRectangle(cornerRadius: 10.0).overlay(
                                    Image(systemName: "plus").foregroundStyle(Color.white).frame(width: 40, height: 40)
                                ).foregroundStyle(AMBISSION_ORANGE).frame(width: 50, height: 50)
                            }.frame(maxWidth: .infinity, minHeight: 70, maxHeight: 70).onTapGesture {
                                let newSegmentId = (videoModel.segments.max() ?? "") + "1"
                                videoModel.segmentTexts[newSegmentId] = ""
                                videoStates[newSegmentId] = []
                                videoModel.segments.append(newSegmentId)
                            }
                            Spacer().frame(width: 10)
                        }
                    }.scrollDismissesKeyboard(.interactively)
                    HStack {
                        Spacer().frame(width: 10)
                        Toggle("", isOn: $addSubtitles).labelsHidden().tint(BUTTON_PURPLE)
                        Text("Subtitles").bold().foregroundStyle(BUTTON_PURPLE).fixedSize()
                        Spacer().frame(maxWidth: .infinity)
                        Button(action: {
                            Task {
                                let outputURL = try await combineVideo()
                                print("got output url")
                                await MainActor.run {
                                    print("add to nav path")
                                    processingFinal = false
                                    navPath.wrappedValue.append(PreviewView(navPath: navPath, outputUrl: outputURL))
                                }
                            }
                        }, label: {
                            Text("Combine segments").font(.system(size: 24)).foregroundStyle(Color.white).fixedSize()
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).foregroundStyle(AMBISSION_ORANGE)).disabled(videoModel.segmentUrls.count == 0)
                        Spacer().frame(width: 10)
                    }
                    Spacer().frame(height: 5)
                }.background(AMBISSION_BACKGROUND).navigationTitle($videoModel.videoTitle).navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: videoModel, navPath: navPath, currentScreen: SegmentView.self)})})
                .onChange(of: videoModel.segments) {
                    videoModel.segmentUrls = videoModel.segmentUrls.filter { (key: String, value: URL) in
                        if !videoModel.segments.contains(where: { iter in
                            iter == key
                        }) {
                            return false
                        }
                        return true
                    }
                    videoModel.segmentTexts = videoModel.segmentTexts.filter { (key: String, value: String) in
                        if !videoModel.segments.contains(where: { iter in
                            iter == key
                        }) {
                            return false
                        }
                        return true
                    }
                    videoModel.updateCombinedFromSegments()
                }
            }
        }
    }
    
    static func getCaptions(_ forUrl: URL, withText: String) async throws -> URL {
        let bucket = "video-resume-4fcd0.appspot.com"
        let storageRef = Storage.storage(url: "gs://" + bucket)
        let videoFilename = UUID().uuidString
        let videoRef = storageRef.reference(withPath: videoFilename)
        print(videoRef)
        do {
            let _ = try await videoRef.putFileAsync(from: forUrl)
        } catch {
            print("error uploading" + error.localizedDescription)
            throw UploadError()
        }
        let signedDownloadUrl = try await functions.httpsCallable("makeCaptions", requestAs: [String:String].self, responseAs: String.self).call(["blob": videoFilename, "text": withText])
        print(signedDownloadUrl)
        let (captionsFile, response) = try await URLSession.shared.download(for: URLRequest(url: URL(string: signedDownloadUrl)!))
        print(response)
        print(captionsFile)
        let finalFile = FileManager().temporaryDirectory.appending(component: UUID().uuidString + ".vtt")
        try FileManager().moveItem(at: captionsFile, to: finalFile)
        print(finalFile)
        return finalFile
    }
    
    func removeBackground(forSegment: String) async {
        var existingStates: [String] = []
        if videoStates[forSegment] != nil {
            existingStates = videoStates[forSegment]!
        }
        existingStates.append("processing")
        videoStates[forSegment] = existingStates
        let inputUrl = "dlb://" + UUID().uuidString + ".mov"
        print(inputUrl)
        do {
            let dolbyAuthorizer = DolbyAuthorizer()
            let signedUrlDict = try await Poster.postFor([String: String].self, requestURL: URL(string: "https://api.dolby.com/media/input")!, postContent: GetSignedUrlRequest(url: inputUrl), authorizer: dolbyAuthorizer)
            print(signedUrlDict)
            try await Poster.putFile(videoModel.segmentUrls[forSegment]!, destination: URL(string: signedUrlDict["url"]!)!)
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
            videoStates[forSegment] = ["background-free"]
            videoModel.segmentUrls[forSegment] = newPermanentDirectory
        } catch {
            print(error)
        }
    }
    

    
    static func fixPreferredTransform(_ toFix: CGAffineTransform, inputSize: CGSize, desiredSize: CGSize) -> CGAffineTransform {
        var preferredTransform = toFix
        print(preferredTransform)
        print(preferredTransform.decomposed())
        print(preferredTransform.decomposed().rotation == 0.0)

        if preferredTransform.decomposed().rotation > 0 {
//            preferredTransform.tx = desiredSize.width
        } else if preferredTransform.decomposed().rotation < 0 {
//            preferredTransform.ty = desiredSize.height
        } else {
            if inputSize.width != desiredSize.width || inputSize.height != desiredSize.height {
                preferredTransform =  preferredTransform.scaledBy(x: desiredSize.width / inputSize.width, y: desiredSize.height / inputSize.height)
            }
        }
        print(preferredTransform)
        print(preferredTransform.decomposed())

        return preferredTransform
    }
    
    func combineVideo() async throws -> URL {
        processingFinal = true
        print("starting combination")
        let finalMovie = AVMutableComposition()
        var currentTime = CMTime.zero
        let audioTrack = finalMovie.addMutableTrack(
            withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoTrack = finalMovie.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoRotationComposition = AVMutableVideoComposition()
        var durations: [String:CMTime] = [:]
        var compositionInstructions = [AVVideoCompositionInstruction]()
        
        for segment in videoModel.segments {
            let compositionInstruction = AVMutableVideoCompositionInstruction()
            print("combination segment" + segment)
            if videoModel.segmentUrls[segment] == nil {
                continue
            }
            print("combination segment" + segment)
            let segmentMovie = AVURLAsset(url: videoModel.segmentUrls[segment]!)
            let segmentDuration = try await segmentMovie.load(.duration)
            durations[segment] = segmentDuration
            try audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: segmentDuration), of: try await segmentMovie.loadTracks(withMediaType: .audio)[0], at: currentTime)
            let segmentVideoTrack = try await segmentMovie.loadTracks(withMediaType: .video)[0]
            
            
            try videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: segmentDuration), of: segmentVideoTrack, at: currentTime)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
            print("nat size")
            let preferredTransform = try await segmentVideoTrack.load(.preferredTransform)
            
            let modifiedTransform = SegmentView.fixPreferredTransform(preferredTransform, inputSize: segmentVideoTrack.naturalSize, desiredSize: CGSize(width: 1080, height: 1920))
            layerInstruction.setTransform(modifiedTransform, at: currentTime)
            


            compositionInstruction.timeRange = CMTimeRange(start: currentTime, duration: segmentDuration)
            currentTime = CMTimeAdd(currentTime, segmentDuration)
//            layerInstruction.setOpacity(0.0, at: currentTime)
            print(currentTime)
//            layerInstruction.setTransform(modifiedTransform.inverted(), at: currentTime)
            compositionInstruction.layerInstructions.append(layerInstruction)
            print("layer instructions")
            print(compositionInstruction.layerInstructions)
            compositionInstructions.append(compositionInstruction)
        }
        
        videoRotationComposition.instructions = compositionInstructions
        videoRotationComposition.renderSize = CGSize(width: 1080, height: 1920)
        videoRotationComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let exportSession = AVAssetExportSession(asset: finalMovie, presetName: AVAssetExportPresetMediumQuality)!
        exportSession.outputURL = FileManager().temporaryDirectory.appending(path: UUID().uuidString + ".mov")
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoRotationComposition
        print("exporting")
        await exportSession.export()
        
        
        let videoURL = exportSession.outputURL!
        print(videoURL)
        
        if !addSubtitles {
            return videoURL
        }
        
        let captionsUrl = try await SegmentView.getCaptions(videoURL, withText: videoModel.unifiedScript)
        print("loading captions")
        let captionsAsset = AVURLAsset(url: captionsUrl)
        print("loaded captions asset")
        let captionsInput = try await captionsAsset.loadTracks(withMediaType: .text).first
        if captionsInput == nil {
            print("no captions input!")
            return exportSession.outputURL!
        }
        print(captionsInput?.mediaType)
        print("captions loaded")

        let asset = AVURLAsset(url: videoURL)
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

        let captionsTrack = composition.addMutableTrack(
            withMediaType: .text, preferredTrackID: kCMPersistentTrackID_Invalid)
        try await captionsTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: captionsAsset.load(.duration)), of: captionsInput!, at: .zero)
        try await print(asset.load(.duration))
        try await print(captionsAsset.load(.duration))
        
        var currentTime2 = CMTime.zero

        let videoRotationComposition2 = AVMutableVideoComposition()
        let compositionInstruction2 = AVMutableVideoCompositionInstruction()
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        print("nat size")
        var preferredTransform = try await assetTrack.load(.preferredTransform)
        print(preferredTransform)
        print(preferredTransform.decomposed())
        layerInstruction.setTransform(preferredTransform, at: currentTime)
        compositionInstruction2.layerInstructions.append(layerInstruction)
        print("layer instructions")
        print(compositionInstruction2.layerInstructions)
        for segment in videoModel.segments {
            print("combination segment" + segment)
            if videoModel.segmentUrls[segment] == nil {
                continue
            }
            print("combination segment" + segment)



            
            currentTime2 = CMTimeAdd(currentTime, durations[segment]!)
//            layerInstruction.setOpacity(0.0, at: currentTime)
            print(currentTime2)

        }
        compositionInstruction2.timeRange = compositionTrack.timeRange
        videoRotationComposition2.instructions = [compositionInstruction2]
        videoRotationComposition2.renderSize = CGSize(width: 1080, height: 1920)
        videoRotationComposition2.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let exportSession2 = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        print("composition tracks")
        print(composition.tracks)
        print(composition.tracks.count)
        exportSession2.outputURL = FileManager().temporaryDirectory.appending(path: UUID().uuidString + ".mp4")
        exportSession2.outputFileType = .mp4
        exportSession2.videoComposition = videoRotationComposition2
        print("exporting")
        await exportSession2.export()
        
        
        let finalAsset = AVURLAsset(url: exportSession2.outputURL!)
        print("final track count")
        print(finalAsset.tracks)
        print(finalAsset.tracks.count)
        


        
        print("done exporting")
        print("added to phot library")
        return exportSession2.outputURL!
    }
}



//#Preview {
//    var navPath = NavigationPath()
//    return SegmentView(navPath: Binding(get: {
//        navPath
//    }, set: { newNavPath in
//        navPath = newNavPath
//    }), segmentText: ["1": "intro", "2": "job 1", "3": "job 2", "4": "job3", "5": "call to action"])
//}



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
                let baseDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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

struct AddVideoView: View {
    @State var videoStates: Binding<[String:[String]]>
    @State var segment: Binding<String>
    @State var videoModel: Binding<CreatedVideo>
    @State var localVideoModel: VideoModel
    
    init(videoStates: Binding<[String : [String]]>, segment: Binding<String>, videoModel: Binding<CreatedVideo>) {
        self.videoStates = videoStates
        self.segment = segment
        self.videoModel = videoModel
        self.localVideoModel = VideoModel(videoUrls: videoModel.segmentUrls, updateKey: segment.wrappedValue)
    }
    
    
    var body: some View {
        PhotosPicker(selection: Binding(get: {
            return localVideoModel.newRecipeVideo
        }, set: { newPick in
            videoStates.wrappedValue[segment.wrappedValue] = []
            localVideoModel.newRecipeVideo = newPick
        }), matching: .videos, photoLibrary: .shared()) {
            RoundedRectangle(cornerRadius: 10.0).foregroundStyle(AMBISSION_ORANGE).overlay {
                Text("Upload").bold().foregroundStyle(Color.white)
            }
        }.frame(width: 100, height: 33)
    }
}

class UploadError: Error {
    
}
