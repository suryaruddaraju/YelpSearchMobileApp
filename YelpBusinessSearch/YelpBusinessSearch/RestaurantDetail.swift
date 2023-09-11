//
//  RestaurantDetail.swift
//  YelpBusinessSearch
//
//  Created by Surya Ruddaraju on 12/4/22.
//

import SwiftUI
import SwiftyJSON
import Alamofire
import Kingfisher
import MapKit
import FacebookCore
import FacebookShare

struct RestaurantDetail: View {
    
    var restaurant: Restaurant;
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    
    @State private var showingSheet = false
    @State var myRes: [[String]] = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
    @State var hasRes: Bool = false;
    @State var resInd: Int = -1;
    @State var reviews: [Review] = []
    @State var imgs: [String] = []
    @State var imgsLoaded: Bool = false;
    
    @State var restJson: JSON = ""
    
    init(restaurant: Restaurant){
        self.restaurant = restaurant
    }
    
    var body: some View {
        
        TabView {
            VStack{
                HStack{
                    Spacer()
                    VStack{
                        Text("Address")
                            .bold()
                        Text(restaurant.address)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack{
                        Text("Category")
                            .bold()
                        Text(restaurant.category)
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                    Spacer()
                }
                
                Spacer()
                HStack{
                    Spacer()
                    VStack{
                        Text("Phone")
                            .bold()
                        Text(restaurant.phone)
                        
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack{
                        Text("Price")
                            .bold()
                        Text(restaurant.price)
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                    Spacer()
                }
                
                Spacer()
                HStack{
                    Spacer()
                    VStack{
                        Text("Status")
                            .bold()
                        if(restaurant.isClosed){
                            Text("Closed")
                                .foregroundColor(Color.red)
                        } else {
                            Text("Open")
                                .foregroundColor(Color.green)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack{
                        Text("Visit Yelp for more info")
                            .bold()
                        let link = "[link]("+restaurant.link+")"
                        Text(.init(link))
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                    Spacer()
                }
                
                Spacer()
                if(!hasRes){
                    Button(action: {
                        print("reserve")
                        showingSheet.toggle()
                    }, label: {
                        Text("Reserve Now")
                        .foregroundColor(Color.white)
                        .font(.system(size: 20))
                    })
                    .frame(width: 200, height: 50)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .buttonStyle(BorderlessButtonStyle())
                    .sheet(isPresented: $showingSheet, onDismiss: checkRes) {
                        ReservationForm(restName: restaurant.name)
                    }
                } else {
                    Button(action: {
                        print("before: " + String(resInd))
                        print(myRes)
                        myRes.remove(at: resInd)
                        print("after: ")
                        print(myRes)
                        UserDefaults.standard.set(myRes, forKey: "reservations")
                        
                        let test = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
                        
                        print("in USD after set in detail")
                        print(test)
                        
                        hasRes = false
                        resInd = -1
                    }, label: {
                        Text("Cancel Reservation")
                        .foregroundColor(Color.white)
                        .font(.system(size: 20))
                    })
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                List{
                    if(imgsLoaded){
                        TabView {
                            ForEach(imgs, id: \.self) { img in
                                 
                                KFImage(URL(string: img)!)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 300)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    } else {
                        ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                
            }.tabItem {
                Label("Business Detail", systemImage: "text.bubble.fill")
            }
            .background(Color(red: 242/255.0, green: 242/255.0, blue: 247/255.0))
                .navigationTitle(restaurant.name)
                .onAppear {
                    checkRes()
                }
            
            VStack {
                let markers = [MapLocation(latitude: restJson["coordinates"]["latitude"].doubleValue, longitude: restJson["coordinates"]["longitude"].doubleValue)]
                Map(coordinateRegion: $region, annotationItems: markers){
                    MapMarker(coordinate: $0.coordinate)
                }
            }
            .tabItem(){
                Label("Map Location", systemImage: "location.fill")
            }
            .navigationTitle("")
            .onAppear{
                region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: restJson["coordinates"]["latitude"].doubleValue, longitude: restJson["coordinates"]["longitude"].doubleValue), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            }
            
            ReviewView(reviews: reviews)
            .tabItem(){
                Label("Reviews", systemImage: "message.fill")
            }
            
        }
        .onAppear{
            var url = "https://angularapp-368104.uc.r.appspot.com/api/getRestaurants/" + restaurant.alias
            
            AF.request(url).validate().responseJSON { response in
                if let data = response.data {
                    restJson = JSON(data)
                    print("in getRestDetails")
                    print(restJson)
                    region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: restJson["coordinates"]["latitude"].doubleValue, longitude: restJson["coordinates"]["longitude"].doubleValue), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
                    
                    print("Coordinates: " + String(restJson["coordinates"]["latitude"].doubleValue) + ", " + String(restJson["coordinates"]["longitude"].doubleValue))
                    
                    
                    print("Photos: ")
                    for (_, str) in restJson["photos"]{
                        print(str.stringValue)
                        imgs.append(str.stringValue)
                    }
                    
                    imgsLoaded = true
                }
            }
            
            var reviewUrl = "https://angularapp-368104.uc.r.appspot.com/api/reviews/" + restaurant.alias
            
            AF.request(reviewUrl).validate().responseJSON { response in
                if let data = response.data {
                    let json = JSON(data)
                    var index = 0
                    for (ind, obj) in json["reviews"] {
                        print("reviews")
                        print(obj["id"])
                        let review = Review(text: obj["text"].stringValue, rating: obj["rating"].doubleValue, name: obj["user"]["name"].stringValue, date: obj["time_created"].stringValue)
                        
                        reviews.append(review)
                    }
                }
            }
        }
    }
    
    func checkRes() {
        myRes = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
        
        print("in checkRes()")
        print(myRes)
        print()
        print()
        for arr in myRes{
            resInd += 1
            print("compare: -" + arr[0] + "--" + restaurant.name + "-")
            if(arr[0] == restaurant.name){
                hasRes = true;
                break;
            }
            print()
        }
    }
}



struct Review: Identifiable, Hashable {
    var id = UUID()
    var text: String
    var rating: Double
    var name: String
    var date: String
}

struct ReviewRow: View {
    
    var review: Review;
    
    init(review: Review){
        self.review = review
    }
    
    var body: some View {
        VStack {
            HStack{
                Text(review.name)
                    .bold()
                Spacer()
                Text(String(review.rating) + "/5")
                    .bold()
            }
            Text(review.text)
            
            Text(review.date.prefix(upTo: review.date.firstIndex(of: " ") ?? review.date.endIndex))
        }
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct ReviewView: View {
    
    var reviews: [Review];
    
    init(reviews: [Review]){
        self.reviews = reviews
    }
    
    var body: some View {
        List {
            ForEach(reviews) { rev in
                ReviewRow(review: rev)
            }
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ReservationForm: View {
    @Environment(\.dismiss) var dismiss
    
    var restName: String;
    
    init(restName: String){
        self.restName = restName
    }
    
    @State var email:String = "";
    @State var resDate:Date = Date.now;
    @State var resHour:String = "10";
    @State var resMins:String = "00";
    @State private var invalidEmail:Bool = false;
    @State var resSuccess = false;

    var body: some View {
        if(!resSuccess){
            ZStack {
                Color(UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1.0))
                    .ignoresSafeArea()
                
                VStack(spacing: 10){
                    
                    Text("Reservation Form")
                        .bold()
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .heavy))
                        .frame(width: 350, height:45, alignment: .center)
                        .multilineTextAlignment(.center)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.top, 10)
                    
                    
                    Text(restName)
                        .bold()
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30))
                        .frame(width: 350, height:45, alignment: .center)
                        .multilineTextAlignment(.center)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.top, 10)

                    
                    List{
                        HStack {
                            Text("email: ")
                                .foregroundColor(Color.gray)
                            TextField("", text: $email)
                            
                        }
                        
                        HStack {
                            Text("Date/Time:")
                                .foregroundColor(Color.gray)
                            
                            var startDate = Date.now
                            DatePicker(selection: $resDate, in: Date.now..., displayedComponents: .date) {
                            }
                            
                            let hours = [10, 11, 12, 13, 14, 15, 16, 17]
                            Picker("", selection: $resHour){
                                ForEach(hours, id:\.self) { hour in
                                    Text("\(hour)")
                                }
                            }
                            .pickerStyle(.menu)
                            
                            
                            Text(":")
                            let mins = ["00", "15", "30", "45"]
                            Picker("", selection: $resMins){
                                ForEach(mins, id:\.self) { min in
                                    Text("\(min)")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        HStack {
                            Spacer()
                            Button(action: {
                                if(submitRes()){
                                    resSuccess = true;
                                }
                                
                            }, label: {
                                Text("Submit")
                                .foregroundColor(Color.white)
                                .background(Color.blue)
                            })
                            .frame(width: 100, height: 50)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(10)
                            Spacer()
                            
                        }
                        
                    }
                    
                    Spacer()
                    Spacer()
                    if(invalidEmail){
                        Text("Please enter a valid email.")
                            .multilineTextAlignment(.center)
                            .frame(width: 300, height:50, alignment: .center)
                            .multilineTextAlignment(.center)
                            .background(Color(red: 0.7, green: 0.7, blue: 0.7))
                            .cornerRadius(10)
                    }
                }
            }
        } else {
            VStack{
                Spacer()
                Spacer()
                Text("Congratulations!")
                    .foregroundColor(Color.white)
                Spacer()
                Text("You have successfully made a resevation at " + restName + "!")
                    .foregroundColor(Color.white)
                Spacer()
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Done")
                    .foregroundColor(Color.green)
                    .background(Color.white)
                })
                    .frame(width: 100, height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(10)
            }
            .background(Color.green)
        }
    }
    
    func submitRes() -> Bool{
        if(email.range(of: #"^\S+@\S+\.\S+$"#, options: .regularExpression) == nil){
            invalidEmail = true;
            return false;
        }
        
        let resTime = String(resHour) + ":" + String(resMins)
        
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'"
        
        var myRes: [[String]] = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
        
        let resObj = [restName, email, formatter.string(from: resDate), resTime]
        myRes.append(resObj)
        
        UserDefaults.standard.set(myRes, forKey: "reservations")

//        var temp: [[String]] = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
//        print("RES AFTER: ")
//        print(temp)

        return true;
    }
}

struct Toast<Presenting>: View where Presenting: View {

    /// The binding that decides the appropriate drawing in the body.
    @Binding var isShowing: Bool
    /// The view that will be "presenting" this toast
    let presenting: () -> Presenting
    /// The text to show
    let text: Text

    var body: some View {

        GeometryReader { geometry in

            ZStack(alignment: .center) {

                self.presenting()
                    .blur(radius: self.isShowing ? 1 : 0)

                VStack {
                    self.text
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .transition(.slide)
                .opacity(self.isShowing ? 1 : 0)

            }

        }

    }

}

var restaurantEx = Restaurant(ind: 0,
                              alias: "sk-donuts-and-croissant-los-angeles",
                              name: "SK Donuts & Croissant",
                              img: "https://s3-media3.fl.yelpcdn.com/bphoto/KJMZ0eazBbMFmg9ode6uoA/o.jpg",
                              rating: 4.5,
                              distance: 10,
                              address: "5850 W 3rd St, Los Angeles, CA 90036",
                              category: "donuts|bakeries|vegan",
                              phone: "(323) 935-2409",
                              price: "$",
                              isClosed: false,
                              link: "https://www.yelp.com/biz/sk-donuts-and-croissant-los-angeles?adjust_creative=io3vzCqVfqI0ws6HLfyTuA&utm_campaign=yelp_api_v3&utm_medium=api_v3_business_search&utm_source=io3vzCqVfqI0ws6HLfyTuA"
        )
//
//    var id = UUID()
//    var ind: Int
//    var alias: String
//    var name: String
//    var img: String
//    var rating: Double
//    var distance: Int
//    var address: String
//    var category: String
//    var phone: String
//    var price: String
//    var isClosed: Bool
//    var link: String
//}

struct RestaurantDetail_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RestaurantDetail(restaurant: restaurantEx)
            RestaurantDetail(restaurant: restaurantEx)
        }
    }
}
