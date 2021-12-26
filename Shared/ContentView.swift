//
//  ContentView.swift
//  Shared
//
//  Created by Lakr Aream on 2021/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        windowView()
        #else
        mobileView()
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
