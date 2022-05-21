//
//  ContentView.swift
//  Barcode scanner
//
//  Created by Skywalker on 2020/3/9.
//  Project manager: Ken
//  Copyright © 2020 OmuSkywalker. All rights reserved.
//

import CodeScanner
import SwiftUI
import AVFoundation
import SwiftUIRefresh
import Combine

// MARK: - Global variables
var resultStr = ""
var contents = ""

// MARK: - Picker array
let requestType = ["GET", "POST"]
let protocolType = ["HTTP", "HTTPS"]

var historys = HistoryObservable()
var historyArray: [Result] = combineHistory()
var resultArr: [String] = UserDefaults.standard.array(forKey: "Result") as? [String] ?? []

// MARK: - Data result structure
struct Result: Identifiable, Hashable {
    var id = UUID()
    var studentId: String
    var result: String
    var time: String
}

// MARK: - func: combine data into [Result]
func combineHistory() -> [Result] {
    var historyArr: [Result] = []
    let scanArr: [String] = UserDefaults.standard.array(forKey: "Student") as? [String] ?? []
    let reqArr: [String]  = UserDefaults.standard.array(forKey: "Result") as? [String] ?? []
    let timeArr: [String] = UserDefaults.standard.array(forKey: "Time") as? [String] ?? []
    
    for index in (0..<scanArr.count) {
        let historyItem = Result(studentId: scanArr[index], result: reqArr[index], time: timeArr[index])
        historyArr.append(historyItem)
    }
    
    return historyArr
}

func sortBy(byId: Int, Arr: [Result]) -> [Result] {
    switch byId {
    case 0:
        return Arr.sorted(by: { $0.studentId < $1.studentId })
    case 1:
        return Arr.sorted(by: { $0.result > $1.result })
    case 2:
        return Arr.sorted(by: { $0.time >  $1.time })
    default:
        return Arr
    }
    
}

// MARK: - Turn UserDefaults data into ObservableObject
class HistoryObservable: ObservableObject {
    @Published var scanArray: [String] = UserDefaults.standard.array(forKey: "Student") as? [String] ?? []
    @Published var reqArray: [String]  = UserDefaults.standard.array(forKey: "Result") as? [String] ?? []
    @Published var timeArray: [String] = UserDefaults.standard.array(forKey: "Time") as? [String] ?? []
    @Published var resultArray: [Result] = historyArray
    @Published var passCount: Int = resultArr.filter{$0 == "PASS"}.count
    @Published var failCount: Int = resultArr.filter{$0 == "NO PASS" || $0 == "FAILED"}.count
    
    func reload() {
        resultArr = UserDefaults.standard.array(forKey: "Result") as? [String] ?? []
        passCount = resultArr.filter{$0 == "PASS"}.count
        failCount = resultArr.filter{$0 == "NO PASS" || $0 == "FAILED"}.count
        scanArray = UserDefaults.standard.array(forKey: "Student") as? [String] ?? []
        reqArray  = UserDefaults.standard.array(forKey: "Result") as? [String] ?? []
        timeArray = UserDefaults.standard.array(forKey: "Time") as? [String] ?? []
        historyArray = combineHistory()
        resultArray = historyArray
    }
}

 class AppSettings: ObservableObject {
     @Published var mode: Bool = false
 }

