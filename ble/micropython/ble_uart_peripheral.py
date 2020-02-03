# Modified example from micropython: This example demonstrates a peripheral implementing the Nordic UART Service (NUS).

import bluetooth
from ble_advertising import advertising_payload
import network

from micropython import const
_IRQ_CENTRAL_CONNECT                 = const(1 << 0)
_IRQ_CENTRAL_DISCONNECT              = const(1 << 1)
_IRQ_GATTS_WRITE                     = const(1 << 2)

_UART_UUID = None
_UART_TX = None
_UART_RX = None
_UART_SERVICE = None
_CONNECTION_SSID = None
_CONNECTION_PASSWORD = None

# org.bluetooth.characteristic.gap.appearance.xml
_ADV_APPEARANCE_GENERIC_COMPUTER = const(128)

class BLEUART:
    def __init__(self, ble, name='mpy-uart', rxbuf=100, services=None):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(handler=self._irq)
        ((self._tx_handle, self._rx_handle,),) = self._ble.gatts_register_services((_UART_SERVICE,))
        # Increase the size of the rx buffer and enable append mode.
        self._ble.gatts_set_buffer(self._rx_handle, rxbuf, True)
        self._connections = set()
        self._rx_buffer = bytearray()
        self._handler = None
        # Optionally add services=[_UART_UUID], but this is likely to make the payload too large.
        self._payload = advertising_payload(name=name, services=services, appearance=_ADV_APPEARANCE_GENERIC_COMPUTER)
        self._advertise()

    def irq(self, handler):
        self._handler = handler

    def _irq(self, event, data):
        # Track connections so we can send notifications.
        if event == _IRQ_CENTRAL_CONNECT:
            conn_handle, _, _, = data
            self._connections.add(conn_handle)
        elif event == _IRQ_CENTRAL_DISCONNECT:
            conn_handle, _, _, = data
            if conn_handle in self._connections:
                self._connections.remove(conn_handle)
            # Start advertising again to allow a new connection.
            self._advertise()
        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle, = data
            if conn_handle in self._connections and value_handle == self._rx_handle:
                self._rx_buffer += self._ble.gatts_read(self._rx_handle)
                if self._handler:
                    self._handler()

    def any(self):
        return len(self._rx_buffer)

    def read(self, sz=None):
        if not sz:
            sz = len(self._rx_buffer)
        result = self._rx_buffer[0:sz]
        self._rx_buffer = self._rx_buffer[sz:]
        return result

    def write(self, data):
        for conn_handle in self._connections:
            self._ble.gatts_notify(conn_handle, self._tx_handle, data)

    def close(self):
        for conn_handle in self._connections:
            self._ble.gap_disconnect(conn_handle)
        self._connections.clear()

    def _advertise(self, interval_us=500000):
        self._ble.gap_advertise(interval_us, adv_data=self._payload)


class IncomingCommands:
    WIFI_CONNECTION_STATUS = 0x00
    SCAN_NETWORK = 0x01
    DELETE_SSID_CREDENTIALS = 0x02
    SET_SSID_CONNECTION_CREDENTIALS = 0x03

class OutgoingCommands:
    WIFI_CONNECTION_STATUS = 0x70
    SSID_NAME = 0x71
    NETWORK_SCAN_SSID = 0x72

class ConnectionStatus:
    IDLE = 0x00 # no connection and no activity
    CONNECTING = 0x01 # connecting in progress
    WRONG_PASSWORD = 0x02 # failed due to incorrect password
    NO_AP_FOUND = 0x03 # failed because no access point replied
    CONNECT_FAIL = 0x04 # failed due to other problems
    CONNECTED = 0x05 # connection successful 

def connectToWifi(nic):
    global _CONNECTION_PASSWORD, _CONNECTION_SSID
    nic.disconnect()
    #print('SSID:', _CONNECTION_SSID, ', password:', _CONNECTION_PASSWORD)
    if not _CONNECTION_SSID:
        return
    nic.connect(_CONNECTION_SSID, _CONNECTION_PASSWORD)

