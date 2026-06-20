import SwiftUI
import PhotosUI
import MessageUI
import UIKit

/// Report-a-bug dialog: a description + optional screenshot, sent via the native Mail
/// composer (with a no-Mail fallback). Content-hugging detent like ExportSheet.
struct BugReportSheet: View {
    @Environment(\.blurPopupClose) private var close

    @State private var description = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingMail = false
    @State private var showFallback = false

    private var canSend: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sheet(isPresented: $showingMail) {
                MailComposeView(subject: BugReport.subject, body: composedBody(),
                                imageData: imageData) { _ in
                    showingMail = false
                    close()
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { imageData = try? await item?.loadTransferable(type: Data.self) }
            }
    }

    @ViewBuilder private var content: some View {
        if showFallback { fallback } else { form }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Report a bug")
                .font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.ink)
            Text("Tell us what went wrong — the more detail, the faster we can fix it.")
                .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)

            label("WHAT HAPPENED")
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("Describe the issue…")
                        .font(.system(size: 15)).foregroundStyle(Palette.ink40)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                }
                TextEditor(text: $description)
                    .font(.system(size: 15)).foregroundStyle(Palette.ink)
                    .scrollContentBackground(.hidden)
                    .frame(height: 96)
                    .padding(.horizontal, 8).padding(.vertical, 2)
            }
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))

            label("SCREENSHOT · OPTIONAL")
            screenshotRow

            VStack(spacing: 8) {
                Button { send() } label: { Text("Send").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).tint(Palette.accent)
                    .disabled(!canSend)
                Button("Cancel") { close() }.foregroundStyle(Palette.ink60)
            }
        }
    }

    @ViewBuilder private var screenshotRow: some View {
        if let imageData, let image = UIImage(data: imageData) {
            HStack(spacing: 11) {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: 40, height: 52).clipShape(RoundedRectangle(cornerRadius: 7))
                Text("Screenshot").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Replace").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.ink60)
                }
                Button { self.imageData = nil; pickerItem = nil } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.ink40)
                }
            }
            .padding(10)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.ink12, lineWidth: 1))
        } else {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                    Text("Add screenshot").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .overlay(RoundedRectangle(cornerRadius: 13)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(Palette.ink12))
            }
        }
    }

    private var fallback: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No email set up").font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Send your report to \(BugReport.supportEmail).")
                .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = composedBody()
                } label: { Text("Copy report").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).tint(Palette.accent)
                Button("Done") { close() }.foregroundStyle(Palette.ink60)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .semibold)).tracking(0.5)
            .foregroundStyle(Palette.ink40)
    }

    private func send() {
        if MFMailComposeViewController.canSendMail() {
            showingMail = true
        } else {
            showFallback = true
        }
    }

    private func composedBody() -> String {
        let info = Bundle.main.infoDictionary
        let device = UIDevice.current
        let diagnostics = BugReport.Diagnostics(
            appVersion: info?["CFBundleShortVersionString"] as? String ?? "?",
            build: info?["CFBundleVersion"] as? String ?? "?",
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            deviceModel: device.model)
        return BugReport.body(description: description, diagnostics: diagnostics)
    }
}

#if DEBUG
#Preview { BugReportSheet() }
#endif
