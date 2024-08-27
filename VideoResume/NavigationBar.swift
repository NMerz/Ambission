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
        HStack(alignment: .bottom, spacing: 0) {
            Group {
                Button {
                    if currentScreen != HomeView.self {
                        navPath.wrappedValue.append(HomeView(navPath: navPath, activeVideo: currentVideo))
                    }
                } label: {
                    VStack(spacing: 0) {
                        Rectangle().frame(width: 30, height: 3).foregroundStyle(currentScreen == HomeView.self ? AMBISSION_ORANGE : .clear)
                        Spacer().frame(minHeight: 2, maxHeight: .infinity) // There was a persistent 2 pixels of padding at the top and I couldn't find where it was coming from. This eliminates it for some reason.
                        Image(systemName: "house").resizable().scaledToFit().frame(width: 30, height: 25)
                        Spacer().frame(height: 5)
                        Text("Home").font(.system(size: 12))
                    }.frame(maxHeight: .infinity)
                }.foregroundStyle(AMBISSION_ORANGE).frame(maxHeight: .infinity).buttonStyle(PlainButtonStyle())
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            Group {
                Button {
                    if currentScreen != ScriptGenerationView.self {
                        navPath.wrappedValue.append(ScriptGenerationView(navPath: navPath, videoModel: currentVideo))
                    }
                } label: {
                    VStack(spacing: 0) {
                        Rectangle().frame(width: 30, height: 3).foregroundStyle(currentScreen == ScriptGenerationView.self ? AMBISSION_ORANGE : .clear)
                        Spacer().frame(minHeight: 2, maxHeight: .infinity)
                        Image(systemName: "scroll").resizable().scaledToFit().frame(width: 30, height: 25)
                        Spacer().frame(height: 5)
                        Text("Script").font(.system(size: 12))
                    }.frame(maxHeight: .infinity)
                }.foregroundStyle(AMBISSION_ORANGE).frame(maxHeight: .infinity).buttonStyle(PlainButtonStyle())
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            Group {
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
                    VStack(spacing: 0) {
                        Rectangle().frame(width: 30, height: 3).foregroundStyle(currentScreen == SegmentView.self ? AMBISSION_ORANGE : .clear)
                        Spacer().frame(minHeight: 2, maxHeight: .infinity)
                        Image(systemName: "video").resizable().scaledToFit().frame(width: 30, height: 25)
                        Spacer().frame(height: 5)
                        Text("Record").font(.system(size: 12))
                    }.frame(maxHeight: .infinity)
                }.foregroundStyle(AMBISSION_ORANGE).frame(maxHeight: .infinity).buttonStyle(PlainButtonStyle())
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            Group {
                Button {
                    if currentScreen != ResumeEntryView.self {
                        navPath.wrappedValue.append(ResumeEntryView(referrerCreatedVideo: currentVideo, navPath: navPath))
                    }
                } label: {
                    VStack(spacing: 0) {
                        Rectangle().frame(width: 30, height: 3).foregroundStyle(currentScreen == ResumeEntryView.self ? AMBISSION_ORANGE : .clear)
                        Spacer().frame(minHeight: 2, maxHeight: .infinity)
                        Image(systemName: "person").resizable().scaledToFit().frame(width: 30, height: 25)
                        Spacer().frame(height: 5)
                        Text("Me").font(.system(size: 12))
                    }.frame(maxHeight: .infinity)
                }.foregroundStyle(AMBISSION_ORANGE).frame(maxHeight: .infinity).buttonStyle(PlainButtonStyle())
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
