import AccessibilitySnapshot
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AccessibilitySnapshotDemo

/// Tests covering the integration between the core components of AccessibilitySnapshot and SnapshotTesting.
final class SnapshotTestingTests: XCTestCase {
    // MARK: - Tests

    func testSimpleSwiftUIConfiguration() throws {
        assertSnapshot(
            of: SwiftUIView(),
            as: .accessibilityImage(size: UIScreen.main.bounds.size),
            named: nameForDevice()
        )
    }

    func testSimpleSwiftUIWithScrollViewConfiguration() throws {
        assertSnapshot(
            of: SwiftUIViewWithScrollView(),
            as: .accessibilityImage(size: UIScreen.main.bounds.size),
            named: nameForDevice()
        )
    }

    func testSimpleConfiguration() {
        let viewController = ViewAccessibilityPropertiesViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSnapshot(of: viewController, as: .accessibilityImage, named: nameForDevice())
    }

    func testShowingActivationPoint() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds

        assertSnapshot(
            of: viewController,
            as: .accessibilityImage(showActivationPoints: .always),
            named: nameForDevice(baseName: "always")
        )

        assertSnapshot(
            of: viewController,
            as: .accessibilityImage(showActivationPoints: .whenOverridden),
            named: nameForDevice(baseName: "whenOverridden")
        )

        assertSnapshot(
            of: viewController,
            as: .accessibilityImage(showActivationPoints: .never),
            named: nameForDevice(baseName: "never")
        )
    }

    func testUsingMonochromeSnapshot() {
        let view = UILabel()
        view.text = "Hello World"
        view.textColor = .red
        view.sizeToFit()

        assertSnapshot(
            of: view,
            as: .accessibilityImage(useMonochromeSnapshot: false),
            named: nameForDevice(baseName: "false")
        )

        assertSnapshot(
            of: view,
            as: .accessibilityImage(useMonochromeSnapshot: true),
            named: nameForDevice(baseName: "true")
        )
    }

    func testRenderingMethods() {
        let view = UIView()
        view.bounds.size = .init(width: 40, height: 40)
        view.layer.transform = CATransform3DMakeRotation(.pi / 4, 1, 1, 1)
        view.backgroundColor = .red

        view.isAccessibilityElement = true
        view.accessibilityLabel = "Test Element"

        let container = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        view.center = .init(x: 50, y: 50)
        container.addSubview(view)

        assertSnapshot(
            of: container,
            as: .accessibilityImage(drawHierarchyInKeyWindow: false),
            named: nameForDevice(baseName: "false")
        )

        assertSnapshot(
            of: container,
            as: .accessibilityImage(drawHierarchyInKeyWindow: true),
            named: nameForDevice(baseName: "true")
        )
    }

    func testMarkerColors() {
        let view = AccessibleContainerView(count: 8, innerMargin: 10)
        view.sizeToFit()

        assertSnapshot(
            of: view,
            as: .accessibilityImage(),
            named: nameForDevice(baseName: "default")
        )

        assertSnapshot(
            of: view,
            as: .accessibilityImage(markerColors: [.red, .green, .blue]),
            named: nameForDevice(baseName: "custom")
        )
    }

    func testInvertColors() {
        let viewController = InvertColorsViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSnapshot(of: viewController, as: .imageWithSmartInvert, named: nameForDevice())
    }

    func testHitTargets() {
        let viewController = ButtonAccessibilityTraitsViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSnapshot(of: viewController, as: .imageWithHitTargets(), named: nameForDevice())
    }

    func testUIKitTextField() {
        let viewController = TextFieldViewController()
        viewController.view.frame = UIScreen.main.bounds

        assertSnapshot(
            of: viewController,
            as: .accessibilityImage,
            named: nameForDevice()
        )
    }

    func testUIKitTextView() {
        let viewController = TextViewViewController()
        viewController.view.frame = UIScreen.main.bounds

        assertSnapshot(
            of: viewController,
            as: .accessibilityImage,
            named: nameForDevice()
        )
    }

    func testSwiftUITextEntry() {
        let view = SwiftUITextEntry()
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        assertSnapshot(
            of: view,
            as: .accessibilityImage,
            named: nameForDevice()
        )
    }

    func testConcurrentAccessibilitySnapshotsComplete() {
        let snapshotCount = 40
        let snapshotsComplete = expectation(description: "All accessibility snapshots complete")
        snapshotsComplete.expectedFulfillmentCount = snapshotCount

        for index in 0 ..< snapshotCount {
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: 0, width: 240, height: 44)
            button.setTitle("Button \(index)", for: .normal)

            Snapshotting<UIView, UIImage>
                .accessibilityImage(shouldRunInHostApplication: false)
                .snapshot(button)
                .run { image in
                    XCTAssertGreaterThan(image.size.height, button.bounds.height)
                    snapshotsComplete.fulfill()
                }
        }

        wait(for: [snapshotsComplete], timeout: 5)
    }

    func testSwiftUIMenuPublishesAccessibilityBeforeSnapshot() {
        let hostingController = UIHostingController(
            rootView: Menu("All Tickets") {
                Button("Bus ticket") {}
            }
            .frame(width: 240, height: 44)
        )
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 240, height: 44)

        let snapshotComplete = expectation(description: "SwiftUI Menu accessibility snapshot completes")
        Snapshotting<UIView, UIImage>
            .accessibilityImage(shouldRunInHostApplication: false)
            .snapshot(hostingController.view)
            .run { image in
                XCTAssertGreaterThan(image.size.height, hostingController.view.bounds.height)
                snapshotComplete.fulfill()
            }

        wait(for: [snapshotComplete], timeout: 5)
    }

    // MARK: - Private Methods

    private func nameForDevice(baseName: String? = nil) -> String {
        let size = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let version = UIDevice.current.systemVersion
        let deviceName = "\(Int(size.width))x\(Int(size.height))-\(version)-\(Int(scale))x"

        return [baseName, deviceName]
            .compactMap { $0 }
            .joined(separator: "-")
    }
}
