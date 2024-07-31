//
//  HomeView.swift
//  Ambission
//
//  Created by Nathan Merz on 7/29/24.
//

import Foundation
import SwiftUI
import SwiftData

struct HomeView: View, Hashable {
    static func == (lhs: HomeView, rhs: HomeView) -> Bool {
        lhs.pastVideos == rhs.pastVideos
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(pastVideos)
    }
    
    @Environment(\.modelContext) var modelContext
    @State var navPath: Binding<NavigationPath>
    @Query let pastVideos: [CreatedVideo]
    @State var activeVideo: CreatedVideo? = nil
    
    func OpenScriptWindow(nominalType: String) {
        let newVideo = CreatedVideo(nominalType: nominalType)
        modelContext.insert(newVideo)
        navPath.wrappedValue.append(ScriptGenerationView(navPath: navPath, videoModel: newVideo))
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    OpenScriptWindow(nominalType: "general")
                }, label: {
                    VStack {
                        Image(systemName: "hand.wave").resizable().scaledToFit().foregroundStyle(Color(uiColor: .white))
                        Text("General Intro").font(.system(size: 12)).foregroundStyle(Color(uiColor: .white))
                    }
                }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).fill(Color(uiColor: .purple))).buttonStyle(PlainButtonStyle())
                Button(action: {
                    OpenScriptWindow(nominalType: "recruiter")
                }, label: {
                    VStack {
                        Image(systemName: "person.badge.plus").resizable().scaledToFit().foregroundStyle(Color(uiColor: .white))
                        Text("Recruiter Intro").font(.system(size: 12)).foregroundStyle(Color(uiColor: .white))
                    }
                }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).fill(Color(uiColor: .purple))).buttonStyle(PlainButtonStyle())
            }
            if pastVideos.count > 0 {
                Text("Or, continue a past video:")
                ForEach(pastVideos) { pastVideo in
                    Button(action: {
                        navPath.wrappedValue.append(SegmentView(navPath: navPath, videoModel: pastVideo))
                    }, label: {
                        Text(pastVideo.videoTitle).font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
                    }).padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
                }
            }
        }
        .toolbar(content: {
            if activeVideo != nil {
                ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: activeVideo!, navPath: navPath, currentScreen: HomeView.self)})
            }
        })

    }
    
}

