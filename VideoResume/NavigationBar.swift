//
//  NavigationBar.swift
//  Ambission
//
//  Created by Nathan Merz on 7/22/24.
//

import Foundation
import SwiftUI


struct NavigationBar: View {
    @State var currentVideo: CreatedVideo?
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
            }.foregroundStyle(AMBISSION_ORANGE)
            Button {
                if currentScreen != ScriptGenerationView.self {
                    navPath.wrappedValue.append(ScriptGenerationView(navPath: navPath, videoModel: currentVideo))
                }
            } label: {
                VStack {
                    Image(systemName: "scroll")
                    Text("Script")
                }
            }.foregroundStyle(AMBISSION_ORANGE)
            Button {
                if currentScreen != SegmentView.self {
                    if currentVideo == nil {
                        navPath.wrappedValue.append(
                            NavigableText("Go create a new video from the Home tab!", toolbarContent:
                                            AnyView(NavigationBar(currentVideo: nil, navPath: navPath, currentScreen: SegmentView.self)))
                        )
                    } else {
                        navPath.wrappedValue.append(SegmentView(navPath: navPath, videoModel: currentVideo!))
                    }
                }
            } label: {
                VStack {
                    Image(systemName: "video")
                    Text("Record")
                }
            }.foregroundStyle(AMBISSION_ORANGE)
            Button {
                if currentScreen != ResumeEntryView.self {
                    navPath.wrappedValue.append(ResumeEntryView())
                }
            } label: {
                VStack {
                    Image(systemName: "person")
                    Text("Me")
                }
            }.foregroundStyle(AMBISSION_ORANGE)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
