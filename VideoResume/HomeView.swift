//
//  HomeView.swift
//  Ambission
//
//  Created by Nathan Merz on 7/29/24.
//

import Foundation
import SwiftUI
import SwiftData
import AVFoundation
import AVKit

let BUTTON_PURPLE = Color(red: 0.3607843137254902, green: 0.3137254901960784, blue: 0.7098039215686275)

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
    @State var optionsFor: CreatedVideo? = nil
    @State var showRenamePrompt = false
    @State var newName = ""
    @State var showDeletePrompt = false
    
    func OpenScriptWindow(nominalType: String) {
        let newVideo = CreatedVideo(nominalType: nominalType)
        modelContext.insert(newVideo)
        navPath.wrappedValue.append(ScriptGenerationView(navPath: navPath, videoModel: newVideo))
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack (spacing: 0) {
                Spacer().frame(width: 20)
                Text("New Project").bold().foregroundStyle(AMBISSION_ORANGE)
            }
            HStack (spacing: 0) {
                Spacer().frame(width:20)
                VStack (spacing:0) {
                    Spacer().frame(height:20)
                    Button(action: {
                        OpenScriptWindow(nominalType: "general")
                    }, label: {
                        Image(systemName: "hand.wave").resizable().scaledToFit().foregroundStyle(Color(uiColor: .white))
                    }).padding(.all, 10).background(RoundedRectangle(cornerRadius: 10.0).fill(BUTTON_PURPLE)).buttonStyle(PlainButtonStyle()).frame(maxWidth: .infinity).frame(width: 68, height: 68)
                    Spacer().frame(height:20)
                    Text("General Intro").bold().font(.system(size: 12)).foregroundStyle(BUTTON_PURPLE)
                }
                Spacer().frame(width:20)
                Spacer().frame(width:20)
                VStack (spacing:0) {
                    Spacer().frame(height:20)
                    Button(action: {
                        OpenScriptWindow(nominalType: "recruiter")
                    }, label: {
                        Image(systemName: "person.badge.plus").resizable().scaledToFit().foregroundStyle(Color(uiColor: .white))
                    }).padding(.all, 10).background(RoundedRectangle(cornerRadius: 10.0).fill(BUTTON_PURPLE)).buttonStyle(PlainButtonStyle()).frame(maxWidth: .infinity).frame(width: 68, height: 68)
                    Spacer().frame(height:20)
                    Text("Recruiter Intro").bold().font(.system(size: 12)).foregroundStyle(BUTTON_PURPLE)
                }
                Spacer().frame(width:20)
            }
            if pastVideos.count > 0 {
                HStack (spacing: 0) {
                    Spacer().frame(width: 20)
                    Text("Saved Projects").bold().foregroundStyle(AMBISSION_ORANGE)
                }
                ScrollView {
                    ForEach(pastVideos) { pastVideo in
                        HStack {
                            let firstSegmentWithVideo = pastVideo.segments.first { segment in
                                pastVideo.segmentUrls[segment] != nil
                            }
                            Group {
                                if firstSegmentWithVideo != nil {
                                    VideoPlayer(player: AVPlayer(url: pastVideo.segmentUrls[firstSegmentWithVideo!]!)).ignoresSafeArea(.all).id(pastVideo.segmentUrls[firstSegmentWithVideo!])
                                } else {
                                    RoundedRectangle(cornerRadius: 10.0).stroke(AMBISSION_ORANGE).foregroundStyle(Color.clear).overlay {
                                        RoundedRectangle(cornerRadius: 10.0).overlay(
                                            Image(systemName: "video").foregroundStyle(Color.white).frame(width: 40, height: 40)
                                        ).foregroundStyle(AMBISSION_ORANGE).frame(width: 50, height: 50)
                                    }
                                }
                            }.frame(width: 100, height: 100 * 16/9).onTapGesture {
                                activeVideo = pastVideo
                                navPath.wrappedValue.append(SegmentView(navPath: navPath, videoModel: pastVideo))
                            }
                            VStack {
                                Text(pastVideo.videoTitle).font(.system(size: 12)).foregroundStyle(Color.black).bold().bold()
                            }.onTapGesture {
                                navPath.wrappedValue.append(SegmentView(navPath: navPath, videoModel: pastVideo))
                            }
                            Button {
                                optionsFor = pastVideo
                            } label: {
                                Image(systemName: "ellipsis").rotationEffect(.degrees(90))
                            }.buttonStyle(PlainButtonStyle())
                        }.frame(maxWidth: .infinity).sheet(item: $optionsFor) { optionsFor in
                            VStack (alignment: .leading){
                                Text(optionsFor.videoTitle).frame(maxWidth: .infinity, alignment: .center).bold()
                                HStack {
                                    Image(systemName: "pencil.line")
                                    Text("Rename")
                                }.onTapGesture {
                                    showRenamePrompt = true
                                }.alert("Enter New Title", isPresented: $showRenamePrompt, presenting: optionsFor) { toRename in
                                    TextField("New name", text: $newName)
                                    Button("Set", action: {
                                        toRename.videoTitle = newName
                                        showRenamePrompt = false
                                        newName = ""
                                    })
                                    Button("Cancel", role: .cancel, action: {})
                                }
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }.onTapGesture {
                                    showDeletePrompt = true
                                }.alert("Confirm Deletion", isPresented: $showDeletePrompt, presenting: optionsFor) { toDelete in
                                    Text("Deleting " + toDelete.videoTitle)
                                    Button("Confirm", action: {
                                        if activeVideo == toDelete {
                                            activeVideo = nil
                                        }
                                        modelContext.delete(toDelete)
                                        self.optionsFor = nil
                                    })
                                    Button("Cancel", role: .cancel, action: {})
                                }
                            }.frame(maxHeight: .infinity).presentationDetents([.medium])
                        }
                    }
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(content: {
            ToolbarItem(placement: .bottomBar, content: {NavigationBar(currentVideo: activeVideo, navPath: navPath, currentScreen: HomeView.self)})
        }).background(AMBISSION_BACKGROUND).toolbarBackground(AMBISSION_BACKGROUND, for: .bottomBar).toolbarBackground(.visible, for: .bottomBar)

    }
    
}

