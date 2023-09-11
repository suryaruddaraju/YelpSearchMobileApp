//
//  ReservationsView.swift
//  YelpBusinessSearch
//
//  Created by Surya Ruddaraju on 12/8/22.
//

import SwiftUI

struct ReservationsView: View {
    @State var myRes = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
    
    var body: some View {
        NavigationView{
            List{
                ForEach(myRes, id: \.self){ res in
                    HStack{
                        ForEach(res, id: \.self) { resItem in
                            Text(resItem)
                                .font(.system(size: 10))
                            Spacer()
                            
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            Spacer()
        }
        .navigationTitle("Your Reservations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear{
            myRes = UserDefaults.standard.object(forKey: "reservations") as? [[String]] ?? []
            print(myRes)
        }
    }
    
    func delete(at offsets: IndexSet) {
        myRes.remove(atOffsets: offsets)
        UserDefaults.standard.set(myRes, forKey: "reservations")
    }
}

struct ReservationsView_Previews: PreviewProvider {
    static var previews: some View {
        ReservationsView()
    }
}