def runBleCommandProcessor(bleName, serviceUUID, uartUUID):
    import time
    global _UART_RX, _UART_TX, _UART_UUID, _UART_SERVICE

    _UART_UUID = bluetooth.UUID(uartUUID)
    _UART_TX = (bluetooth.UUID(uartUUID), bluetooth.FLAG_NOTIFY,)
    _UART_RX = (bluetooth.UUID(uartUUID), bluetooth.FLAG_WRITE,)
    _UART_SERVICE = (_UART_UUID, (_UART_TX, _UART_RX,),)

    # turn on the ble services
    ble = bluetooth.BLE()
    uart = BLEUART(ble, name=bleName, services=[bluetooth.UUID(serviceUUID)])

    # turn on the network (client mode)
    nic = network.WLAN(network.STA_IF)
    nic.active(True)

    def on_rx():
        global _CONNECTION_PASSWORD, _CONNECTION_SSID
        data = uart.read()
        if data and len(data) > 0:
            command = data[0]
            if command == IncomingCommands.WIFI_CONNECTION_STATUS:
                print('WIFI_CONNECTION_STATUS')
                outbuf = bytearray()
                outbuf.append(OutgoingCommands.WIFI_CONNECTION_STATUS)
                status = nic.status()
                if status == network.STAT_IDLE:
                    outbuf.append(ConnectionStatus.IDLE)
                elif status == network.STAT_CONNECTING:
                    outbuf.append(ConnectionStatus.CONNECTING)
                elif status == network.STAT_WRONG_PASSWORD:
                    outbuf.append(ConnectionStatus.WRONG_PASSWORD)
                elif status == network.STAT_NO_AP_FOUND:
                    outbuf.append(ConnectionStatus.NO_AP_FOUND)
                elif status == network.STAT_GOT_IP:
                    outbuf.append(ConnectionStatus.CONNECTED)
                else:
                    # default fall through.  There are statuses listed 
                    # on the python docs that don't match what is on the
                    # network object (e.g. STAT_HANDSHAKE_TIMEOUT, STAT_BEACON_TIMEOUT
                    # STAT_ASSOC_FAIL)
                    outbuf.append(ConnectionStatus.CONNECT_FAIL)

                uart.write(outbuf)

                # send out the current set SSID name
                outbuf = bytearray()
                outbuf.append(OutgoingCommands.SSID_NAME)
                if _CONNECTION_SSID is not None:
                    for c in _CONNECTION_SSID:
                        outbuf.append(ord(c))
                uart.write(outbuf)

            elif command == IncomingCommands.SCAN_NETWORK:
                print('SCAN_NETWORK')
                access_points = nic.scan()
                for ap in access_points:
                    outbuf = bytearray()
                    outbuf.append(OutgoingCommands.NETWORK_SCAN_SSID)
                    for b in ap[0]: # append the name
                        outbuf.append(b) 
                    uart.write(outbuf)

            elif command == IncomingCommands.DELETE_SSID_CREDENTIALS:
                print('DELETE_SSID_CREDENTIALS')
                _CONNECTION_SSID = None
                _CONNECTION_PASSWORD = None
                connectToWifi(nic)

            elif command == IncomingCommands.SET_SSID_CONNECTION_CREDENTIALS:
                print('SET_SSID_CONNECTION_CREDENTIALS')
                _CONNECTION_SSID = None
                _CONNECTION_PASSWORD = None
                creds = data[1:]

                splitindex = -1
                for i in range(0, len(creds)):
                    if creds[i] == 0x00:
                        splitindex = i
                        break
                if splitindex > 0:
                    name = creds[:splitindex]
                    if len(name) > 0:
                        _CONNECTION_SSID = name.decode('ASCII')
                        password = creds[splitindex+1:]
                        if len(password) > 0:
                            _CONNECTION_PASSWORD = password.decode('ASCII')

                connectToWifi(nic)

            elif command == IncomingCommands.SET_SSID_CONNECTION_PASSWORD:
                print('SET_SSID_CONNECTION_PASSWORD')
                password = data[1:]
                if len(password) > 0:
                    _CONNECTION_PASSWORD = password
                else:
                    _CONNECTION_PASSWORD = None
                connectToWifi(nic)

            else:
                print("Unknow incoming command: ", str(command))

    uart.irq(handler=on_rx)

    try:
        while True:
            time.sleep_ms(1000)
    except KeyboardInterrupt:
        pass

    uart.close()
