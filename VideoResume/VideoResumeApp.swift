//
//  VideoResumeApp.swift
//  VideoResume
//
//  Created by Nathan Merz on 6/26/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFunctions

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

var functions = Functions.functions()
let localMode = false

@main
struct VideoResumeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            
            ContentView().modelContainer(for: [
                InputContent.self,
                CreatedVideo.self
            ])
//            JumperView().modelContainer(for: [
//                InputContent.self,
//                CreatedVideo.self
//            ])
        }
    }
}

struct JumperView: View  {
    @State var navPath = NavigationPath()
    @Environment(\.modelContext) var modelContext

    var body: some View {

        NavigationStack(path: $navPath) {
            HomeView(navPath: $navPath)
//            SegmentView(navPath: $navPath, videoModel: CreatedVideo(unifiedScript: "into\njob 1\njob 2\njob3\ncall to action", segments: ["1", "2", "3", "4", "5"], segmentTexts: ["1": "intro", "2": "job 1", "3": "job 2", "4": "job3", "5": "call to action"], nominalType: "general")).navigationDestination(for: SegmentView.self) { newView in
//                newView
//            }.navigationDestination(for: ScriptGenerationView.self) { newView in
//                newView
//            }
//            EditClipView(navPath: $navPath, outputUrl: Binding(get: {
//                return FileManager().temporaryDirectory.appending(path: "11F0F2EC-821D-4F22-9BCF-9E906B0F1141.mov")
//            }, set: { newValue in
//                
//                print("setting output: " + newValue.absoluteString)
//            }))
        }
    }
}
