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
                    List($videoModel.segments, id: \.self, editActions: .all) { segment in
                        VStack {
                            TextField("", text: Binding(get: {
//                                print(segment.wrappedValue)
//                                print(videoModel.segmentTexts)
                                return videoModel.segmentTexts[segment.wrappedValue] ?? ""
                            }, set: { newValue in
                                videoModel.segmentTexts[segment.wrappedValue] = newValue
                                videoModel.updateCombinedFromSegments()
                            }), axis: .vertical)
                            if (videoStates[segment.wrappedValue] ?? []).contains(["processing"]) {
                                ProgressView()
                            } else {
                                if videoModel.segmentUrls[segment.wrappedValue] == nil {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 5).strokeBorder(style: .init(lineWidth: 1, dash: [12, 12])).frame(height: 60).overlay {
                                            Button("record section") {
                                                try! AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .defaultToSpeaker)
                                                navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                                    videoModel.segmentUrls[segment.wrappedValue]
                                                }, set: { newUrl in
                                                    videoStates[segment.wrappedValue] = ["exported"]
                                                    videoModel.segmentUrls[segment.wrappedValue] = newUrl
                                                    SegmentView.exportSegment(newUrl)
                                                }), promptText: videoModel.segmentTexts[segment.wrappedValue] ?? ""))
                                            }.buttonStyle(PlainButtonStyle())
                                            
                                        }
                                        AddVideoView(videoStates: $videoStates, segment: segment, videoModel: $videoModel)
                                    }
                                } else {
                                    HStack {
                                        Spacer().frame(width: 10)
                                        Button(action: {
                                            navPath.wrappedValue.append(EditClipView(navPath: navPath, outputUrl: Binding(get: {
                                                videoModel.segmentUrls[segment.wrappedValue]!
                                            }, set: { newUrl in
                                                videoStates[segment.wrappedValue] = []
                                                videoModel.segmentUrls[segment.wrappedValue] = newUrl
                                            })))
                                        }) {
                                            Image(systemName: "scissors").resizable()
                                        }.frame(width: 30, height: 30).buttonStyle(PlainButtonStyle())
                                        Spacer().frame(width: 10)
                                        VideoPlayer(player: AVPlayer(url: videoModel.segmentUrls[segment.wrappedValue]!)).frame(width: 200, height: 200 * 16/9).ignoresSafeArea(.all).id(videoModel.segmentUrls[segment.wrappedValue])
                                        AddVideoView(videoStates: $videoStates, segment: segment, videoModel: $videoModel)
                                        Button(action: {
                                            navPath.wrappedValue.append(RecordView(navPath: navPath, outputUrl: Binding(get: {
                                                videoModel.segmentUrls[segment.wrappedValue]
                                            }, set: { newUrl in
                                                videoStates[segment.wrappedValue] = ["exported"]
                                                videoModel.segmentUrls[segment.wrappedValue] = newUrl
                                                SegmentView.exportSegment(newUrl)
                                            }), promptText: videoModel.segmentTexts[segment.wrappedValue] ?? ""))
                                        }) {
                                            Image(systemName: "arrow.triangle.2.circlepath").resizable()
                                        }.frame(width: 30, height: 30).buttonStyle(PlainButtonStyle())
                                        Spacer().frame(width: 10)
                                    }
                                }
                                //                    Text(String(describing: segmentUrls[segment]))
                                if videoModel.segmentUrls[segment.wrappedValue] != nil {
                                    Button(action: {
                                        SegmentView.exportSegment(videoModel.segmentUrls[segment.wrappedValue])
                                        videoStates[segment.wrappedValue]?.append("exported")
                                    }, label: {
                                        if (videoStates[segment.wrappedValue] ?? []).contains(["exported"]) {
                                            Text("Export again").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                                        } else {
                                            Text("Export").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                                        }
                                    }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label))).buttonStyle(PlainButtonStyle())
                                    if !(videoStates[segment.wrappedValue] ?? []).contains(["background-free"]) {
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
                                                    try await Poster.putFile(videoModel.segmentUrls[segment.wrappedValue]!, destination: URL(string: signedUrlDict["url"]!)!)
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
                                                    videoModel.segmentUrls[segment.wrappedValue] = newPermanentDirectory
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
                    if videoModel.segmentUrls.count > 0 {
                        HStack {
                            Text("Subtitle")
                            Toggle("", isOn: $addSubtitles).labelsHidden()
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
                                Text("Combine segments").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                            }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                        }
                    }
                }.navigationTitle($videoModel.videoTitle).toolbar {
                    Button {
                        let newSegmentId = (videoModel.segments.max() ?? "") + "1"
                        videoModel.segmentTexts[newSegmentId] = ""
                        videoStates[newSegmentId] = []
                        videoModel.segments.append(newSegmentId)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                .toolbar(content: {ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: videoModel, navPath: navPath, currentScreen: SegmentView.self)})})
                .onChange(of: videoModel.segments) {
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
        let compositionInstruction = AVMutableVideoCompositionInstruction()
        var durations: [String:CMTime] = [:]

        for segment in videoModel.segments {
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
            var preferredTransform = try await segmentVideoTrack.load(.preferredTransform)
            print(preferredTransform)
            print(preferredTransform.decomposed())
            if preferredTransform.decomposed().rotation > 0 {
                preferredTransform.tx = 1080
            } else if preferredTransform.decomposed().rotation < 0 {
                preferredTransform.tx = -1080
            } else {
                if videoTrack!.naturalSize.width < 1080.0 || videoTrack!.naturalSize.height < 1920.0 {
                    preferredTransform =  preferredTransform.scaledBy(x: 1080.0 / videoTrack!.naturalSize.width, y: 1920.0 / videoTrack!.naturalSize.height)
                }
            }
            layerInstruction.setTransform(preferredTransform, at: currentTime)

            
            currentTime = CMTimeAdd(currentTime, segmentDuration)
//            layerInstruction.setOpacity(0.0, at: currentTime)
            print(currentTime)
            compositionInstruction.layerInstructions.append(layerInstruction)
            print("layer instructions")
            print(compositionInstruction.layerInstructions)
        }
        compositionInstruction.timeRange = videoTrack!.timeRange
        videoRotationComposition.instructions = [compositionInstruction]
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

                let mergedLayer = CALayer()
                mergedLayer.frame = CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920))
        let backgroundLayer = CALayer()
        backgroundLayer.frame = CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920))
                let subtitleLayers = CALayer()
                let videoLayer = CALayer()
                videoLayer.frame = CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920))
        mergedLayer.addSublayer(backgroundLayer)
                mergedLayer.addSublayer(videoLayer)
                mergedLayer.addSublayer(subtitleLayers)
                subtitleLayers.frame = CGRect(x: 0, y: 0, width: 1080, height: 1920)
