//
//  NewSwiftUI.swift
//  WordLensAR
//
//  Created by arjun on 7/28/23.
//


import SwiftUI

struct NewView: View {
    var body: some View{
        
        NavigationView{
            Home()
                .preferredColorScheme(.dark)
                .navigationTitle("")
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
        }
    }
}

struct NewView_Preview: PreviewProvider {
    static var previews: some View{
        NewView()
    }
}

struct Home: View {
    
    @State var tab = "Reading"
    @Namespace var animation
    @State var subTab = "Today"
    @State var dailySaled = [
        // Last 7 Days...
        DailySales(day: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, value: 32, show: true, time: "Sun"),
        DailySales(day: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, value: 48, show: false, time: "Mon"),
        DailySales(day: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, value: 56, show: false, time: "Tues"),
        DailySales(day: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, value: 93, show: false, time: "Wed"),
        DailySales(day: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, value: 35, show: false, time: "Thur"),
        DailySales(day: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, value: 73, show: false, time: "Fri"),
        DailySales(day: Date(), value: 42, show: false, time: "Sat")
    ]
    @State var edges = UIApplication.shared.windows.first?.safeAreaInsets
//    var link : NavigationDestinationLink<Text>
    
    var body: some View{
        VStack{
            
            HStack{
                Button(action:{}){
                    Image("menu").resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 32.0, height: 32.0)
                }
                
                Spacer(minLength: 0)
                
//                Button(action:{
////                    self.link = NavigationDesintationLink()
//                    print("HI")
//                }){
//                    Image("bell").resizable()
//                        .renderingMode(.template)
//                        .foregroundColor(.white)
//                        .frame(width: 32.0, height: 32.0)
//                }
//
                    Image("bell").resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 32.0, height: 32.0)
//                NavigationButton(destination: Text("hi")){
//                    Image("bell").resizable()
//                        .renderingMode(.template)
//                        .foregroundColor(.white)
//                        .frame(width: 32.0, height: 32.0)
//                }
            }
            .padding()
            
            VStack{
                Text("User Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
//                Spacer(minLength: 0)
//                Text("Dashboard")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
                //Spacer(minLength: 0)
                
            }
            .padding()
             
            HStack(spacing: 0){
                TabButton(selected: $tab, title: "Reading", animation: animation)
                TabButton(selected: $tab, title: "Writing", animation: animation)
            }
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .padding(.horizontal)
            
            HStack(spacing: 20){
                ForEach(subTabs, id: \.self){tab in
                    Button(action: {subTab = tab}){
                        Text(tab)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white.opacity(subTab == tab ? 1 : 0.4))
                    }
                }
            }
            .padding()
            
            // Or you can use ForEach also
            VStack(spacing: 20){
                HStack(spacing: 15){
                    SalesView(sale: salesData[0])
                    SalesView(sale: salesData[1])
                }
                HStack(spacing: 15){
                    SalesView(sale: salesData[2])
                    SalesView(sale: salesData[3])
                    SalesView(sale: salesData[4])
                }
            }
            .padding(.horizontal)
            
            ZStack{
                Color.white
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], size: 45))
                    .edgesIgnoringSafeArea(.bottom)
                
                VStack{
                    HStack{
                        Text("Weekly Progress")
                            .font(.title2)
                            .foregroundColor(.black)
                        
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .padding(.top, 10)
                    
                    HStack(spacing: 10){
                        ForEach(dailySaled.indices, id: \.self){ i in
                            // For Toggling Show Button...
                            GraphView(data: dailySaled[i], allData: dailySaled)
                                .onTapGesture {
                                    withAnimation{
                                        // toggling all other...
                                        for index in 0..<dailySaled.count{
                                            dailySaled[index].show = false
                                            
                                        }
                                        dailySaled[i].show.toggle()
                                    }
                                }
                            
                            // sample spacing For Spacing Effect...
                            if dailySaled[i].value != dailySaled.last!.value{
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, edges!.bottom == 0 ? 15 : 0)
                }
                    
            }
            .padding(.top, 20)
            
            //Spacer(minLength: 0)
        }
        .background(Color("bg").edgesIgnoringSafeArea(.all))
    }
    
}

var subTabs = ["Today", "Last Week"]

struct TabButton: View {
    @Binding var selected : String
    var title : String
    var animation : Namespace.ID
    
    var body: some View{
        Button(action: {
            withAnimation(.spring()){
                selected = title
            }
        }){
            ZStack{
                // Capsule  and Sliding Effect ...
                Capsule()
                    .fill(Color.clear)
                    .frame(height: 45)
                
                if selected == title {
                    Capsule()
                        .fill(Color.white)
                        .frame(height: 45)
                    // Matched Geometry Effect ...
                        .matchedGeometryEffect(id: "Tab", in: animation)
                }
                Text(title)
                    .foregroundColor(selected == title ? .black : .white)
                    .fontWeight(.bold)
            }
        }
    }
}

// Sample Model Data ...
struct Sales : Identifiable {
    var id = UUID().uuidString
    var title : String
    var value : String
    var color : Color
}

var salesData = [
    Sales(title: "Yesterday", value: "elephant", color: Color.orange),
    Sales(title: "Most Missed", value: "vacuum", color: Color.red),
    Sales(title: "Missed", value: "37", color: Color.blue),
    Sales(title: "Practice", value: "51", color: Color.pink),
    Sales(title: "Written", value: "9", color: Color.purple)
]

// Daily Sold Model And Data...
struct DailySales : Identifiable {
    var id = UUID().uuidString
    var day : Date
    var value : CGFloat
    var show : Bool
    var time: String
}


struct SalesView: View {
    var sale: Sales
    
    var body: some View{
        ZStack{
            HStack{
                VStack(alignment: .leading, spacing: 22){
                    Text(sale.title)
                        .foregroundColor(.white)
                    Text(sale.value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(sale.color)
        .cornerRadius(10)
        
    }
}


// Custom Corners
struct CustomCorners: Shape {
    var corners : UIRectCorner
    var size : CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: size, height: size))
        
        return Path(path.cgPath)
    }
}

struct GraphView : View {
    var data : DailySales
    var allData : [DailySales]
    var body: some View{
        VStack(spacing: 5){
            GeometryReader {reader in
                VStack(spacing: 0){
                    Spacer(minLength: 0)
                    Text("\(Int(data.value))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        // Default height for Graph...
                        .frame(height: 20)
                        .opacity(data.show ? 1 : 0)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.red.opacity(data.show ? 1: 0.4))
                        .frame(height: calculateHeight(value: data.value, height: reader.frame(in: .global).height - 20))
                }
            }
            
//            Text(customDateStyle(date: data.day))
//                .font(.caption2)
//                .foregroundColor(.gray)
            Text(data.time)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    func customDateStyle(date : Date)->String {
        let format = DateFormatter()
        format.dateFormat = "MMM dd"
        return format.string(from: date)
    }
    
    func calculateHeight(value: CGFloat, height: CGFloat)->CGFloat{
        let max = allData.max {(max, sale) -> Bool in
            if max.value > sale.value {return false}
            else {return true}
        }
        
        let percent = value / max!.value
        
        return percent * height
    }
}

