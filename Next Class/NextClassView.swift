//
//  NextClassView.swift
//  Next ClassExtension
//
//  Created by 戴元平 on 9/18/20.
//  Copyright © 2020 David. All rights reserved.
//

import SwiftUI

struct NextClassView: View {
    @State var nextClass: ClassDetail
    var body: some View {
        VStack(spacing: 20) {
            Text("Next Class")
                .foregroundColor(.white)
                .font(.headline)
            
            Text(nextClass.className)
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if nextClass.roomNumber != nil {
                Text(nextClass.roomNumber!)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .font(.caption)
            }
        }
    }
}

struct NextClassView_Previews: PreviewProvider {
    static var previews: some View {
        NextClassView(nextClass: ClassDetail(className: "Test", imagePath: nil, roomNumber: "Test room"))
    }
}
