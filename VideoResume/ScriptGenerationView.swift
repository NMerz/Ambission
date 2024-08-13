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

struct RecruiterScriptRequest: Codable {
    let tone: String
    let resume: String
    let jobDescription: String
}

struct ExtractJobDescriptionRequest: Codable {
    let jobUrl: String
    let uselessAuth: String
}

struct ScriptGenerationView: View, Hashable {
    static func == (lhs: ScriptGenerationView, rhs: ScriptGenerationView) -> Bool {
        lhs.videoModel?.unifiedScript == rhs.videoModel?.unifiedScript && lhs.tone == rhs.tone
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(videoModel?.unifiedScript)
        hasher.combine(tone)
    }
    @Environment(\.modelContext) var modelContext

    @State var tone = "professional"
    @State var scriptProposal: String
    @State var navPath: Binding<NavigationPath>
    
    @State var manualEntry = false
    @State var errorDisplay = ""
    
    let potentialTones = ["fun", "professional", "technical"]
    
    @State var processingState = ""
    
    @State var videoModel: CreatedVideo?
    
    init(navPath: Binding<NavigationPath>, videoModel: CreatedVideo?) {
        self.navPath = navPath
        self.videoModel = videoModel
        scriptProposal = videoModel?.unifiedScript ?? ""
        if localMode {
            functions.useEmulator(withHost: "http://127.0.0.1", port: 5001)
        }
        print(videoModel)
    }
    
    func getNewScript() async throws {
        let storedInputs = try! modelContext.fetch(FetchDescriptor<InputContent>()).first
        let resume = storedInputs?.resume
        if resume == nil {
            scriptProposal = "Please upload a resume first. You can do so under the Me tab."
            return
        }
        if videoModel?.nominalType == "recruiter" {
            if videoModel?.typeSpecificInput["listingText"] == nil || videoModel?.typeSpecificInput["listingText"] == "" {
                scriptProposal = "Please input the url or contents of the targeted job listing at the top of this screen and wait for it to finish processing."
                return
            }
            scriptProposal = try await functions.httpsCallable("makeRecruiterScript", requestAs: RecruiterScriptRequest.self, responseAs: String.self).call(RecruiterScriptRequest(tone: tone, resume: resume!, jobDescription: videoModel!.typeSpecificInput["listingText"]!))
        } else if videoModel?.nominalType == "general" {

            scriptProposal = try await functions.httpsCallable("makeScript", requestAs: ScriptRequest.self, responseAs: String.self).call(ScriptRequest(tone: tone, resume: resume!))
        } else {
            scriptProposal = "Sorry, an error occurred. We'd appreciate a bug report so we can fix it."
        }
    }
    
    var body: some View {
        GeometryReader { reader in
            ScrollView {
                VStack {
                    if videoModel?.nominalType == "recruiter" {
                        TextField("Enter LinkedIn job listing URL", text: Binding(get: {
                            return videoModel!.typeSpecificInput["listingUrl"] ?? ""
                        }, set: { newValue in
                            if newValue == videoModel!.typeSpecificInput["listingUrl"] {
                                return
                            }
                            errorDisplay = ""
                            videoModel!.typeSpecificInput["listingUrl"] = newValue
                            let proposedUrl = URL(string: newValue)
                            if proposedUrl == nil {
                                if newValue != "" {
                                    errorDisplay = "URL not valid"
                                }
                                return
                            }
                            processingState = "processing"
                            Task {
                                print(newValue)
                                do {
                                    videoModel!.typeSpecificInput["listingText"] = try await functions.httpsCallable("extractJobDescription", requestAs: ExtractJobDescriptionRequest.self, responseAs: String.self).call(ExtractJobDescriptionRequest(jobUrl: newValue, uselessAuth: "FDKNE@!IORjr3kl23i23"))
                                    processingState = "Processing complete. Job description ready for use"
                                    print(videoModel!.typeSpecificInput["listingText"] ?? "")
                                    errorDisplay = ""
                                } catch {
                                    print(error)
                                    errorDisplay = "Unable to load URL. Make sure it is valid. If the error persists, report a bug -- include the URL please."
                                }
                            }
                        }))
                        Text(processingState)
                        if errorDisplay != "" {
                            Text(errorDisplay).foregroundStyle(.red)
                        }
                        
                        Button(action: {
                            manualEntry = !manualEntry
                        }, label: {
                            Text("Or paste in the job description").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                        if manualEntry == true {
                            TextField("Paste the job desciption here", text: Binding(get: {
                                videoModel!.typeSpecificInput["listingText"] ?? ""
                            }, set: { newValue in
                                videoModel!.typeSpecificInput["listingText"] = newValue
                            }),  axis: .vertical).frame(maxWidth:.infinity, maxHeight: .infinity)
                        }
                    }
                    
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
                        if scriptProposal == "" {
                            ProgressView()
                        } else {
                            TextField((videoModel?.unifiedScript == "" ? "Generating... This may take up to 30 seconds" : "Use refresh to generate a new script"), text: $scriptProposal,  axis: .vertical).frame(maxWidth:.infinity, minHeight: reader.size.height * 0.3, maxHeight: reader.size.height * 0.4)
                        }
                        Button(action: {
                            Task {
                                scriptProposal = ""
                                try await getNewScript()
                            }
                        }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        })
                        Spacer().frame(width: 20)
                    }.onAppear {
                        Task {
                            if videoModel?.unifiedScript == "" {
                                try await getNewScript()
                            }
                        }
                    }
                    Button(action: {
                        if videoModel?.unifiedScript == "" && videoModel!.segments.isEmpty {
                            (videoModel!.segments, videoModel!.segmentTexts) = ScriptGenerationView.getScriptSegments(script: videoModel!.unifiedScript)
                        }
                        videoModel?.unifiedScript = scriptProposal
                    }, label: {
                        Text("Save proposed script").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                    }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    HStack {
                        Spacer().frame(width: 20)
                        TextField("Final script goes here", text: Binding(get: {
                            videoModel?.unifiedScript ?? ""
                        }, set: { newValue in
                            videoModel?.unifiedScript = newValue
                        }),  axis: .vertical).frame(maxWidth:.infinity, minHeight: reader.size.height * 0.3, maxHeight: reader.size.height * 0.4)
                        Spacer().frame(width: 20)
                    }
                    if videoModel?.unifiedScript != "" {
                        Button(action: {
                            (videoModel!.segments, videoModel!.segmentTexts) = ScriptGenerationView.getScriptSegments(script: videoModel!.unifiedScript)
                            videoModel!.segmentUrls = [:]
                            navPath.wrappedValue.append(SegmentView(navPath: navPath, videoModel: videoModel!))
                        }, label: {
                            if videoModel != nil && videoModel!.segments.isEmpty {
                                Text("Load script into Video Studio").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
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
            }.onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            }
        }.navigationTitle(Binding<String>(get: {
            return videoModel?.videoTitle ?? ""
        }, set: { newValue in
            if videoModel != nil {
                videoModel!.videoTitle = newValue
            }
        })).toolbar(content: {ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: videoModel, navPath: navPath, currentScreen: ScriptGenerationView.self)})})
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
