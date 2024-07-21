//
//  VideoResumeApp.swift
//  VideoResume
//
//  Created by Nathan Merz on 6/26/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


@main
struct VideoResumeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().modelContainer(for: [
                InputContent.self,
                CreatedVideo.self
            ])
//            JumperView()
        }
    }
}

struct JumperView: View  {
    @State var navPath = NavigationPath()
    
    var body: some View {

        NavigationStack(path: $navPath) {
            SegmentView(navPath: $navPath, videoModel: CreatedVideo(segmentTexts: ["1": "intro", "2": "job 1", "3": "job 2", "4": "job3", "5": "call to action"]))
//            EditClipView(navPath: $navPath, outputUrl: Binding(get: {
//                return FileManager().temporaryDirectory.appending(path: "11F0F2EC-821D-4F22-9BCF-9E906B0F1141.mov")
//            }, set: { newValue in
//                
//                print("setting output: " + newValue.absoluteString)
//            }))
        }
    }
}
