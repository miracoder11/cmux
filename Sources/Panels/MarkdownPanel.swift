import Foundation
import Combine

enum MarkdownPanelRenderMode: Sendable, Equatable {
    case markdown
    case image
    case code
    case plainText
}

/// A panel that renders a file with live file-watching.
/// Markdown uses MarkdownUI, code/text use the syntax preview path, and images
/// use a native image preview.
@MainActor
final class MarkdownPanel: Panel, ObservableObject {
    let id: UUID
    let panelType: PanelType = .markdown

    /// Absolute path to the file being displayed.
    @Published private(set) var filePath: String

    /// How the file content should be rendered.
    @Published private(set) var renderMode: MarkdownPanelRenderMode

    /// Single-click file explorer previews are reused until committed.
    @Published private(set) var isPreview: Bool

    /// The workspace this panel belongs to.
    private(set) var workspaceId: UUID

    /// Current file content read from disk for text-like render modes.
    @Published private(set) var content: String = ""

    /// Title shown in the tab bar (filename).
    @Published private(set) var displayTitle: String = ""

    /// SF Symbol icon for the tab bar.
    var displayIcon: String? {
        switch renderMode {
        case .markdown: return "doc.richtext"
        case .image: return "photo"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .plainText: return "doc.text"
        }
    }

    /// Whether the file has been deleted or is unreadable.
    @Published private(set) var isFileUnavailable: Bool = false

    /// Token incremented to trigger focus flash animation.
    @Published private(set) var focusFlashToken: Int = 0

    // MARK: - File watching

    // nonisolated(unsafe) because deinit is not guaranteed to run on the
    // main actor, but DispatchSource.cancel() is thread-safe.
    private nonisolated(unsafe) var fileWatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var isClosed: Bool = false
    private var fileWatchGeneration: UInt64 = 0
    private let watchQueue = DispatchQueue(label: "com.cmux.markdown-file-watch", qos: .utility)

    /// Maximum number of reattach attempts after a file delete/rename event.
    private static let maxReattachAttempts = 6
    /// Delay between reattach attempts (total window: attempts * delay = 3s).
    private static let reattachDelay: TimeInterval = 0.5

    // MARK: - Init

    init(workspaceId: UUID, filePath: String, isPreview: Bool = false) {
        let standardizedPath = URL(fileURLWithPath: filePath).standardizedFileURL.path
        self.id = UUID()
        self.workspaceId = workspaceId
        self.filePath = standardizedPath
        self.renderMode = Self.renderMode(for: standardizedPath)
        self.isPreview = isPreview
        self.displayTitle = (standardizedPath as NSString).lastPathComponent

        loadFileContent()
        startFileWatcher()
        if isFileUnavailable && fileWatchSource == nil {
            // Session restore can create a panel before the file is recreated.
            // Retry briefly so atomic-rename recreations can reconnect.
            scheduleReattach(attempt: 1, generation: fileWatchGeneration)
        }
    }

    private static func renderMode(for filePath: String) -> MarkdownPanelRenderMode {
        let ext = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        switch ext {
        case "md", "markdown", "mdown", "mkd", "mdx":
            return .markdown
        case "apng", "avif", "bmp", "gif", "heic", "heif", "icns", "ico", "jpeg", "jpg", "png", "tif", "tiff", "webp":
            return .image
        case "txt", "text":
            return .plainText
        default:
            return .code
        }
    }

    func replaceFile(path: String, keepPreview: Bool = true) {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let nextMode = Self.renderMode(for: standardizedPath)
        guard standardizedPath != filePath || nextMode != renderMode else {
            if keepPreview {
                isPreview = true
            } else {
                commitPreview()
            }
            return
        }

        fileWatchGeneration &+= 1
        stopFileWatcher()
        filePath = standardizedPath
        renderMode = nextMode
        isPreview = keepPreview
        displayTitle = (standardizedPath as NSString).lastPathComponent
        content = ""
        isFileUnavailable = false
        loadFileContent()
        startFileWatcher()
        if isFileUnavailable && fileWatchSource == nil {
            scheduleReattach(attempt: 1, generation: fileWatchGeneration)
        }
    }

