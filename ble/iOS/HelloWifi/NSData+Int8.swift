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
import Foundation

extension Data {
  static func dataWithValue(value: Int8) -> Data {
    var variableValue = value
    return Data(buffer: UnsafeBufferPointer(start: &variableValue, count: 1))
  }
  
  func int8Value() -> Int8 {
    return Int8(bitPattern: self[0])
  }
}
