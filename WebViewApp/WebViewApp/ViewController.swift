import UIKit
import WebKit

class ViewController: UIViewController {
    
    private var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadHTMLFile()
    }
    
    private func setupWebView() {
        // Configure WebView
        let configuration = WKWebViewConfiguration()
        
        // Add JavaScript message handler for notifications
        let userContentController = WKUserContentController()
        userContentController.add(NotificationManager.shared, name: "pushNotification")
        configuration.userContentController = userContentController
        
        // Allow media playback
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Create WebView
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add WebView to view
        view.addSubview(webView)
        
        // Set constraints to fill entire screen
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Enable scrolling
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
    }
    
    private func loadHTMLFile() {
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html"),
              let htmlContent = try? String(contentsOfFile: htmlPath) else {
            print("Could not load HTML file")
            return
        }
        
        let baseURL = URL(fileURLWithPath: htmlPath).deletingLastPathComponent()
        webView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView failed to load: \(error)")
    }
}

// MARK: - WKUIDelegate
extension ViewController: WKUIDelegate {
    
    // Handle file input (camera/photo library)
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        
        let alertController = UIAlertController(title: "Select Source", message: nil, preferredStyle: .actionSheet)
        
        // Camera option
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera, completionHandler: completionHandler)
            })
        }
        
        // Photo Library option
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alertController.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
                self.presentImagePicker(sourceType: .photoLibrary, completionHandler: completionHandler)
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        
        // For iPad
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = webView
            popover.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alertController, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType, completionHandler: @escaping ([URL]?) -> Void) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = ["public.image", "public.movie"]
        imagePicker.allowsEditing = false
        
        imagePicker.completionHandler = completionHandler
        
        present(imagePicker, animated: true)
    }
}

// MARK: - UIImagePickerController Extension
extension UIImagePickerController {
    private struct AssociatedKeys {
        static var completionHandler = "completionHandler"
    }
    
    var completionHandler: (([URL]?) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.completionHandler) as? ([URL]?) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.completionHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            delegate = self
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension UIImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var urls: [URL] = []
        
        if let imageURL = info[.imageURL] as? URL {
            urls.append(imageURL)
        } else if let mediaURL = info[.mediaURL] as? URL {
            urls.append(mediaURL)
        } else if let image = info[.originalImage] as? UIImage {
            // Save image to temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "temp_image_\(Date().timeIntervalSince1970).jpg"
            let tempURL = tempDir.appendingPathComponent(fileName)
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try? imageData.write(to: tempURL)
                urls.append(tempURL)
            }
        }
        
        picker.dismiss(animated: true) {
            picker.completionHandler?(urls.isEmpty ? nil : urls)
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            picker.completionHandler?(nil)
        }
    }
}

