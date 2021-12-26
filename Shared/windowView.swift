//
//  windowView.swift
//  Aibmoe
//
//  Created by Lakr Aream on 2021/12/25.
//

import SwiftUI

#if canImport(AppKit)

    import SwiftAmbiguousPNGPacker

    struct windowView: View {
        @State var appleImage: NSImage? = nil
        @State var otherImage: NSImage? = nil
        @State var outputImage: NSImage? = nil

        @State var showProgressBar: Bool = false
        @State var showSaveButton: Bool = false

        var body: some View {
            HStack {
                makeButton(titleImage: "applelogo") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.beginSheetModal(for: NSApplication.shared.keyWindow!) { response in
                        guard response == .OK else {
                            return
                        }
                        guard let image = NSImage(contentsOfFile: panel.url?.path ?? "/") else {
                            return
                        }
                        appleImage = image
                    }
                }
                .makeOverlayImage(with: appleImage)
                .padding()

                makeButton(titleImage: "pc") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.beginSheetModal(for: NSApplication.shared.keyWindow!) { response in
                        guard response == .OK else {
                            return
                        }
                        guard let image = NSImage(contentsOfFile: panel.url?.path ?? "/") else {
                            return
                        }
                        otherImage = image
                    }
                }
                .makeOverlayImage(with: otherImage)
                .padding()

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(4)

                if let outputImage = outputImage {
                    Image(nsImage: outputImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128, height: 128)
                        .cornerRadius(4)
                        .opacity(0.5)
                        .padding()
                        .overlay(
                            Button {
                                let savePanel = NSSavePanel()
                                savePanel.nameFieldStringValue = "magic.png"
                                savePanel.beginSheetModal(for: NSApplication.shared.keyWindow!) { result in
                                    if result == .OK, let url = savePanel.url {
                                        try? outputImage.obtainPNGData().write(to: url)
                                    }
                                }
                            } label: {
                                Rectangle()
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .overlay(
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 24, weight: .thin, design: .rounded))
                                    )
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(showSaveButton ? 1 : 0)
                        )
                        .onHover { hover in
                            showSaveButton = hover
                        }
                } else {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 50, weight: .thin, design: .rounded))
                        .opacity(0.5)
                        .padding()
                }
            }

            .animation(.interactiveSpring(), value: appleImage)
            .animation(.interactiveSpring(), value: otherImage)
            .animation(.interactiveSpring(), value: outputImage)
            .animation(.interactiveSpring(), value: showSaveButton)

            .onChange(of: appleImage) { _ in
                compile()
            }
            .onChange(of: otherImage) { _ in
                compile()
            }

            .sheet(isPresented: $showProgressBar, onDismiss: nil) {
                ProgressView()
                    .padding()
            }
        }

        func compile() {
            guard let appleImage = appleImage,
                  let otherImage = otherImage
            else {
                return
            }

            showProgressBar = true

            DispatchQueue.global().async {
                let temp = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("wiki.qaq.Aibmoe")
                try? FileManager
                    .default
                    .createDirectory(at: temp, withIntermediateDirectories: true, attributes: nil)
                let appleUrl = temp
                    .appendingPathComponent("apple.img.png")
                let otherUrl = temp
                    .appendingPathComponent("other.img.png")

                let appleData = appleImage.obtainPNGData()
                let otherData = otherImage.obtainPNGData()

                try? appleData.write(to: appleUrl)
                try? otherData.write(to: otherUrl)

                let output = temp
                    .appendingPathComponent("output.img.png")

                try? SwiftAmbiguousPNGPacker()
                    .pack(
                        appleImageURL: appleUrl,
                        otherImageURL: otherUrl,
                        outputURL: output
                    )

                guard let outImg = NSImage(contentsOfFile: output.path) else {
                    return
                }

                DispatchQueue.main.async {
                    showProgressBar = false
                    outputImage = outImg
                }
            }
        }

        func makeButton(
            titleImage: String,
            size: CGSize = CGSize(width: 128, height: 128),
            action: @escaping () -> Void
        ) -> some View {
            Button {
                action()
            } label: {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.1))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        Image(systemName: "square.and.arrow.down.on.square.fill")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    )
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
            .overlay(
                ZStack {
                    Circle()
                        .foregroundColor(Color(NSColor.textBackgroundColor))
                        .frame(width: 30, height: 30)
                    Image(systemName: titleImage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .offset(x: size.width / 2, y: 0 - size.height / 2)
            )
        }
    }

    extension View {
        func makeOverlayImage(with image: NSImage?, size: CGSize = CGSize(width: 100, height: 100)) -> AnyView {
            if let image = image {
                return AnyView(
                    overlay(
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size.width, height: size.height)
                    )
                )
            } else {
                return AnyView(self)
            }
        }
    }

    struct windowView_Previews: PreviewProvider {
        static var previews: some View {
            windowView()
        }
    }

    extension NSImage {
        func obtainPNGData() -> Data {
            guard let tiffRepresentation = self.tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
                return Data()
            }
            let pngData = bitmapImage.representation(using: .png, properties: [:])
            return pngData!
        }
    }

#endif
