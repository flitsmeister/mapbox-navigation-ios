<div align="center">
  <img src="https://github.com/flitsmeister/flitsmeister-navigation-ios/blob/master/.github/splash-image-ios.png" alt="Flitsmeister Navigation iOS Splash">
</div>
<br>

The Flitsmeister Navigation SDK for iOS is built on a fork of the [Mapbox Navigation SDK v0.21](https://github.com/flitsmeister/flitsmeister-navigation-ios/tree/v0.21.0) which is build on top of the [Mapbox Directions API](https://www.mapbox.com/directions) and contains logic needed to get timed navigation instructions.

With this SDK you can implement turn by turn navigation in your own iOS app while hosting your own Map tiles and Directions API.

# Why have we forked

1. Mapbox decided to put a closed source component to their navigation SDK and introduced a non open source license. Flitsmeister wants an open source solution.
2. Mapbox decided to put telemetry in their SDK. We couldn't turn this off without adjusting the source.
3. We want to use the SDK without paying Mapbox for each MAU and without Mapbox API keys.

All issues are covered with this SDK. 

# What have we changed

- Removed EventManager and all its references, this manager collected telemetry data which we don't want to send
- Updated [Mapbox SDK](https://github.com/mapbox/mapbox-gl-native-ios) from version 4.3 to 5.3
- Added optional config parameter in NavigationMapView constructor to customize certain properties like route line color

# Getting Started

If you are looking to include this inside your project, you have to follow the the following steps:

## Carthage

Alternatively, to install Mapbox Navigation using [Carthage](https://github.com/Carthage/Carthage/):

1. Create a [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#github-repositories) with the following dependency:
   ```cartfile
   github "flitsmeister/flitsmeister-navigation-ios" ~> 1.0.3
   ```

1. Run `carthage update --platform iOS` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include MapboxNavigation.framework and MapboxCoreNavigation.framework.

# Getting Help

- **Have a bug to report?** [Open an issue](https://github.com/flitsmeister/flitsmeister-navigation-ios/issues). If possible, include the version of Flitsmeister Services, a full log, and a project that shows the issue.
- **Have a feature request?** [Open an issue](https://github.com/flitsmeister/flitsmeister-navigation-ios/issues/new). Tell us what the feature should do and why you want the feature.

## <a name="sample-code">Sample code

A demo app is currently not available, so no sample code yet. Please check the Mapbox repository or documentation for examples.

In order to see the map or calculate a route you need your own Maptile and Direction services.

# License

Code is [licensed](LICENSE.md) under MIT and ISC. 
ISC is meant to be functionally equivalent to the MIT license.