// MARK: - Home
struct HomeView: View {
    @ObservedObject var historyData = historys
    @State var show_modal: Bool = false
    @State private var shakeOpen: Bool = UserDefaults.standard.bool(forKey: "ShakeOpen")
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .leading) {
                    Spacer()
                    HStack{
                        Spacer()
                        Spacer()
                        HomeButtonView(color: .green, name: "pass", result: "PASS", icon: "hand.thumbsup.fill", count: String(historyData.passCount), upOrDown: true)
                        Spacer()
                        Spacer()
                        HomeButtonView(color: .red, name: "fail", result: "NO PASS", icon: "hand.thumbsdown.fill", count: String(historyData.failCount), upOrDown: false)
                        Spacer()
                        Spacer()
                    }
                    Spacer()
                        .frame(height: 20.0)
                    Divider()
                    Spacer()
                        .frame(height: 10.0)
                    HistoryView()
                }
                .onReceive(messagePublisher) { (message) in
                    if UserDefaults.standard.bool(forKey: "ShakeOpen") {
                        self.appSettings.mode = true
                    }
                }
                VStack {
                    Spacer()
                    HStack() {
                        Spacer()
                        Button(action: {
                            self.appSettings.mode.toggle()
                        }) {
                            Image(systemName: "barcode.viewfinder").font(.system(size: 36)).foregroundColor(Color.white)
                        }.sheet(isPresented: self.$appSettings.mode) {
                            ModalView()
                        }.buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .navigationBarTitle("home-title")
            .navigationBarItems(trailing: SettingButton())
        }.navigationViewStyle(StackNavigationViewStyle())
        //.resignKeyboardOnDragGesture()

    }
    
    private func endEditing() {
        UIApplication.shared.endEditing()
    }
    
}

// MARK: - Home Button
struct HomeButtonView: View {
    var color: Color = .blue
    var name: LocalizedStringKey = ""
    var result: String = ""
    var icon: String = ""
    var count: String = "0"
    var upOrDown: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: ResultSelectView(result: result, name: name)) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(isPressed ? color : .white)
                            .padding(upOrDown ? .top : .bottom, -3.0)
                            .padding(.all, 12.0)
                            .background(isPressed ? .white : color)
                            .clipShape(Circle())
                            .padding(.leading, -4.0)
                        Spacer()
                        Text(count)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(isPressed ? .white : .primary)
                            .multilineTextAlignment(.trailing)
                    }
                    Text(name).foregroundColor(isPressed ? .white : .secondary).fontWeight(.semibold)
                }
            }
            .padding(.all, 10.0)
            .background(isPressed ? color : Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(Animation.linear.speed(2.5))
        }.buttonStyle(PlainButtonStyle())
        .background(Color.clear)
        .simultaneousGesture(DragGesture(minimumDistance: 0.0)
            .onChanged { _ in
                self.isPressed = true
        }
            .onEnded { _ in
                self.isPressed = false
        })
    }
}

// MARK: - Home button detail view
struct ResultSelectView: View {
    var result: String
    var name: LocalizedStringKey = ""
    @State private var historyArray:[Result] = combineHistory()
    
    var body: some View{
        List{
            ForEach(historyArray.filter {$0.result == result}, id: \.self) {(item) in
                NavigationLink(destination: HistoryDetailView(result: item)) {
                    ResultRow(result: item)
                }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
        }
        .navigationBarTitle(Text(name), displayMode: .inline)
    }
}

// MARK: - History List
struct HistoryView: View {
    @State private var isShowing = false
    @State private var sortType = 2
    @State private var showAlert = false
    @ObservedObject var historyData = historys
    
