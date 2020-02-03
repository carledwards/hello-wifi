//
//  SetupWifi.swift
//  HelloWifi
//
//  Created by Carl Edwards on 1/31/20.
//  Copyright © 2020 Bengalbot. All rights reserved.
//

import SwiftUI

struct SetupWifi: View {
  @EnvironmentObject var bluetooth: MicropythonBluetooth
  @State private var selectedSsid = ""
  @State private var password = ""
    
  var body: some View {
    VStack {
      Picker(selection: $selectedSsid, label: Text("Choose SSID")) {
        ForEach(self.bluetooth.networkSsids.sorted {
        $0.caseInsensitiveCompare($1) == .orderedAscending }) { ssid in
          Text(ssid)
        }
      }
      SecureField("Enter SSID Password", text: $password)
      Button(action: {
        self.bluetooth.setAPCredentials(ssid: self.selectedSsid, password: self.password)
        }, label: { Text("Save") }).padding()
    }
    .padding()
    .navigationBarTitle("Setup Wifi")
    .onAppear(perform: {self.bluetooth.scanForNetworks()})
  }
}
