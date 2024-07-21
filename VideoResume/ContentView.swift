//
//  ContentView.swift
//  VideoResume
//
//  Created by Nathan Merz on 6/26/24.
//

import SwiftUI
import FirebaseFunctions
import PDFKit
import SwiftData

@Model
class InputContent {
    var file = ""
    var resume = ""
    
    init() {
        
    }
}

@Model
class CreatedVideo {
    var videoTitle: String
    var unifiedScript: String
    var segments: [String]
    var segmentUrls: [String: URL]
    var segmentTexts: [String: String]
    
    init(videoTitle:String = "Untitled Video", unifiedScript: String = "", segments: [String] = [], segmentUrls: [String: URL] = [:], segmentTexts: [String: String] = [:]) {
        self.videoTitle = videoTitle
        self.unifiedScript = unifiedScript
        self.segments = segments
        self.segmentUrls = segmentUrls
        self.segmentTexts = segmentTexts
    }
}

var functions = Functions.functions()
let localMode = false

struct ContentView: View {
    
    @Environment(\.modelContext) var modelContext

    @State var navPath = NavigationPath()
    @State var presentFileSelection = false
    @State var manualEntry = false
    @State var inputContent: InputContent? = nil
    @Query let pastVideos: [CreatedVideo]
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack {
                Button(action: {
                    presentFileSelection = true
                }, label: {
                    Text("Upload a pdf resume").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                }).fileImporter(isPresented: $presentFileSelection, allowedContentTypes: [.pdf]) { chosenResult in
                    do {
                        let chosenUrl = try chosenResult.get()
                        if !chosenUrl.startAccessingSecurityScopedResource() {
                            return
                        }
                        inputContent!.resume = PDFDocument(url: chosenUrl)!.string!
                        chosenUrl.stopAccessingSecurityScopedResource()
                        inputContent!.file = chosenUrl.lastPathComponent
                    } catch {
                        print(error)
                        return
                    }
                }.padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                if inputContent?.file != nil && inputContent?.file != "" {
                    Text(inputContent!.file)
                }
                
                
                Button(action: {
                    manualEntry = true
                }, label: {
                    Text("Or type it in yourself").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                if manualEntry == true {
                    TextField("Paste your resume here", text: Binding(get: {
                        inputContent?.resume ?? ""
                    }, set: { newValue in
                        inputContent?.resume = newValue
                    }),  axis: .vertical).frame(maxWidth:.infinity, maxHeight: .infinity)
                }
                if inputContent?.resume != nil && inputContent?.resume != "" {
                    Button(action: {
                        let newVideo = CreatedVideo()
                        modelContext.insert(newVideo)
                        navPath.append(ScriptGenerationView(navPath: $navPath, resume: inputContent!.resume, videoModel: newVideo))
                    }, label: {
                        Text("Proceed to script studio").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                    }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                }
                if pastVideos.count > 0 {
                    Text("Or, continue a past video:")
                    ForEach(pastVideos) { pastVideo in
                        Button(action: {
                            navPath.append(ScriptGenerationView(navPath: $navPath, resume: inputContent!.resume, videoModel: pastVideo))
                        }, label: {
                            Text(pastVideo.videoTitle).font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    }
                }
            }.navigationDestination(for: SegmentView.self) { newView in
                newView
            }.navigationDestination(for: ScriptGenerationView.self) { newView in
                newView
            }.onAppear {
                var storedInputs = try! modelContext.fetch(FetchDescriptor<InputContent>()).first
                if storedInputs == nil {
                    storedInputs = InputContent()
                    modelContext.insert(storedInputs!)
                }
                inputContent = storedInputs
            }
        }.onOpenURL { callingUrl in
            let queryItems = URLComponents(url: callingUrl, resolvingAgainstBaseURL: true)?.queryItems
            if queryItems == nil {
                return
            }
            for queryItem in queryItems! {
                if queryItem.name == "script"{
                    let inputScript = queryItem.value ?? ""
                    let newVideo = CreatedVideo(unifiedScript: inputScript, segmentTexts: ScriptGenerationView.getScriptSegments(script: inputScript))
                    navPath.append(SegmentView(navPath: $navPath, videoModel: newVideo))

                }
            }
        }
    }
}



#Preview {
    ContentView()
}
