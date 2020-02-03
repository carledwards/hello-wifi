//
//  IOTBluetooth.swift
//  HelloWifi
//
//  Created by Carl Edwards on 2/2/20.
//  Copyright © 2020 Bengalbot. All rights reserved.
//

import Foundation

enum ConnectedState {
  case idle // bluetooth is off/disabled
  case scanning // searching for BLE device
  case connecting // BLE found, attaching to services
  case connected // fully connected and ready
}

enum OutgoingCommands: UInt8 {
  case wifiConnectionStatus = 0x00
  case scanNetwork = 0x01
  case deleteSsidCredentials = 0x02
  case setSsidConnectionCredentials = 0x03
}

enum IncomingCommands: UInt8 {
  case wifiConnectionStatus = 0x70
  case ssidName = 0x71
  case networkScanSsid = 0x72
}

enum ConnectionStatus: UInt8, CustomStringConvertible {
  case idle = 0x00 // no connection and no activity
  case connecting = 0x01 // connecting in progress
  case wrongPassword = 0x02 // failed due to incorrect password
  case noApFound = 0x03 // failed because no access point replied
  case connectFail = 0x04 // failed due to other problems
  case gotIp = 0x05 // connection successful
  
  var description: String {
    switch self {
    case .idle: return "Not Setup"
    case .connecting: return "Connecting to access point"
    case .wrongPassword: return "Incorrect password"
    case .noApFound: return "Access point not found"
    case .connectFail: return "Failed (unknown reason)"
    case .gotIp: return "Connected"
    }
  }
}

extension String: Identifiable {
  public var id: String {
    return self
  }
}

class MicropythonBluetooth : ObservableObject {
  @Published var connectionState: ConnectedState = ConnectedState.idle
  @Published var networkSsids: [String] = []
  @Published var remoteSsidName: String? = nil
  @Published var remoteConnectionStatus: ConnectionStatus = .idle
  private var simpleBluetoothIO: SimpleBluetoothIO
  private var enabled = false
  
  init() {
    simpleBluetoothIO = SimpleBluetoothIO(serviceUUID: "CA55E77E")
  }
  
  func enable() {
    if !enabled {
      enabled = true
      self.connectionState = .scanning
      self.simpleBluetoothIO.startScan(
        onPeripheralFound: self.peripheralFound, onPeripheralConnected: self.peripheralConnected, onValueChanged: self.remoteValueChanged)
    }
  }
  
  func disable() {
    self.connectionState = ConnectedState.idle
    self.simpleBluetoothIO.stopScan()
    enabled = false
  }
  
  func refreshStatus() {
    self.sendOutgoingCommand(.wifiConnectionStatus)
  }
  
  func scanForNetworks() {
    self.sendOutgoingCommand(.scanNetwork)
  }
  
  func setAPCredentials(ssid: String, password: String?) {
    var data = Data()
    
    // add the command
    data.append(OutgoingCommands.setSsidConnectionCredentials.rawValue)
    
    // add the SSID
    var arrayData = Array(ssid.utf8)
    data.append(Data(bytes:arrayData, count: arrayData.count))
    data.append(0x00)
    
    // add the optional Password
    if let pwd = password {
      arrayData = Array(pwd.utf8)
      data.append(Data(bytes:arrayData, count: arrayData.count))
    }

    self.simpleBluetoothIO.writeData(data: data)
  }
  
  private func sendOutgoingCommand(_ command: OutgoingCommands) -> Void {
    let command: Int8 = Int8(command.rawValue)
    self.simpleBluetoothIO.writeValue(value: command)
  }
  
  private func peripheralFound() -> Void {
    print("peripheralFound")
    connectionState = ConnectedState.connecting
  }
  
  private func peripheralConnected() -> Void {
    print("peripheralConnected")
    connectionState = ConnectedState.connected
    
    // TODO: if I do not add the delay, the return value from sending
    // the refresh status never makes it to the call back
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.refreshStatus()
      // TODO: while ok to do on connect, when trying to use the @Publish for the names,
      // the events are not published for the array for SSID names.
      self.scanForNetworks()
    }
  }
  
  private func remoteValueChanged(_ data: Data) -> Void {
    if data.count == 0 {
      return
    }
    let incomingCommand = data[0]
    switch incomingCommand {
    case IncomingCommands.networkScanSsid.rawValue:
      print("received: IncomingCommands.networkScanSsid")
      if data.count > 1 {
        if let name = String(bytes: data[1...], encoding: .utf8) {
          if !self.networkSsids.contains(name) {
            self.networkSsids.append(name)
          }
        }
      }
    case IncomingCommands.ssidName.rawValue:
      print("received: IncomingCommands.ssidName")
      if data.count > 1 {
        if let name = String(bytes: data[1...], encoding: .utf8) {
          remoteSsidName = name
        }
      }
      else {
        remoteSsidName = nil
      }
    case IncomingCommands.wifiConnectionStatus.rawValue:
      print("received: IncomingCommands.wifiConnectionStatus, data: \(data[1])")
      remoteConnectionStatus = ConnectionStatus.init(rawValue: data[1]) ?? .idle
    default:
      print("unhandled incomming command: \(incomingCommand)")
    }
  }
}