    func commitPreview() {
        guard isPreview else { return }
        isPreview = false
    }

    // MARK: - Panel protocol

    func focus() {
        // Markdown panel is read-only; no first responder to manage.
    }

    func unfocus() {
        // No-op for read-only panel.
    }

    func close() {
        isClosed = true
        fileWatchGeneration &+= 1
        stopFileWatcher()
    }

    func triggerFlash(reason: WorkspaceAttentionFlashReason) {
        _ = reason
        guard NotificationPaneFlashSettings.isEnabled() else { return }
        focusFlashToken += 1
    }

    // MARK: - File I/O

    private func loadFileContent() {
        if renderMode == .image {
            isFileUnavailable = !FileManager.default.fileExists(atPath: filePath)
            content = ""
            return
        }

        do {
            let newContent = try String(contentsOfFile: filePath, encoding: .utf8)
            content = Self.formattedContent(newContent, for: filePath)
            isFileUnavailable = false
        } catch {
            // Fallback: try ISO Latin-1, which accepts all 256 byte values,
            // covering legacy encodings like Windows-1252.
            if let data = FileManager.default.contents(atPath: filePath),
               let decoded = String(data: data, encoding: .isoLatin1) {
                content = Self.formattedContent(decoded, for: filePath)
                isFileUnavailable = false
            } else {
                isFileUnavailable = true
            }
        }
    }

    private static func formattedContent(_ content: String, for filePath: String) -> String {
        let ext = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        guard ext == "json",
              let data = content.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let pretty = String(data: prettyData, encoding: .utf8) else {
            return content
        }
        return pretty
    }

    // MARK: - File watcher via DispatchSource

    private func startFileWatcher() {
        guard fileWatchSource == nil else { return }
        let fd = open(filePath, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: watchQueue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                // File was deleted or renamed. The old file descriptor points to
                // a stale inode, so we must always stop and reattach the watcher
                // even if the new file is already readable (atomic save case).
                DispatchQueue.main.async {
                    self.fileWatchGeneration &+= 1
                    let generation = self.fileWatchGeneration
                    self.stopFileWatcher()
                    self.loadFileContent()
                    if self.isFileUnavailable {
                        // File not yet replaced - retry until it reappears.
                        self.scheduleReattach(attempt: 1, generation: generation)
                    } else {
                        // File already replaced - reattach to the new inode immediately.
                        self.startFileWatcher()
                    }
                }
            } else {
                // Content changed - reload.
                DispatchQueue.main.async {
                    self.loadFileContent()
                }
            }
        }

        source.setCancelHandler {
            Darwin.close(fd)
        }

        source.resume()
        fileWatchSource = source
    }

    /// Retry reattaching the file watcher up to `maxReattachAttempts` times.
    /// Each attempt checks if the file has reappeared. Bails out early if
    /// the panel has been closed or reused for another path.
    private func scheduleReattach(attempt: Int, generation: UInt64) {
        guard attempt <= Self.maxReattachAttempts else { return }
        watchQueue.asyncAfter(deadline: .now() + Self.reattachDelay) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                guard !self.isClosed, self.fileWatchGeneration == generation else { return }
                if FileManager.default.fileExists(atPath: self.filePath) {
                    self.isFileUnavailable = false
                    self.loadFileContent()
                    self.startFileWatcher()
                } else {
                    self.scheduleReattach(attempt: attempt + 1, generation: generation)
                }
            }
        }
    }

    private func stopFileWatcher() {
        if let source = fileWatchSource {
            source.cancel()
            fileWatchSource = nil
        }
        // File descriptor is closed by the cancel handler.
        fileDescriptor = -1
    }

    deinit {
        // DispatchSource cancel is safe from any thread.
        fileWatchSource?.cancel()
    }
}
