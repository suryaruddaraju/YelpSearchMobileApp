//
//  ContentView.swift
//  YelpBusinessSearch
//
//  Created by Surya Ruddaraju on 12/3/22.
//

import SwiftUI
import Alamofire
import SwiftyJSON
import Kingfisher

struct BusinessSearchView: View {
    var catgs = ["Default", "Arts and Entertainment", "Health and Medical", "Hotels and Travel", "Food", "Professional Services"];
    
    @State var subDsbl = true;
    @State var subColor = Color.gray
    
    @State var keyword: String = "";
    @State var distance: String = "10";
    @State var category: String = "Default";
    @State var location: String = ""
    @State var autoLoc: Bool = false;
    @State var autoLocVal: String = "";
    
    @State var searchRes: [Restaurant] = [];
    @State var submitted: Bool = false;
    @State var finished: Bool = false;
    
    init(){
//        UserDefaults.standard.set([], forKey: "reservations")
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Keyword : ")
                        TextField("keyword", text: $keyword, onCommit: { formChange() })
                        
                    }
                    HStack {
                        Text("Distance: ")
                        TextField("", text: $distance, onCommit: { formChange() })
                    }
                    HStack {
                        Text("Category: ")
                        Menu {
                            ForEach(catgs, id: \.self) { cat in
                                Button{
                                    category = cat
                                } label: {
                                    Text(cat)
                                }
                            }
                        } label: {
                            Text(category)
                        }
                    }
                    if !autoLoc {
                        HStack {
                            Text("Location: ")
                            TextField("Required", text: $location, onCommit: { formChange() })
                        }
                    }
                    Toggle("Auto-detect my location", isOn: $autoLoc)
                    .onChange(of: autoLoc) { value in
                        getLocation()
                    }
                    
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            print("CLICK SUBMIT")
                            submitForm()
                        }, label: {
                            Text("Submit")
                            .foregroundColor(Color.white)
                        })
                        .frame(width: 100, height: 50)
                        .background(subDsbl ? Color.gray : Color.red)
                        .disabled(subDsbl)
