import SwiftUI

import AppKit       // for NSSavePanel

func promptUserForPNGSave(completion: @escaping (URL?) -> Void) {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.nameFieldStringValue = "mandelbrot_16k.png"
    panel.begin { response in
        completion(response == .OK ? panel.url : nil)
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            MetalView().frame(minWidth: 1200, minHeight: 800)
            Button("Export Image") {
                promptUserForPNGSave { url in
                    guard let url else { return }           // user cancelled
                    MandelbrotRenderer.shared?.exportCurrentImage(to: url)
                }
            }
        }
    }
}
