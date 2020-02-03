/*
 This file has been modifiled from the original to support this project
 but all of the credit goes to Nebojsa Petrovic for pulling this together
 and making this easier to just plug in and go.
 
 Source from: https://github.com/nebs/hello-bluetooth
 
 MIT License

 Copyright (c) 2019 Nebojsa Petrovic

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import CoreBluetooth

class SimpleBluetoothIO: NSObject {
  let serviceUUID: String
  var valueChangedDelegate: ((Data) -> Void)?
  var peripheralFoundDelegate: (() -> Void)?
  var peripheralConnectedDelegate: (() -> Void)?
  
  var centralManager: CBCentralManager!
  var connectedPeripheral: CBPeripheral?
  var targetService: CBService?
  var writableCharacteristic: CBCharacteristic?
  
  var isPoweredOn: Bool = false
  
  init(serviceUUID: String) {
    self.serviceUUID = serviceUUID
    
    super.init()
    
  }

  func stopScan() {
    self.valueChangedDelegate = nil
    self.peripheralFoundDelegate = nil
    self.peripheralConnectedDelegate = nil
    if let cm = centralManager {
      centralManager = nil
      cm.delegate = nil
      if self.isPoweredOn {
        cm.stopScan()
      }
    }
  }

  func startScan(onPeripheralFound peripheralFoundDelegate: @escaping () -> Void,
                 onPeripheralConnected peripheralConnectedDelegate: @escaping () -> Void,
                 onValueChanged valueChangedDelegate: @escaping (_ value: Data) -> Void) {
    stopScan()
    self.peripheralFoundDelegate = peripheralFoundDelegate
    self.peripheralConnectedDelegate = peripheralConnectedDelegate
    self.valueChangedDelegate = valueChangedDelegate
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }
  
  func writeValue(value: Int8) {
    guard let peripheral = connectedPeripheral, let characteristic = writableCharacteristic else {
      return
    }
    
    let data = Data.dataWithValue(value: value)
    peripheral.writeValue(data, for: characteristic, type: .withResponse)
  }
  
  func writeData(data: Data) {
    guard let peripheral = connectedPeripheral, let characteristic = writableCharacteristic else {
      return
    }
    peripheral.writeValue(data, for: characteristic, type: .withResponse)
  }

  func writeString(value: String) {
    guard let peripheral = connectedPeripheral, let characteristic = writableCharacteristic else {
      return
    }

    let bData = Array(value.utf8)
    let data = Data(bytes: bData, count: bData.count)
    peripheral.writeValue(data, for: characteristic, type: .withResponse)
  }

}

extension SimpleBluetoothIO: CBCentralManagerDelegate {
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.discoverServices(nil)
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    connectedPeripheral = peripheral

    if let connectedPeripheral = connectedPeripheral {
      print("connectedPeripheral.identifier.uuidString: \(connectedPeripheral.identifier.uuidString), name: \(String(describing: connectedPeripheral.name))")
        if let peripheralFoundDelegate = peripheralFoundDelegate {
          peripheralFoundDelegate()
        }
        connectedPeripheral.delegate = self
        centralManager.connect(connectedPeripheral, options: nil)
        centralManager.stopScan()
    }
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
      self.isPoweredOn = true
      print("centralManagerDidUpdateState: isPoweredOn is True")
      centralManager.scanForPeripherals(withServices: [CBUUID(string: self.serviceUUID)], options:[
        CBCentralManagerScanOptionAllowDuplicatesKey:false,
      ])
    }
    else {
      print("centralManagerDidUpdateState: isPoweredOn is False")
      self.isPoweredOn = false
    }
  }
}

extension SimpleBluetoothIO: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else {
      return
    }
    
    targetService = services.first
    if let service = services.first {
      targetService = service
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristics = service.characteristics else {
      return
    }
    
    if let peripheralConnectedDelegate = peripheralConnectedDelegate {
      peripheralConnectedDelegate()
    }
    
    for characteristic in characteristics {
      if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
        writableCharacteristic = characteristic
      }
      peripheral.setNotifyValue(true, for: characteristic)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard let data = characteristic.value else {
      return
    }
    
    if let valueChangedDelegate = valueChangedDelegate {
      valueChangedDelegate(data)
    }
  }
}