    @State private var searchText: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                SearchBar(text: $searchText, placeholder: "search-placeholder")
                Spacer()
            }
            HStack {
                Spacer()
                Spacer()
                Picker(selection: $sortType, label: Text("Sort Type")) {
                    Text("student-id").tag(0)
                    Text("result").tag(1)
                    Text("time").tag(2)
                }.pickerStyle(SegmentedPickerStyle())
                Spacer()
                Spacer()
            }
            List{
                ForEach(sortBy(byId: sortType, Arr: historyData.resultArray).filter{
                    self.searchText.isEmpty ? true : $0.studentId.lowercased().contains(self.searchText.lowercased())
                }, id: \.self) { (item) in
                    NavigationLink(destination: HistoryDetailView(result: item)) {
                        ResultRow(result: item)
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }.onDelete(perform: delete)
            }.pullToRefresh(isShowing: $isShowing) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.isShowing = false
                    self.self.historyData.reload()
                }
            }
        }.alert(isPresented: self.$showAlert , content: {
            Alert(title: Text("reset-alert-title"), message: Text("delete-text"), dismissButton: .default(Text("reset-alert-no")))
        })
    }
    
    func delete(at offsets: IndexSet) {
        if sortType != 2 {
            showAlert.toggle()
            return
        }
        
        historyData.scanArray = UserDefaults.standard.array(forKey: "Student") as? [String] ?? []
        historyData.reqArray  = UserDefaults.standard.array(forKey: "Result") as? [String] ?? []
        historyData.timeArray = UserDefaults.standard.array(forKey: "Time") as? [String] ?? []
        
        historyData.scanArray.remove(atOffsets: offsets)
        historyData.reqArray.remove(atOffsets: offsets)
        historyData.timeArray.remove(atOffsets: offsets)
        
        UserDefaults.standard.set( historyData.scanArray, forKey: "Student")
        UserDefaults.standard.set( historyData.reqArray, forKey: "Result")
        UserDefaults.standard.set( historyData.timeArray, forKey: "Time")
        
        historys.reload()
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Result list row
struct ResultRow: View {
    var result: Result
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(result.studentId)
                Text(result.time).font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            if result.result == "PASS" {
                Text("pass").foregroundColor(.green)
            } else if result.result == "NO PASS" || result.result == "FAILED" {
                Text("fail").foregroundColor(.red)
            } else {
                Text("other").foregroundColor(.gray)
            }
            
        }
    }
}

// MARK: - History detail pre-view
struct HistoryDetailView: View {
    var result: Result
    
    @ViewBuilder
    var body: some View {
        HStack {
            if result.result == "PASS" {
                HistoryDetailRowView(result: result, color: .green)
            } else if result.result == "NO PASS" || result.result == "FAILED" {
                HistoryDetailRowView(result: result, color: .red)
            } else {
                HistoryDetailRowView(result: result, color: .gray)
            }
        }
    }
}

