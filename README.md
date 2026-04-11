# BoatTracker-iOS

The iOS app for BoatTracker. See [www.boat-tracker.com](https://www.boat-tracker.com) for details.

## Development

To run tests from the command line:

    xcodebuild test -workspace BoatTracker.xcworkspace -scheme BoatTracker -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=17.0.1'

### Formatting

To format all files in the current directory recursively:

    swift format format --configuration swift-format.json -i -r .

## Releasing

Push to the master branch.

Every commit to the master branch triggers a [GitHub Actions](.github/workflows/release) job that uses [Fastlane](fastlane/Fastlane) to publish a new version to the [App Store](https://itunes.apple.com/us/app/boat-tracker/id1434203398?ls=1&mt=8).
