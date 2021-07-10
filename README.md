# AutoDB Swift

![Built for Linux, Android, iOS and mac](https://img.shields.io/badge/platform-Linux%20%7C%20iOS%20%7C%20Android%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20-red)

Work in progress...

# Linux / Android

The future is cross-compiling, so ensure things are working around the globe by running tests on Linux:

[Install docker](https://www.docker.com/docker-mac)

Use -e QEMU_CPU=max on m1 macs

	docker run --platform linux/amd64 --rm -v "$(pwd):/pkg" -w "/pkg" -e QEMU_CPU=max --rm -it swift:latest /bin/bash -c "swift test --build-path ./.build/linux"

The first time "core dumped" - just run again!

Unreleased swift versions, e.g. 5.5:

	docker run --platform linux/amd64 --rm -v "$(pwd):/pkg" -w "/pkg" -e QEMU_CPU=max --rm -it swiftlang/swift:nightly-5.5-bionic /bin/bash -c "swift test --build-path ./.build/linux"

[Some more info](https://gist.github.com/ianpartridge/aa572ae4dba15155787fafca956413c1)

If you need to build for swift < 5.4 you must have an LinuxMain.swift file in your Test folder and run tests with "--enable-test-discovery"

Then it give you this warning, but ignore that: '--enable-test-discovery' option is deprecated; tests are automatically discovered on all platforms


## Docker

https://forums.swift.org/t/arm64-swift-docker-images/43864/13

kill hung images like this:

docker ps
docker stop #id

Sometimes things go wrong with caching, so clean the package:

	docker run --platform linux/amd64 --rm -v "$(pwd):/pkg" -w "/pkg" -e QEMU_CPU=max --rm -it swift:latest /bin/bash -c "swift package clean --build-path ./.build/linux"

## Enable coverage, test this:

swift test --enable-code-coverage
swift test --show-codecov-path

