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
            TextField("Generating...\nThis may take up to 30 seconds", text: $script,  axis: .vertical).frame(maxWidth:.infinity, maxHeight: .infinity).onAppear {
                    Task {
                        script = try await functions.httpsCallable("makeScript", requestAs: ScriptRequest.self, responseAs: String.self).call(ScriptRequest(tone: tone, resume: resume))
                    }
            }
            Button(action: {
                Task {
                    script = try await functions.httpsCallable("makeScript", requestAs: ScriptRequest.self, responseAs: String.self).call(ScriptRequest(tone: tone, resume: resume))
                }
            }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
            })
            Spacer().frame(width: 20)
        }
        Button(action: {
            navPath.wrappedValue.append(SegmentView(navPath: navPath, segmentText: getScriptSegments(script: script)))
        }, label: {
            Text("Proceed to video studio").font(.system(size: 24)).foregroundStyle(Color(uiColor: .label))
        }).navigationDestination(for: SegmentView.self) { newView in
            newView
        }.padding(.all, 5).background(RoundedRectangle(cornerRadius: 10.0).stroke(Color(uiColor: .label)))
    }
    
    func getScriptSegments(script: String) -> [String: String] {
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

#Preview {
    var navPath = NavigationPath()

    return  ScriptGenerationView(navPath: Binding(get: {
        navPath
    }, set: { newNavPath in
        navPath = newNavPath
    }), resume: """
                                                                                                                                                                                                                                                                                                EXPERIENCE
                                                                                                                                                                                                                                                                                                CROCS INC.
                                                                                                                                                                                                                                                                                                GLOBAL ECOMM PROJECT MANAGER
                                                                                                                                                                                                                                                                                                Led successful global brand expansion initiatives, utilizing strategic project management for revenue growth.
                                                                                                                                                                                                                                                                                                ● Managed Projects for HEYDUDE expansion in multiple countries; estimated revenue between $1-$10 Million.
                                                                                                                                                                                                                                                                                                ● Headed Crocs’ Marketing Technology project, enhancing Crocs and HEYDUDE websites, with each Sprint
                                                                                                                                                                                                                                                                                                completing upwards of 100 Story Points, including Tag Management, API Integrations, and Digital Commerce.
                                                                                                                                                                                                                                                                                                ● Contributed to Agile-focused Crocs Project Management program development.
                                                                                                                                                                                                                                                                                                ● Collaborated on defining project scope, objectives, and timelines with cross-functional teams.
                                                                                                                                                                                                                                                                                                ● Facilitated project status meetings and milestone reviews for effective communication.
                                                                                                                                                                                                                                                                                                ● Partnered with senior leadership to drive strategic initiatives for global growth and competitive advantage.
                                                                                                                                                                                                                                                                                                WUNDERKIND 04/2022 - 01/2023 Technical Solutions Manager
                                                                                                                                                                                                                                                                                                Effectively distilled and communicated development/technical requirements into business goals and applications.
                                                                                                                                                                                                                                                                                                ● Managed technical projects overseeing performance/success of 15 Strategic Accounts, totaling > $800K/mo.
                                                                                                                                                                                                                                                                                                ● Maintained an understanding of existing and upcoming API integrations.
                                                                                                                                                                                                                                                                                                ● Performed technical troubleshooting on reported potential bugs, performance issues, integration issues, and more.
                                                                                                                                                                                                                                                                                                ● Assessed feasibility and executed and managed development cycles for these projects.
                                                                                                                                                                                                                                                                                                ● Defined and managed vital product enhancements for Strategic Accounts.
                                                                                                                                                                                                                                                                                                ● Supported account security and changes.
                                                                                                                                                                                                                                                                                                ● Developed and maintained client relationships on strategic accounts to support sales, customer success, and
                                                                                                                                                                                                                                                                                                client growth.
                                                                                                                                                                                                                                                                                                ● Recognized as team expert on Feed and Catalog related development, troubleshooting, and training.
                                                                                                                                                                                                                                                                                                 ARRYVED
                                                                                                                                                                                                                                                                                                Technical Success Team Lead
                                                                                                                                                                                                                                                                                                Worked with the Development Team to deliver on strategic clients’ development requests.
                                                                                                                                                                                                                                                                                                ● Worked with Developers to run and design new Scripts.
                                                                                                                                                                                                                                                                                                ● Managed the Technical Support Team.
                                                                                                                                                                                                                                                                                                ● Directed all technical projects for >30 Strategic Accounts.
                                                                                                                                                                                                                                                                                                ● Oversaw client relationships for > 300 clients.
                                                                                                                                                                                                                                                                                                ● Performed basic QA testing and worked with QA team to resolve them.
                                                                                                                                                                                                                                                                                                ● Helped accomplish 2-week development cycles.
                                                                                                                                                                                                                                                                                                11/2020 - 04/2022
                                                                                                                                                                                                                                                                                                06/2023 - 05/2024
                                                                                                                                                                                                                                                                                                ● Hired Support Team personnel.
                                                                                                                                                                                                                                                                                                ● Promoted to lead the team in under six months.
                                                                                                                                                                                                                                                                                                BOULDER MARKIT
                                                                                                                                                                                                                                                                                                Founder
                                                                                                                                                                                                                                                                                                Acquired clients and managed social media marketing for multiple focused clients.
                                                                                                                                                                                                                                                                                                ● Executed marketing solutions across various social media platforms.
                                                                                                                                                                                                                                                                                                ● Implemented sales solutions based on technical acumen and research.
                                                                                                                                                                                                                                                                                                ● Managed > 6 portfolios across multiple platforms.
                                                                                                                                                                                                                                                                                                ALJEX INC.
                                                                                                                                                                                                                                                                                                Project Manager
                                                                                                                                                                                                                                                                                                Provided project management for daily and long-term technical projects.
                                                                                                                                                                                                                                                                                                ● Served as client relationship lead.
                                                                                                                                                                                                                                                                                                ● Helped acquire 7 new clients.
                                                                                                                                                                                                                                                                                                ● Managed and completed upwards of 30 major programming goals.
                                                                                                                                                                                                                                                                                                ● Implemented project management tool, Jira, to increase programming efficiency.
                                                                                                                                                                                                                                                                                                ASPEX POS
                                                                                                                                                                                                                                                                                                Sales and Project Manager
                                                                                                                                                                                                                                                                                                Functioned as project manager for Mobile Point of Sale (POS) development.
                                                                                                                                                                                                                                                                                                ● Oversaw and developed marketing strategies for technical products and re-branding.
                                                                                                                                                                                                                                                                                                ● Acquired > 10 new clients yearly.
                                                                                                                                                                                                                                                                                                ● Successfully managed > 80 client relationships.
                                                                                                                                                                                                                                                                                                ● Managed POS software sales and implementation for new clients.
                                                                                                                                                                                                                                                                                                ● Built sales strategies for future sales reps.
                                                                                                                                                                                                                                                                                                """)
}
