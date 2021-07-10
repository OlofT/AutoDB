// swift-tools-version:5.3
import PackageDescription

var package = Package(
    name: "AutoDB",
    //CXShim should allow backporting + linux so we shouldn't need to worry. But it doesn't!
    //platforms: [
    //    .macOS(.v10_15), .iOS(.v13), .tvOS(.v13)
    //],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AutoDB",
            targets: ["AutoDB"]),
    ],
    dependencies: [
        //This allows us to backport to older versions and Linux/Android
        .package(url: "https://github.com/cx-org/CXShim", .upToNextMinor(from: "0.4.0")),
        
        //use a subset of GRDB to port to linux
        .package(name: "GRDB", url: "https://github.com/OlofT/GRDB.swift", .branch("Android")),
        
        //.package(url: "https://github.com/ahti/SQLeleCoder.git", from: "0.0.1"),
        //This doesn't load, why?
        //.package(url: "https://github.com/apple/swift-collections.git", from: "0.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AutoDB",
            dependencies: ["CXShim", "GRDB"]),
        .testTarget(
            name: "AutoDBTests",
            dependencies: ["AutoDB"]),
    ]
)

/* GRDB
targets: [
        .systemLibrary(
            name: "CSQLite",
            providers: [.apt(["libsqlite3-dev"])]),
        .target(
            name: "GRDB",
            dependencies: ["CSQLite"],
            path: "GRDB"),
        .testTarget(
            name: "GRDBTests",
            dependencies: ["GRDB"],
            path: "Tests",
            exclude: [
                "CocoaPods",
                "CustomSQLite",
                "Crash",
                "Performance",
                "SPM",
            ])
    ],
    swiftLanguageVersions: [.v5]
*/

// MARK: - Config Package

#if canImport(Combine)
//if we are using regular Combine we must restrict to this - but we don't have to!
    package.platforms = [.macOS("10.15"), .iOS("13.0"), .tvOS("13.0"), .watchOS("6.0")]
#endif
