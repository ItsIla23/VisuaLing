//
//  VideoInput.swift
//  AppDevelopmentWS
//
//  Created by Ilaria Poziello on 19/02/24.
//

import SwiftUI

struct FrameView: View {
    
    var image: CGImage?
    private let label = Text("frame")
    
    var body: some View {
        VStack {
            if let image = image {
                Image (image, scale:
                        1.0, orientation: .up, label: label)
            } else {
                Color.white
            }
        }
        
    }
}

struct FrameView_Previews: PreviewProvider {
    static var previews: some View {
        FrameView()
    }
}