// MARK: - History detail view
struct HistoryDetailRowView: View {
    var result: Result
    var color: Color = .blue

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .foregroundColor(color)
                .edgesIgnoringSafeArea(.all)
            VStack {
                VStack {
                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
                        if (result.result == "PASS") {
                            Text("pass")
                                .foregroundColor(.white)
                                .font(.system(size: 50))
                                .fontWeight(.bold)
                                .padding()
                        } else if result.result == "NO PASS" || result.result == "FAILED" {
                            Text("fail")
                                .foregroundColor(.white)
                                .font(.system(size: 50))
                                .fontWeight(.bold)
                                .padding()
                        } else {
                            Text("other")
                            .foregroundColor(.white)
                            .font(.system(size: 50))
                            .fontWeight(.bold)
                            .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .background(color)
                
                List {
                    HStack {
                        Text("student-id")
                        Spacer()
                        Text(result.studentId).foregroundColor(.secondary)
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    HStack {
                        Text("response-data")
                        Spacer()
                        Text(result.result).foregroundColor(.secondary)
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    HStack {
                        Text("upload-time")
                        Spacer()
                        Text(result.time).foregroundColor(.secondary)
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    HStack {
                        Text("UUID")
                        Spacer()
                        Text(result.id.uuidString).foregroundColor(.secondary).lineLimit(1)
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }.listStyle(GroupedListStyle())
            }
            .navigationBarTitle(Text("detail-title"), displayMode: .inline)
        }
    }
}

// MARK: - Select Day View
struct SelectDayView: View {
    @State private var showModal: Bool = false
    @State private var chooseDay = Date()
    let dateFormatter: DateFormatter = {
       let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-MM-dd"
       return dateFormatter
    }()
    
    @ObservedObject var historyData = historys
    
    var body: some View {
        NavigationView {
            VStack {
                List{
                    ForEach(historyData.resultArray.filter({$0.time.components(separatedBy: " ")[0] == dateFormatter.string(from: chooseDay)}), id: \.self) { (item) in
                        NavigationLink(destination: HistoryDetailView(result: item)) {
                            ResultRow(result: item)
                        }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    }
                }
            }
            .navigationBarTitle("day-title")
            .navigationBarItems(trailing:
                NavigationLink(destination: DatePicker("pick-day", selection: self.$chooseDay, displayedComponents: .date).labelsHidden()) {
                    Image(systemName: "calendar.circle").font(.system(size: 20))
                    Text(dateFormatter.string(from: chooseDay))
                }
            )
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}


// MARK: - Setting navgation button
enum SheetType {
    case day, setting
}
   

struct SettingButton: View {
    @State private var showModal: Bool = false
    @State private var showModalDay: Bool = false
    @State private var showActionSheet: Bool = false
   
    @State private var sheetType: SheetType = .setting
    
    var body: some View {
        Button (action: {
            self.showActionSheet.toggle()
        }) {
            Image(systemName: "ellipsis.circle").font(.system(size: 20))
            Text("nav-btn")
        }.actionSheet(isPresented: $showActionSheet, content: {
            ActionSheet(title: Text("action-title"), buttons: [
                .default(Text("action-date"), action: {
                    self.showModal.toggle()
                    self.sheetType = .day
                }),
                .default(Text("action-setting"), action: {
                    self.showModal.toggle()
                    self.sheetType = .setting
                }),
                .cancel()
            ])
        })
        .sheet(isPresented: self.$showModal) {
            if self.sheetType == .setting {
                SettingDetail()
            }
            else {
                SelectDayView()
            }
        }
    }
}

// MARK: - Setting View
struct SettingDetail: View {
    @State private var serverURL: String = UserDefaults.standard.string(forKey: "serverURL") ?? ""
    @State private var additionVal: String = UserDefaults.standard.string(forKey: "additionVal") ?? ""
    @State private var deleteAlert: Bool = false
    @State private var protocolTypeIndex:String = UserDefaults.standard.string(forKey: "protocolType") ?? "HTTP"
    @State private var requestTypeIndex:String = UserDefaults.standard.string(forKey: "requestType") ?? "GET"
    @State private var shakeOpen: Bool = UserDefaults.standard.bool(forKey: "ShakeOpen")
    
    var versionNum: String = UIApplication.appVersion! + " (" + UIApplication.buildVersion! + ")"

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("server-preference")) {
                    HStack {
                        Picker(selection: $protocolTypeIndex, label: Text("Protocol Type")) {
                            ForEach(protocolType, id: \.self) { (type) in
                                Text(type)
                            }
                        }.frame(width: 80.0).labelsHidden()
                        .onReceive([self.protocolTypeIndex].publisher.first()) { (value) in
                            UserDefaults.standard.set(value, forKey: "protocolType");
                        }
                        TextField("URL", text: self.$serverURL)
                        .onReceive([self.serverURL].publisher.first()) { (value) in
                            UserDefaults.standard.set(value, forKey: "serverURL");
                        }
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    TextField("addition", text: self.$additionVal)
                    .onReceive([self.additionVal].publisher.first()) { (value) in
                        UserDefaults.standard.set(value, forKey: "additionVal");
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    Picker(selection: $requestTypeIndex, label: Text("request-method")) {
                        ForEach(requestType, id: \.self) { (type) in
                            Text(type)
                        }
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .onReceive([self.requestTypeIndex].publisher.first()) { (value) in
                        UserDefaults.standard.set(value, forKey: "requestType");
                    }
                }
                Section {
                    Toggle(isOn: $shakeOpen) {
                        Text("shake-open")
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .onReceive([self.shakeOpen].publisher.first()) { (value) in
                            UserDefaults.standard.set(value, forKey: "ShakeOpen");
                    }
                }
                Section(header: Text("reset-footer")) {
                    Button(action: {
                        self.deleteAlert = true
                    }) {
                        Text("reset").foregroundColor(Color.red)
                    }.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
                Section(header: Text("app-info"), footer: Text("© 2020 LuSkywalker")) {
                    HStack {
                        Text("developer-name")
                        Spacer()
                        Text("LuSkywalker").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("current-version-num")
                        Spacer()
                        Text(self.versionNum).foregroundColor(.secondary)
                    }
                }
            }.listStyle(GroupedListStyle())
            .alert(isPresented: self.$deleteAlert , content: {
                    Alert(title: Text("reset-alert-title"), message: Text("reset-alert-text"), primaryButton: .default(Text("reset-alert-yes").fontWeight(.semibold), action: {
                            UserDefaults.standard.removeObject(forKey: "Student")
                            UserDefaults.standard.removeObject(forKey: "Result")
                            UserDefaults.standard.removeObject(forKey: "Time")
                            UserDefaults.standard.removeObject(forKey: "passCount")
                            UserDefaults.standard.removeObject(forKey: "failCount")
                            historys.reload()
                    }), secondaryButton: .destructive(Text("reset-alert-no"), action: {
                    }))
                })
            .navigationBarTitle("setting-title")
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Scanner modal
enum ActiveAlert {
    case first, second, third, bad
}

struct ModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var serverURL: String = UserDefaults.standard.string(forKey: "serverURL") ?? ""
    @State private var additionVal: String = UserDefaults.standard.string(forKey: "additionVal") ?? ""
    @State private var protocolTypeIndex:String = UserDefaults.standard.string(forKey: "protocolType") ?? "HTTP"
    @State private var requestTypeIndex:String = UserDefaults.standard.string(forKey: "requestType") ?? "GET"
    @State private var lightToggle: Bool = true
    
    @State private var activeAlert: ActiveAlert = .first
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                CodeScannerView(codeTypes: [.code39, .code128, .code93, .qr, .ean13], simulatedData: "Paul Hudson") { result in
                    switch result {
                    case .success(let code):
                        resultStr = code;
                        
                        let session = URLSession.shared
                        let url = URL(string: self.protocolTypeIndex.lowercased() + "://" + self.serverURL + "?text=" + resultStr + "&" + self.additionVal)!
                        var request = URLRequest(url: url)
                        request.httpMethod = self.requestTypeIndex
                        let task = session.dataTask(with: request, completionHandler: { data, response, error in
                            guard let error = error else {
                                guard let data = data else { return }
                                print(String(data: data, encoding: .utf8)!)
                                
                                if String(data: data, encoding: .utf8)! == "PASS" {
                                    contents = String(data: data, encoding: .utf8)!
                                    self.activeAlert = .first
                                } else if String(data: data, encoding: .utf8)! == "NO PASS" {
                                    contents = String(data: data, encoding: .utf8)!
                                    self.activeAlert = .second
                                    UIDevice.vibrate()
                                } else {
                                    contents = String(data: data, encoding: .utf8)!
                                    self.activeAlert = .third
                                }
                                
                                let now = Date()
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                let nowString = dateFormatter.string(from: now)
                                
                                self.showingAlert = true
                                                    
                                var scanArray = UserDefaults.standard.array(forKey: "Student") as? [String] ?? []
                                var reqArray  = UserDefaults.standard.array(forKey: "Result") as? [String] ?? []
                                var timeArray = UserDefaults.standard.array(forKey: "Time") as? [String] ?? []
                                scanArray.insert(resultStr, at:0)
                                reqArray.insert(contents, at:0)
                                timeArray.insert(nowString, at:0)
                                UserDefaults.standard.set( scanArray, forKey: "Student")
                                UserDefaults.standard.set( reqArray, forKey: "Result")
                                UserDefaults.standard.set( timeArray, forKey: "Time")
                                return
                            }
                            print(error)

                            self.activeAlert = .bad
                            self.showingAlert = true
                        })
                        task.resume()
                    case .failure(let error):
                        self.activeAlert = .bad
                        self.showingAlert = true
                        print(error)
                    }
                }.edgesIgnoringSafeArea(.all)
                .alert(isPresented: self.$showingAlert , content: {
                    switch activeAlert {
                    case .first:
                        return Alert(title: Text("student-id"), message: Text(resultStr), dismissButton: .default(Text("pass"), action: {
                            withAnimation {
                                historys.reload()
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }))
                    case .second:
                        return Alert(title: Text("student-id"), message: Text(resultStr), dismissButton: .destructive(Text("fail"), action: {
                            withAnimation {
                                historys.reload()
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }))
                    case .third:
                        return Alert(title: Text("student-id"), message: Text(resultStr), dismissButton: .cancel(Text("other"), action: {
                            withAnimation {
                                historys.reload()
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }))
                    case .bad:
                    return Alert(title: Text("reset-alert-title"), message: Text("wrong-text"), dismissButton: .destructive(Text("reset-alert-no"), action: {
                        withAnimation {
                            historys.reload()
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }))
                    }
                })
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: UIScreen.main.bounds.size.width, height: 3)
                        .opacity(0.7)
                    Spacer()
                }
                VStack {
                    GeometryReader { geometry in
                        VisualEffectView(effect: UIBlurEffect(style: self.colorScheme == .dark ? .dark : .light))
                            .edgesIgnoringSafeArea(.all)
                            .frame(width: geometry.size.width, height: 200)
                            .position(x: geometry.size.width/2, y: 100)
                        
                       VisualEffectView(effect: UIBlurEffect(style: self.colorScheme == .dark ? .dark : .light))
                            .edgesIgnoringSafeArea(.all)
                            .frame(width: geometry.size.width, height: 200)
                            .position(x: geometry.size.width/2, y: geometry.size.height-100)
                    }
                }
            }
            .navigationBarTitle("modal-title", displayMode: .inline)
            .navigationBarItems( leading:
                Button(action: {
                    self.toggleTorch(on: self.lightToggle)
                    self.lightToggle.toggle()
                }) {
                    if self.lightToggle {
                        Image(systemName: "lightbulb").font(.system(size: 20))
                    } else {
                        Image(systemName: "lightbulb.fill").font(.system(size: 20))
                    }
                },
                                 
                trailing:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("close-btn")
                }
            )
        }
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()

                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }

                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
}

// MARK: - Blur effect
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

// MARK: - Scanner button style
struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: ScaleButtonStyle.Configuration) -> some View {
        configuration.label
            .font(.title)
            .padding()
            .background(configuration.isPressed ? Color.gray : Color.blue)
            .clipShape(Circle())
            .padding()
    }
}

// MARK: - preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .previewDevice("iPhone 11 Pro")
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light")
                .environment(\.locale, .init(identifier: "en"))

            HomeView()
                .previewDevice("iPhone 11")
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")
                .environment(\.locale, .init(identifier: "en"))
        }
    }
}

// MARK: - UISearchBar View
struct SearchBar: UIViewRepresentable {

    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UISearchBarDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
            searchBar.showsCancelButton = true
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            text = ""
            searchBar.showsCancelButton = false
            searchBar.endEditing(true)
        }
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder.localizedStringKey()
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}

// MARK: - Shake controller
let messagePublisher = PassthroughSubject<String, Never>()

extension UIWindow {

    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event:   UIEvent?) {
        if motion == .motionShake {
            messagePublisher.send("Stop Shaking Me")
        }
    }
}

// MARK: - Vibration
extension UIDevice {
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

// MARK: - Localized String
extension String {

    func localizedStringKey(bundle _: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: "\(NSLocalizedString(self, tableName: "DefaultEnglish", bundle: .main, value: self, comment: ""))", comment: "")
    }
}

// MARK: - Keyboard
extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{_ in
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}

// MARK: - Camera
struct CameraView: UIViewControllerRepresentable {

    @Binding var showCameraView: Bool
    @Binding var pickedImage: Image

    func makeCoordinator() -> CameraView.Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        let cameraViewController = UIImagePickerController()
        cameraViewController.delegate = context.coordinator
        cameraViewController.sourceType = .camera
        cameraViewController.allowsEditing = false
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CameraView>) {

    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraView

        init(_ cameraView: CameraView) {
            self.parent = cameraView
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            parent.pickedImage = Image(uiImage: uiImage)
            parent.showCameraView = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.showCameraView = false
        }
    }
}

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    static var buildVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}
