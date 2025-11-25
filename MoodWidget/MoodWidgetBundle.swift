//
//  MoodWidgetBundle.swift
//  MoodWidget
//
//  Created by Tm Revanza Narendra Pradipta on 25/11/25.
//

import WidgetKit
import SwiftUI

@main
struct MoodWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoodWidget()
        MoodWidgetControl()
        MoodWidgetLiveActivity()
    }
}