//                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            keyword = "";
                            distance = "10";
                            category = "Default";
                            location = ""
                            autoLoc = false;
                            searchRes.removeAll()
                            submitted = false
                            finished = false
                        }, label: {
                            Text("Clear")
                            .foregroundColor(Color.white)
                        })
                        .frame(width: 100, height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .buttonStyle(BorderlessButtonStyle())
                        Spacer()
                    }.padding(20)
                }
                
                Section {
                    Text("Results")
                    .bold()
                    .font(.system(size: 30))
                    
                    if(submitted){
                        if(finished){
                            if(searchRes.isEmpty){
                                Text("No results available")
                                .foregroundColor(Color.red)
                            } else {
                                ForEach(searchRes){ rest in
                                    NavigationLink {
                                        RestaurantDetail(restaurant: rest)
                                    } label: {
                                        RestaurantRow(restaurant: rest)
                                    }
                                        
                                        
                                }
                            }
                        } else {
                            VStack{
                                ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                
                                Text("Please wait...")
                            }
                        }
                    }
                }
                
                .navigationTitle("Business Search")
                .toolbar{
                    NavigationLink {
                        ReservationsView()
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                    }
                }
                
                
            }
        }
        .onAppear {
            let myRes = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
            
            print("in Search USD")
            print(myRes)
        }
        
    }
    
    func submitForm() {
        
        print("IN SUBMIT")
        submitted = true;
        finished = false;
        
        var lat = 0.0;
        var long = 0.0;
        
        if(!autoLoc){
            let locUrl = "https://maps.googleapis.com/maps/api/geocode/json?address=" + location + "&key=AIzaSyClGHeQVPCpVDhOZUhhwx3YzM955N6GlsI"
            AF.request(locUrl).validate().responseJSON { response in
                if let data = response.data {
                    let json = JSON(data)
                    lat = json["results"][0]["geometry"]["location"]["lat"].doubleValue
                    long = json["results"][0]["geometry"]["location"]["lng"].doubleValue
                    performSearch(lat: lat, long: long)
                } else {
                    return
                }
            }
        } else {
            let arr = autoLocVal.components(separatedBy: ",")
            lat = Double(arr[0])!
            long = Double(arr[1])!
            performSearch(lat: lat, long: long)
        }
    }
    
    func performSearch(lat: Double, long: Double) {
        
        print("keyword: " + keyword)
        print("distance: " + distance)
        print("category: " + category)
        print("lat: " + String(lat))
        print("long: " + String(long))
        
        var url = "https://angularapp-368104.uc.r.appspot.com/api/restaurants/search/"
        url += keyword + "/"
        url += String(lat) + "/"
        url += String(long) + "/"
        url += category + "/"
        url += String(Int(distance)!*1609)
        
        
        print(url)
        
        AF.request(url).validate().responseJSON { response in
            
            print("IN REQUEST BODY")
            if let data = response.data {
                let json = JSON(data)
                var index = 0
                searchRes.removeAll()
                for (ind, obj) in json["businesses"] {
                    
                    
                    if(index == 10){
                        break
                    }
                    
                    var catString = ""
                    
                    for (ind, cat) in obj["categories"]{
                        catString += cat["title"].stringValue + "|"
                    }
                    
                    var address = obj["location"]["display_address"][0].stringValue + ", " + obj["location"]["display_address"][1].stringValue
                    
                    var rest = Restaurant(ind: index+1,
                                          alias: obj["alias"].stringValue,
                                          name: obj["name"].stringValue,
                                          img: obj["image_url"].stringValue,
                                          rating: obj["rating"].doubleValue,
                                          distance: Int(obj["distance"].doubleValue/1609),
                                          address: address,
                                          category: String(catString.dropLast()),
                                          phone: obj["display_phone"].stringValue,
                                          price: obj["price"].stringValue,
                                          isClosed: obj["is_closed"].boolValue,
                                          link: obj["url"].stringValue
                    )
                    searchRes.append(rest)
                    
                    index += 1
                }
                
                finished = true
            }
        }
    }
    
    func formChange(){
        print("in form change")
        if(keyword.isEmpty || distance.isEmpty || (location.isEmpty && !autoLoc) || Int(distance) == nil){
            subDsbl = true
            print("disabled")
        }
        else {
            print("enabled")
            subDsbl = false
        }
            
    }
    
    func getLocation() {
        print("autoLoc: "+String(autoLoc))
        if(autoLocVal == ""){
            print("in get request")
            AF.request("https://ipinfo.io/json?token=2747365f68142d").validate().responseJSON { response in
                if let data = response.data {
                    print("parse data")
                    let json = JSON(data)
                    print("in getLocation(): " + json["loc"].stringValue)
                    autoLocVal = json["loc"].stringValue
                    print("autolocVal in getLocation(): " + autoLocVal)
                }
            }
        }
        else {
            print("auto loc is off")
        }
        formChange()
    }
}

struct RestaurantRow: View {
    var restaurant: Restaurant

    var body: some View {
        HStack {
            Spacer()
            Text(String(restaurant.ind))
                .frame(alignment: .leading)
            Spacer()
            KFImage(URL(string: restaurant.img)!)
            
                .resizable()
                .aspectRatio(nil, contentMode: .fit)
                .cornerRadius(10)
                .frame(width: 50, alignment: .leading)

            Spacer()
            Text(restaurant.name)
                .frame(alignment: .leading)
            Spacer()
            Text(String(restaurant.rating))
                .frame(alignment: .leading)
            Spacer()
            Text(String(restaurant.distance))
                .frame(alignment: .leading)
        }
    }
}

struct Restaurant: Identifiable, Hashable {
    
    var id = UUID()
    var ind: Int
    var alias: String
    var name: String
    var img: String
    var rating: Double
    var distance: Int
    var address: String
    var category: String
    var phone: String
    var price: String
    var isClosed: Bool
    var link: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BusinessSearchView()
    }
}
