import SwiftUI
import MessageUI

/// Wraps MFMailComposeViewController for SwiftUI: prefills the bug report and reports
/// the result so the presenter can dismiss. Present only when canSendMail() is true.
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let imageData: Data?
    var onFinish: (MFMailComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([BugReport.supportEmail])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        if let imageData {
            controller.addAttachmentData(imageData, mimeType: "image/jpeg",
                                         fileName: "screenshot.jpg")
        }
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (MFMailComposeResult) -> Void

        init(onFinish: @escaping (MFMailComposeResult) -> Void) { self.onFinish = onFinish }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            onFinish(result)
        }
    }
}
