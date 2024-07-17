//
//  ContentView.swift
//  VideoResume
//
//  Created by Nathan Merz on 6/26/24.
//

import SwiftUI
import FirebaseFunctions
import PDFKit

var functions = Functions.functions()
let localMode = false

struct ContentView: View {
    @State var navPath = NavigationPath()
    @State var resume = ""
    @State var presentFileSelection = false
    @State var manualEntry = false
    @State var file = ""
    
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
                        resume = PDFDocument(url: chosenUrl)!.string!
                        chosenUrl.stopAccessingSecurityScopedResource()
                        file = chosenUrl.lastPathComponent
                    } catch {
                        print(error)
                        return
                    }
                }.padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                if file != "" {
                    Text(file)
                }
                
                
                Button(action: {
                    manualEntry = true
                }, label: {
                    Text("Or type it in yourself").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                if manualEntry == true {
                    TextField("Paste your resume here", text: $resume,  axis: .vertical).frame(maxWidth:.infinity, maxHeight: .infinity)
                }
                if resume != "" {
                    Button(action: {
                        navPath.append(ScriptGenerationView(navPath: $navPath, resume: resume))
                    }, label: {
                        Text("Proceed to script studio").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                    }).navigationDestination(for: ScriptGenerationView.self) { newView in
                        newView
                    }.padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                }
            }.navigationDestination(for: SegmentView.self) { newView in
                newView
            }
        }.onOpenURL { callingUrl in
            let queryItems = URLComponents(url: callingUrl, resolvingAgainstBaseURL: true)?.queryItems
            if queryItems == nil {
                return
            }
            for queryItem in queryItems! {
                if queryItem.name == "script"{
                    navPath.append(SegmentView(navPath: $navPath, segmentText: ScriptGenerationView.getScriptSegments(script: queryItem.value ?? "")))

                }
            }
        }
    }
}



#Preview {
    ContentView()
}
