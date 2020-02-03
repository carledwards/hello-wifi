//
//  Home.swift
//  HelloWifi
//
//  Created by Carl Edwards on 1/31/20.
//  Copyright © 2020 Bengalbot. All rights reserved.
//

import SwiftUI

struct Home: View {
  @EnvironmentObject var bluetooth: MicropythonBluetooth
  
  var body: some View {
    NavigationView {

      VStack {
        if bluetooth.connectionState == .connected {
          VStack {
            Form {
              Section(header: Text("BLE Device Settings")) {
                HStack {
                  Text("Wifi Status")
                  Spacer()
                  Text("\(bluetooth.remoteConnectionStatus.description)")
                }
                NavigationLink(destination: LazyView(SetupWifi())) {
                  HStack {
                    Text("SSID")
                    Spacer()
                    Text("\(bluetooth.remoteSsidName ?? "<not set>")")
                  }
                }
              }
            }
            Button(action: {
              self.bluetooth.refreshStatus()
            }) {Text("Refresh")}.padding()
            Button(action: {
              self.bluetooth.disable()
            }) {Text("Disconnect")}.padding()
          }
        }
        else if bluetooth.connectionState == .connecting {
          Text("Found BLE device, connecting...")
        }
        else if bluetooth.connectionState == .scanning {
          VStack {
            Text("Searching for BLE device...")
            ActivityIndicator(isAnimating: .constant(true), style: .large)
          }
        }
        else {
            Button(action: {
              self.bluetooth.enable()
            }) {Text("Connect to BLE Device")}.padding()
        }
        EmptyView() // keep the compiler happy by having content ouside of the 'if' statements
      }
      .navigationBarTitle("Hello-Wifi")
    }
  }
}

