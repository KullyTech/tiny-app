//
// ShareSheet.swift
// Tiny
//
// Created by Benedictus Yogatama Favian Satyajati on 03/11/25.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
  var activityItems: [Any]
  var applicationActivities: [UIActivity]?

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: applicationActivities
    )
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    // Nothing to update here
  }
}
