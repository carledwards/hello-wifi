# hello-wifi

The goal of this project is to try different ways to provide a Micropython microcontroller the wifi credentials without having a UI or keyboard on the device.

For the microcontroller I am using the [MakerFocus ESP32 Development Board](https://www.amazon.com/gp/product/B076KJZ5QM/ref=ppx_yo_dt_b_asin_title_o03_s01) running Micropython version `esp32-idf3-20200125-v1.12-87-g96716b46e`.  When a mobile component is being used, I am using iOS.

These tests are to help me in my own projects, making frictionless connectivity setup, as well as, to learn more about new/different technologies and how they perform under normal and edge cases.

I will update this page as new tests are performed.

## Tests

### BLE

Using BLE, the test was to have the microcontroller coordinate with an iOS app to perform the following functions:

1. Get the status of the microcontroller's connection to the access point
2. Get the list of access points (iOS does not allow this, the microcontroller will perform the scan and send the list to the iOS app)
3. Allow the iOS app to send the credentials to the microcontroller

