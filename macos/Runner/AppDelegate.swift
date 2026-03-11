import Cocoa
import Darwin
import Foundation
import FlutterMacOS

final class SingleInstanceLock {
  private var fileDescriptor: Int32 = -1

  func acquire() -> Bool {
    guard fileDescriptor == -1 else { return true }

    do {
      let fileManager = FileManager.default
      let appSupportDirectory = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      let bundleIdentifier = Bundle.main.bundleIdentifier ?? "dev.aurora.desktop"
      let lockDirectory = appSupportDirectory.appendingPathComponent(
        bundleIdentifier,
        isDirectory: true
      )
      try fileManager.createDirectory(
        at: lockDirectory,
        withIntermediateDirectories: true
      )

      let lockPath = lockDirectory
        .appendingPathComponent("single-instance.lock", isDirectory: false)
        .path
      let descriptor = open(lockPath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
      guard descriptor != -1 else { return true }

      if flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
        close(descriptor)
        return false
      }

      fileDescriptor = descriptor
      return true
    } catch {
      return true
    }
  }

  func release() {
    guard fileDescriptor != -1 else { return }
    flock(fileDescriptor, LOCK_UN)
    close(fileDescriptor)
    fileDescriptor = -1
  }

  func activateExistingInstance() {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

    let currentProcessId = ProcessInfo.processInfo.processIdentifier
    let otherInstance = NSRunningApplication
      .runningApplications(withBundleIdentifier: bundleIdentifier)
      .first { $0.processIdentifier != currentProcessId }

    otherInstance?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  private let singleInstanceLock = SingleInstanceLock()

  override func applicationWillFinishLaunching(_ notification: Notification) {
    guard singleInstanceLock.acquire() else {
      singleInstanceLock.activateExistingInstance()
      NSApp.terminate(nil)
      return
    }

    super.applicationWillFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    singleInstanceLock.release()
    super.applicationWillTerminate(notification)
  }
}
