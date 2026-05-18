import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {
  private let runnerBundleId = "com.aurora.aurora"

  func testRunnerBundleLoadsInsideHostApplication() {
    let loadedBundleIds = Bundle.allBundles.compactMap(\.bundleIdentifier)
    XCTAssertTrue(
      loadedBundleIds.contains(runnerBundleId),
      "Runner host bundle should be loaded when unit tests run."
    )
  }

  func testFlutterEngineCanBeConstructed() {
    let engine = FlutterEngine(name: "runner-tests-engine")
    XCTAssertNotNil(engine.binaryMessenger)
  }
}
