//
//  ContentView.swift
//  VideoResume
//
//  Created by Nathan Merz on 6/26/24.
//

import SwiftUI
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
    var nominalType: String  = "general"
    var typeSpecificInput: [String: String] = [:]
    
    
    init(videoTitle:String = "Untitled Video", unifiedScript: String = "", segments: [String] = [], segmentUrls: [String: URL] = [:], segmentTexts: [String: String] = [:], nominalType: String) {
        self.videoTitle = videoTitle
        self.unifiedScript = unifiedScript
        self.segments = segments
        self.segmentUrls = segmentUrls
        self.segmentTexts = segmentTexts
        self.nominalType = nominalType
    }
    
    func updateCombinedFromSegments() {
        var newCombined = ""
        var first = true
        for segment in segments {
            if first {
                first = false
            } else {
                newCombined += "\n"
            }
            newCombined += segmentTexts[segment] ?? ""
        }
        unifiedScript = newCombined
    }
}

let AMBISSION_BACKGROUND = Color(red: 0.996078431372549, green: 0.9529411764705882, blue: 0.9176470588235294)

struct NavigableText: View, Hashable {
    static func == (lhs: NavigableText, rhs: NavigableText) -> Bool {
        lhs.contents == rhs.contents
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(contents)
    }
     
    
    init(_ contents: String, toolbarContent: AnyView) {
        self.contents = contents
        self.toolbarContent = toolbarContent
    }
    
    let contents: String
    let toolbarContent: AnyView
    
    var body: some View {
        Text(contents).toolbar(content: {ToolbarItem(placement: .bottomBar, content: {toolbarContent})}).frame(maxWidth: .infinity, maxHeight: .infinity).background(AMBISSION_BACKGROUND)
    }
}

struct ContentView: View {
    

    @Query var inputContent: [InputContent]
    @State var advance = false
    @Environment(\.modelContext) var modelContext
    @State var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            
            VStack {
                if advance {
                    HomeView(navPath: $navPath)
                } else {
                    ResumeEntryView(referrerCreatedVideo: nil, navPath: $navPath).toolbar(content: {
                        if advance {
                            ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: nil, navPath: $navPath, currentScreen: HomeView.self)})
                        }
                    }).toolbarBackground(AMBISSION_BACKGROUND, for: .bottomBar)
                    if inputContent.count > 0 && inputContent.first?.resume != nil && inputContent.first?.resume != "" {
                        Button(action: {
                            navPath.append(HomeView(navPath: $navPath))
                        }, label: {
                            Text("Start creating").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    }
                }
            }.navigationDestination(for: SegmentView.self) { newView in
                newView
            }.navigationDestination(for: ScriptGenerationView.self) { newView in
                newView
            }.navigationDestination(for: RecordView.self) { newView in
                newView
            }.navigationDestination(for: EditClipView.self) { newView in
                newView
            }.navigationDestination(for: PreviewView.self) { newView in
                newView
            }.navigationDestination(for: HomeView.self) { newView in
                newView
            }.navigationDestination(for: ResumeEntryView.self) { newView in
                newView
            }.navigationDestination(for: NavigableText.self) { newView in
                newView
            }.onAppear {
                if inputContent.count > 0 && inputContent.first?.resume != nil && inputContent.first?.resume != "" {
                    advance = true
                }
            }
        }.tint(AMBISSION_ORANGE).background(AMBISSION_BACKGROUND)
        .onOpenURL { callingUrl in
            let queryItems = URLComponents(url: callingUrl, resolvingAgainstBaseURL: true)?.queryItems
            if queryItems == nil {
                return
            }
            var scriptType = "general"
            for queryItem in queryItems! {
                if queryItem.name == "scripttype" {
                    scriptType = queryItem.value ?? "general"
                    
                }
            }
            for queryItem in queryItems! {
                if queryItem.name == "script" {
                    let inputScript = queryItem.value ?? ""
                    let (segments, texts) = ScriptGenerationView.getScriptSegments(script: inputScript)
                    let newVideo = CreatedVideo(unifiedScript: inputScript, segments: segments, segmentTexts: texts, nominalType: scriptType)
                    navPath.append(SegmentView(navPath: $navPath, videoModel: newVideo))
                    
                }
            }
        }
    }
}



#Preview {
    ContentView()
}
