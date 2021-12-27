//
//  WindowView.swift
//  Aibmoe
//
//  Created by Lakr Aream on 2021/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)

import SwiftAmbiguousPNGPacker

extension SwiftAmbiguousPNGPacker.Error: LocalizedError {
    public var errorDescription: String? {
        return "\(self)"  // TODO: localized text
    }
}

struct ImageDropDelegate: DropDelegate {
    @Binding var image: NSImage?
    @Binding var imageURL: URL?

    func urlItemProvider(info: DropInfo) -> NSItemProvider? {
        guard info.hasItemsConforming(to: ["public.file-url"]) else {
            return nil
        }

        let items = info.itemProviders(for: ["public.file-url"])
        guard items.count == 1 else {
            return nil
        }

        return items.first
    }

    func validateDrop(info: DropInfo) -> Bool {
        return urlItemProvider(info: info) != nil
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = urlItemProvider(info: info) else {
            return false
        }

        _ = (provider.copy() as! NSItemProvider).loadObject(ofClass: URL.self) { url, err in
            if let url = url, let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self.image = image
                    self.imageURL = url
                }
            }
        }

        return true
    }
}

struct WindowView: View {

    @State var error: AnyError?
    @State var showAlert = false
    @State var showProgressBar: Bool = false
    @State var showSaveButton: Bool = false

    // Presentation only
    @State var appleImage: NSImage? = nil
    @State var otherImage: NSImage? = nil
    @State var outputImage: NSImage? = nil

    @State var appleImageURL: URL? = nil
    @State var otherImageURL: URL? = nil
    @State var outputImageURL: URL? = nil

    var body: some View {
        HStack {
            makeButton(titleImage: "applelogo") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.beginSheetModal(for: NSApplication.shared.keyWindow!) { response in
                    guard response == .OK, let image = NSImage(contentsOf: panel.url!) else {
                        return
                    }
                    appleImage = image
                    appleImageURL = panel.url
                }
            }
            .makeOverlayImage(with: appleImage)
            .padding()
            .onDrop(
                of: ["public.file-url"],
                delegate: ImageDropDelegate(
                    image: $appleImage,
                    imageURL: $appleImageURL
                )
            )

            makeButton(titleImage: "pc") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.beginSheetModal(for: NSApplication.shared.keyWindow!) { response in
                    guard response == .OK, let image = NSImage(contentsOf: panel.url!) else {
                        return
                    }
                    otherImage = image
                    otherImageURL = panel.url
                }
            }
            .makeOverlayImage(with: otherImage)
            .padding()
            .onDrop(
                of: ["public.file-url"],
                delegate: ImageDropDelegate(
                    image: $otherImage,
                    imageURL: $otherImageURL
                )
            )

            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(4)

            if let outputImage = outputImage, let outputImageURL = outputImageURL {
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
                                    try! FileManager.default.copyItem(at: outputImageURL, to: url)
                                }
                            }
                        } label: {
                            Rectangle()
                                .foregroundColor(Color.white.opacity(0.5))
                                .overlay(
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 24, weight: .semibold, design: .rounded))
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
                    .onDrag {
                        do {
                            let copiedURL = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: outputImageURL, create: true).appendingPathComponent("magic.png")
                            try FileManager.default.copyItem(at: outputImageURL, to: copiedURL)
                            return NSItemProvider(contentsOf: copiedURL)!
                        } catch {
                            DispatchQueue.main.async {
                                showProgressBar = false
                                self.error = AnyError.anyError(error)
                                showAlert = true
                            }
                            return NSItemProvider()
                        }
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

        .onChange(of: appleImageURL) { _ in
            compile()
        }
        .onChange(of: otherImageURL) { _ in
            compile()
        }

        .sheet(isPresented: $showProgressBar, onDismiss: nil) {
            ProgressView()
                .padding()
        }

        .alert(isPresented: $showAlert, error: error) {
            Button("OK") {
                
            }
        }
    }

    func compile() {
        guard let appleImageURL = appleImageURL,
              let otherImageURL = otherImageURL
        else {
            return
        }

        showProgressBar = true

        DispatchQueue.global().async {
            do {
                let tempDirectory = try FileManager.default.url(
                    for: .itemReplacementDirectory,
                       in: .userDomainMask,
                       appropriateFor: appleImageURL,
                       create: true
                )
                let appleURL = tempDirectory
                    .appendingPathComponent("apple.png")
                let otherURL = tempDirectory
                    .appendingPathComponent("other.png")

                try FileManager.default.copyItem(at: appleImageURL, to: appleURL)
                try FileManager.default.copyItem(at: otherImageURL, to: otherURL)

                let outputURL = tempDirectory
                    .appendingPathComponent("output.png")

                try SwiftAmbiguousPNGPacker
                    .shared
                    .pack(
                        appleImageURL: appleURL,
                        otherImageURL: otherURL,
                        outputURL: outputURL
                    )

                guard let outputImage = NSImage(contentsOfFile: outputURL.path) else {
                    return
                }

                DispatchQueue.main.async {
                    showProgressBar = false
                    self.outputImage = outputImage
                    outputImageURL = outputURL
                }
            } catch {
                DispatchQueue.main.async {
                    showProgressBar = false
                    self.error = AnyError.anyError(error)
                    showAlert = true
                }
                return
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
            }.offset(x: size.width / 2, y: 0 - size.height / 2)
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

struct WindowView_Previews: PreviewProvider {
    static var previews: some View {
        WindowView()
    }
}

#endif
