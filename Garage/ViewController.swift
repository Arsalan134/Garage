//
//  ViewController.swift
//  Garage
//
//  Created by Arsalan Iravani on 3/28/19.
//  Copyright © 2019 Arsalan Iravani. All rights reserved.
//

import UIKit
import CoreBluetooth

enum Command: Int {
    case close = 0, stop, open, none
}

class ViewController: UIViewController {

    var manager: CBCentralManager? = nil
    var mainCharacteristic: CBCharacteristic? = nil

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var buttonUp: UIButton!
    @IBOutlet weak var buttonStop: UIButton!
    @IBOutlet weak var buttonDown: UIButton!

    var commandToSend: Command = .none

    var peripheral: CBPeripheral? {
        didSet {
            if self.peripheral == nil {
                activityIndicator.startAnimating()
                return
            }
            manager?.connect(self.peripheral!, options: nil)
        }
    }

    let garageServiceUUID = "FFE0"

    override func viewDidLoad() {
        super.viewDidLoad()

        manager = CBCentralManager(delegate: self, queue: nil)
        manager?.delegate = self
        peripheral?.delegate = self
    }

    func setButtons(enabled: Bool) {
        buttonUp.isEnabled = enabled
        buttonStop.isEnabled = enabled
        buttonDown.isEnabled = enabled
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            commandToSend = .open
        case 1:
            commandToSend = .stop
        case 2:
            commandToSend = .close
        default:
            commandToSend = .none
        }

        switch peripheral?.state {
        case .connected?:
            print ("connected")
        case .connecting?:
            print("connecting")
        default:
            break
        }

        guard let dataToSend = "\(commandToSend.rawValue)".data(using: String.Encoding.utf8), let mainCharacteristic = mainCharacteristic else {return}

        if peripheral != nil {
            peripheral?.writeValue(dataToSend, for: mainCharacteristic, type: .withoutResponse)
        } else {
            print("peripheral is nil, command is \(commandToSend)")
        }
    }

}

extension ViewController: CBCentralManagerDelegate {

    func scan() {
        manager?.scanForPeripherals(withServices: [CBUUID.init(string: garageServiceUUID)], options: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn, .resetting:
            print("Bluetooth power on")
            scan()
        default:
            print("Bluetooth power off")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("Connected to", (peripheral.name ?? "no name"), "Command is", commandToSend)
        manager?.stopScan()
        setButtons(enabled: true)
        activityIndicator.stopAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.manager?.cancelPeripheralConnection(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.peripheral = nil
        print("Disconnected", peripheral.name ?? "no name")
        scan()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error ?? "no error")
    }

}

extension ViewController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            if (service.uuid.uuidString == garageServiceUUID) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        for characteristic in service.characteristics ?? [] {
            if (characteristic.uuid.uuidString == "FFE1") {
                mainCharacteristic = characteristic
                peripheral.setNotifyValue(false, for: characteristic)
                print("Found GARAGE Data Characteristic")

                guard let dataToSend = "\(commandToSend.rawValue)".data(using: String.Encoding.utf8),
                    let mainCharacteristic = mainCharacteristic else {
                        return
                    }
                peripheral.writeValue(dataToSend, for: mainCharacteristic, type: .withoutResponse)
                commandToSend = .none
            }
        }
    }
}
