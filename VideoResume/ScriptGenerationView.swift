//
//  ScriptGenerationView.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/2/24.
//

import Foundation
import SwiftUI
import SwiftData

struct ScriptRequest: Codable {
    let tone: String
    let resume: String
}

struct ScriptGenerationView: View, Hashable {
    static func == (lhs: ScriptGenerationView, rhs: ScriptGenerationView) -> Bool {
        lhs.videoModel.unifiedScript == rhs.videoModel.unifiedScript && lhs.tone == rhs.tone && lhs.resume == rhs.resume
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(videoModel.unifiedScript)
        hasher.combine(resume)
    }
    @Environment(\.modelContext) var modelContext

    @State var tone = "professional"
    @State var scriptProposal = ""
    @State var resume: String = ""
    @State var navPath: Binding<NavigationPath>
    
    let potentialTones = ["fun", "professional", "technical"]
    
    @State var videoModel: CreatedVideo
    
    init(navPath: Binding<NavigationPath>, videoModel: CreatedVideo) {
        self.navPath = navPath
        self.videoModel = videoModel
        if localMode {
            functions.useEmulator(withHost: "http://127.0.0.1", port: 5001)
        }
    }
    
    var body: some View {
        GeometryReader { reader in
            ScrollView {
                VStack {
                    Picker(selection: $tone, label: Text("Data")) {
                        ForEach(potentialTones, id: \.self) { iterTone in
                            Text(iterTone)
                        }
                    }.pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(maxHeight: 100)
                        .clipped()
                    HStack {
                        Spacer().frame(width: 20)
                        TextField((videoModel.unifiedScript == "" ? "Generating... This may take up to 30 seconds" : "Use refresh to generate a new script"), text: $scriptProposal,  axis: .vertical).frame(maxWidth:.infinity, minHeight: reader.size.height * 0.3, maxHeight: reader.size.height * 0.4).onAppear {
                            let storedInputs = try! modelContext.fetch(FetchDescriptor<InputContent>()).first
                            resume = storedInputs?.resume ?? ""
                            Task {
                                if videoModel.unifiedScript == "" {
                                    scriptProposal = try await functions.httpsCallable("makeScript", requestAs: ScriptRequest.self, responseAs: String.self).call(ScriptRequest(tone: tone, resume: resume))
                                }
                            }
                        }
                        Button(action: {
                            Task {
                                scriptProposal = ""
                                scriptProposal = try await functions.httpsCallable("makeScript", requestAs: ScriptRequest.self, responseAs: String.self).call(ScriptRequest(tone: tone, resume: resume))
                            }
                        }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        })
                        Spacer().frame(width: 20)
                    }
                    Button(action: {
                        videoModel.unifiedScript = scriptProposal
                    }, label: {
                        Text("Save proposed script").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                    }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    HStack {
                        Spacer().frame(width: 20)
                        TextField("Final script goes here", text: $videoModel.unifiedScript,  axis: .vertical).frame(maxWidth:.infinity, minHeight: reader.size.height * 0.3, maxHeight: reader.size.height * 0.4)
                        Spacer().frame(width: 20)
                    }
                    if videoModel.unifiedScript != "" {
                        Button(action: {
                            (videoModel.segments, videoModel.segmentTexts) = ScriptGenerationView.getScriptSegments(script: videoModel.unifiedScript)
                            videoModel.segmentUrls = [:]
                            navPath.wrappedValue.append(SegmentView(navPath: navPath, videoModel: videoModel))
                        }, label: {
                            if videoModel.segments.isEmpty {
                                Text("Proceed to video studio").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                            } else {
                                Text("Replace progress with new script").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                            }
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
//                        Button(action: {
//                            UIPasteboard.general.string = "https://ambission.app?script=" + videoModel.script.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//                        }, label: {
//                            Text("Copy a shareable link").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
//                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    }
                }
            }
        }.navigationTitle($videoModel.videoTitle).toolbar(content: {ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: videoModel, navPath: navPath, currentScreen: ScriptGenerationView.self)})})
    }
    
    static func getScriptSegments(script: String) -> ([String], [String: String]) {
        let scriptSentences = script.split(separator: "\n")
        var orderableMapping: [String: String] = [:]
        var ordering: [String] = []
        for scriptSentence in scriptSentences {
            let newId = UUID().uuidString
            ordering.append(newId)
            orderableMapping[newId] = String(scriptSentence)
        }
        return (ordering, orderableMapping)
    }
}