//        videoRotationComposition2.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: mergedLayer)
        
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
        
        
        
        
//        let asset = AVURLAsset(url: exportSession.outputURL!)
//        let composition = AVMutableComposition()
//        let timeRange = CMTimeRange(start: .zero, duration: try await asset.load(.duration))
//        let compositionTrack = composition.addMutableTrack(
//            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        let assetTrack =  try await asset.loadTracks(withMediaType: .video).first
//        try compositionTrack!.insertTimeRange(timeRange, of: assetTrack!, at: .zero)
//        let audioAssetTrack = try await asset.loadTracks(withMediaType: .audio).first
//        let compositionAudioTrack = composition.addMutableTrack(
//            withMediaType: .audio,
//            preferredTrackID: kCMPersistentTrackID_Invalid)
//        try compositionAudioTrack!.insertTimeRange(
//            timeRange,
//            of: audioAssetTrack!,
//            at: .zero)
//        
//        let mergedLayer = CALayer()
//        mergedLayer.frame = CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920))
//        let subtitleLayers = CALayer()
//        let videoLayer = CALayer()
//        videoLayer.frame = CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920))
//        mergedLayer.addSublayer(videoLayer)
//        mergedLayer.addSublayer(subtitleLayers)
//        subtitleLayers.frame = CGRect(x: 0, y: 0, width: 1080, height: 1920)
//        for segment in videoModel.segments {
//            let captionAnimation = CABasicAnimation(keyPath: "opacity")
//            captionAnimation.isRemovedOnCompletion = true
//            captionAnimation.beginTime = .zero
//            print("begin time")
//            print(currentTime.seconds)
//            captionAnimation.duration = durations[segment]!.seconds
//            captionAnimation.fromValue = 1
//            captionAnimation.toValue = 1
//            let subtitleLayer = CATextLayer()
//            subtitleLayer.foregroundColor = CGColor(gray: 1, alpha: 1.0)
//            subtitleLayer.fontSize = 128
//            subtitleLayer.frame = CGRect(x: 0, y: -1920.0 / 2, width: 1080.0, height: 1920.0)
//            subtitleLayer.alignmentMode = .center
//            subtitleLayer.add(captionAnimation, forKey: "opacity")
//            subtitleLayer.string = videoModel.segmentTexts[segment] ?? ""
//            subtitleLayer.displayIfNeeded()
//            subtitleLayer.opacity = 0
//            print(subtitleLayer)
//            subtitleLayers.addSublayer(subtitleLayer)
//        }
//        
//        let videoComposition = AVMutableVideoComposition()
//        videoComposition.renderSize = CGSize(width: 1080, height: 1920)
//        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
//          postProcessingAsVideoLayer: videoLayer,
//          in: mergedLayer)
//        
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.timeRange = CMTimeRange(
//          start: .zero,
//          duration: composition.duration)
//        videoComposition.instructions = [instruction]
//        let layerInstruction = compositionLayerInstruction(
//          for: compositionTrack,
//          assetTrack: assetTrack)
//        instruction.layerInstructions = [layerInstruction]

        
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
        Spacer().frame(width: 10)
        PhotosPicker(selection: Binding(get: {
            return localVideoModel.newRecipeVideo
        }, set: { newPick in
            videoStates.wrappedValue[segment.wrappedValue] = []
            localVideoModel.newRecipeVideo = newPick
        }), matching: .videos, photoLibrary: .shared()) {
            Image(systemName: "square.and.arrow.down").resizable().scaledToFit()
        }.frame(width: 30, height: 30)
        Spacer().frame(width: 10)
    }
}

class UploadError: Error {
    
}
