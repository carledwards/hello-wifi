
import ble_uart_peripheral

def run():
    ble_uart_peripheral.runBleCommandProcessor(
        'HelloWifi ESP32', 
        b'\x7E\xE7\x55\xCA', 
        '19B10010-E8F2-537E-4F6C-D104768A1214'
        )

