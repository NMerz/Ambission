//
//  ResumeEntryView.swift
//  Ambission
//
//  Created by Nathan Merz on 7/29/24.
//

import Foundation
import SwiftUI
import PDFKit
import SwiftData

let AMBISSION_ORANGE = Color(red: 1, green: 0.3058823529411765, blue: 0.06274509803921569)

struct ResumeEntryView: View, Hashable {
    static func == (lhs: ResumeEntryView, rhs: ResumeEntryView) -> Bool {
        lhs.presentFileSelection == rhs.presentFileSelection && lhs.inputContent == rhs.inputContent && lhs.manualEntry == rhs.manualEntry
    }
    
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(presentFileSelection)
        hasher.combine(inputContent)
    }
    
    @State var presentFileSelection = false
    @State var manualEntry = false
    @State var inputContent: InputContent? = nil
    @State var advance = false
    @State var referrerCreatedVideo: CreatedVideo?
    @State var navPath: Binding<NavigationPath>
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        VStack {
            Button(action: {
                presentFileSelection = true
            }, label: {
                Text("Upload a pdf resume").font(.system(size: 24)).foregroundStyle(Color.white)
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
            }.padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).foregroundStyle(AMBISSION_ORANGE))
            if inputContent?.file != nil && inputContent?.file != "" {
                Text(inputContent!.file)
            }
            
            
//            Button(action: {
//                manualEntry = true
//            }, label: {
//                Text("Or type it in yourself").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
//            }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
//            if manualEntry == true {
//                TextField("Paste your resume here", text: Binding(get: {
//                    inputContent?.resume ?? ""
//                }, set: { newValue in
//                    inputContent?.resume = newValue
//                }),  axis: .vertical).frame(maxWidth:.infinity, maxHeight: .infinity)
//            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(AMBISSION_BACKGROUND).onAppear {
            var storedInputs = try! modelContext.fetch(FetchDescriptor<InputContent>()).first
            if storedInputs == nil {
                storedInputs = InputContent()
                modelContext.insert(storedInputs!)
            }
            inputContent = storedInputs
        }.toolbar(content: {ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: referrerCreatedVideo, navPath: navPath, currentScreen: ResumeEntryView.self)})})
    }
    
}
