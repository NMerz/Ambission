//
//  NavigationBar.swift
//  Ambission
//
//  Created by Nathan Merz on 7/22/24.
//

import Foundation
import SwiftUI


struct NavigationBar: View {
    @State var currentVideo: CreatedVideo
    @State var navPath: Binding<NavigationPath>
    let currentScreen: any View.Type
    
    var body: some View {
        HStack {
            Button {
                if currentScreen != HomeView.self {
                    navPath.wrappedValue.append(HomeView(navPath: navPath, activeVideo: currentVideo))
                }
            } label: {
                VStack {
                    Image(systemName: "house")
                    Text("Home")
                }
            }.foregroundStyle(.foreground)
            Button {
                if currentScreen != ScriptGenerationView.self {
                    navPath.wrappedValue.append(ScriptGenerationView(navPath: navPath, videoModel: currentVideo))
                }
            } label: {
                VStack {
                    Image(systemName: "scroll")
                    Text("Script")
                }
            }.foregroundStyle(.foreground)
            Button {
                if currentScreen != SegmentView.self {
                    navPath.wrappedValue.append(SegmentView(navPath: navPath, videoModel: currentVideo))
                }
            } label: {
                VStack {
                    Image(systemName: "video")
                    Text("Record")
                }
            }.foregroundStyle(.foreground)
            Button {
                if currentScreen != ResumeEntryView.self {
                    navPath.wrappedValue.append(ResumeEntryView())
                }
            } label: {
                VStack {
                    Image(systemName: "person")
                    Text("Me")
                }
            }.foregroundStyle(.foreground)
        }
    }
}
