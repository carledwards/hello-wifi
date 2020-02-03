//
//  LazyView.swift
//  HelloWifi
//
//  Created by Carl Edwards on 2/2/20.
//  Copyright © 2020 Bengalbot. All rights reserved.
//

import SwiftUI

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
