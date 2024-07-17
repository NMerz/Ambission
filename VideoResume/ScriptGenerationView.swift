//
//  ScriptGenerationView.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/2/24.
//

import Foundation
import SwiftUI

struct ScriptRequest: Codable {
    let tone: String
    let resume: String
}

struct ScriptGenerationView: View, Hashable {
    static func == (lhs: ScriptGenerationView, rhs: ScriptGenerationView) -> Bool {
        lhs.script == rhs.script && lhs.tone == rhs.tone && lhs.resume == rhs.resume
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(script)
        hasher.combine(resume)
    }
    
    @State var tone = "fun"
    @State var scriptProposal = ""
    @State var script = ""
    let resume: String
    @State var navPath: Binding<NavigationPath>
    
    let potentialTones = ["fun", "professional"]
    
    init(navPath: Binding<NavigationPath>, resume: String) {
        self.navPath = navPath
        self.resume = resume
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
                        TextField("Generating... This may take up to 30 seconds", text: $scriptProposal,  axis: .vertical).frame(maxWidth:.infinity, minHeight: reader.size.height * 0.3, maxHeight: reader.size.height * 0.4).onAppear {
                            Task {
                                scriptProposal = try await functions.httpsCallable("makeScript", requestAs: ScriptRequest.self, responseAs: String.self).call(ScriptRequest(tone: tone, resume: resume))
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
                        script = scriptProposal
                    }, label: {
                        Text("Save proposed script").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                    }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    HStack {
                        Spacer().frame(width: 20)
                        TextField("Final script goes here", text: $script,  axis: .vertical).frame(maxWidth:.infinity, minHeight: reader.size.height * 0.3, maxHeight: reader.size.height * 0.4)
                        Spacer().frame(width: 20)
                    }
                    if script != "" {
                        Button(action: {
                            navPath.wrappedValue.append(SegmentView(navPath: navPath, segmentText: ScriptGenerationView.getScriptSegments(script: script)))
                        }, label: {
                            Text("Proceed to video studio").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                        Button(action: {
                            UIPasteboard.general.string = "https://ambission.app?script=" + script.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                        }, label: {
                            Text("Copy a shareable link").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                        }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                    }
                }
            }
        }
    }
    
    static func getScriptSegments(script: String) -> [String: String] {
        let scriptSentences = script.split(separator: "\n")
        var counter = 0
        var orderableMapping: [String: String] = [:]
        for scriptSentence in scriptSentences {
            counter += 1
            orderableMapping[String(counter)] = String(scriptSentence)
        }
        return orderableMapping
    }
}
