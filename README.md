# ZeitSatTrack - A Swift TLE Satellite Tracking Library
## Author David HM Spector (spector@zeitgeist.com)

# Summary
_ZeitSatTrack_ will provide position (lat/lon, altitude) information for satellites based on standard TLE (Two Line Element) format orbital parameter descriptions.

This library provides discrete or continuous tracking of satellites either by explicitly naming a satellite or by providing a list of satellites to watch.

# Installation 

_Baseline OS support:_  **Xcode 8.2+, Swift 3.1**; the project targets are configured for iOS but may be compiled under macOS as well. 

## Cocoapods
```ruby
use_frameworks!
pod 'ZeitSatTrack'
```

## Carthage
TBD
## Directly
You can either download the _ZeitSatTrack_ git repo as a git sub-module, or compile directly and either drag _ZeitSatTrack.framework_ into your project, or add it as a subproject/dependency in Xcode. 

# Usage / API

_ZeitSatTrack_ is provides as a manager class that can operated in one of 2 modes: auto-updating and manual.

- _Autoupdating mode_ will fire off calls to  _ZeitSatTrackDelegate_ to notify subscribers that satellites of interest have new positions. 

- _Manual mode_ allows the calling application to ask for updates to a specific satellite by name (or all known satellites); the values return will be the name of the satellite and a set of GeoCoordinate presenting the position (lat/lon) and altitude of the satellite.  Other info about a specific satellite can be requested of the satellite object via other convenience APIs listed below.

## Setup and Initialization
## Instantiating
**import** ZeitSatTrack into your Swift files with

```swift
import ZeitSatTrack
```

then:

```swift
let satTracker = ZeitSatTrackManager.sharedInstance
```

Once instantiated, the library will read from its internal dataset of available satellite groups.  These can be listed by calling 

```swift
let satGroups = satTracker.satelliteCollections()
```

Which will return an array of top-level Satellite groups:</br>

```
▿ 6 elements
  - 0 : "Common Interest"
  - 1 : "Weather & Earth Resources Satellites"
  - 2 : "Communications Satellites"
  - 3 : "Navigation Satellites"
  - 4 : "Scientific Satellites"
  - 5 : "Miscellaneous Satellites"
```

Each of these groups can be further enumerated to get a listing of the names of the TLE files in each group:

```swift
let subGroups = satTracker.subGroupsForCollection(name:"Communications Satellites")
```
Returns an array of names of the satellite TLE files for this group:</br>

```
▿ 13 elements
  - 0 : "Geostationary"
  - 1 : "Intelsat"
  - 2 : "SES"
  - 3 : "Iridium"
  - 4 : "Iridium NEXT"
  - 5 : "Orbcomm"
  - 6 : "Globalstar"
  - 7 : "Amateur Radio"
  - 8 : "Experimental"
  - 9 : "Other Comm"
  - 10 : "Gorizont"
  - 11 : "Raduga"
  - 12 : "Molniya"
```

Most of these listings are self describing, but more details can be found at the [Celestrack](https://www.celestrack.com) site.


<br/>Lastly, you can add satellites explicitly by providing a string containing TLE data with:

```swift
addSatellitesFromTLEData(tleString:String) 
```
Where the string is one or more stanzas in the [Two-Line Element format](https://en.wikipedia.org/wiki/Two-line_element_set):

```
ISS (ZARYA)             
1 25544U 98067A   17144.89781703  .00001573  00000-0  31242-4 0  9992
2 25544  51.6416 154.3996 0005308 189.3117 243.1127 15.53923882 58131
```
The string provided must adhere to the format and are separated by newline characters between each TLE entry.

## Setting the Location
If a location is set, additional information about satellites from the perspective of an Earthbound observer can requested.  Location can be set to be fixed point by setting the property directly:

```swift
satTracker.location = CLLocation(latitude: 37.780129, longitude: -122.392033)
```

...or by enabling continuous updating using the call:

```swift
Let status = satTracker.enableContinuousLocationUpdates()
```

This will return a [CLAuthorizationStatus](https://developer.apple.com/reference/corelocation/clauthorizationstatus) value.

<br/>This feature requires using the CoreLocation manager  which will require both permission of the user in the enclosing location, as well as [Privacy strings describing the use of location info](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW18) in the application's _Info.plist_ file.

### Setting the Update Frequency
_AutoUpdate mode_ includes the ability to set the frequency at which satellite info is updated.  By default the data are updated every _2 seconds_ but a different update frequency can be selected by setting the property

```swift
satTracker.updateInterval
```

This property is in _seconds_.  Setting it to less than 1 second can have adverse impacts on app performance as performing orbital calculations on a large number of satellites is quite computationally expensive.  Another possibility if you need to know a satellite's track over a range of times is to request a [batch location update for the satellite](#Batch-Satellite-Updates).

## Observing Multiple Satellites

_ZeitSatTrack_ has the ability to watch a number of satellites simultaneously and support 2 methods to add and remove satellite for observation:

```swift
func startObservingSatelliteNamed( _ name: String) -> Bool
```

```swift
func stopObservingSatelliteNamed( _ name: String) -> Bool
```

In either case, a result of `true` indicates the named satellite has been added (or removed) from the watch list.  A `false` result means the named satellite was not found(or not being observed).

```swift
func stopObservingAllSatellite()
```

Will remove all satellite from observation.

Lastly, the number of satellites being observed is stored in the property
```swift
observedCount
```
> See [ZeitSatTrack Delegate](#ZeitSatTrack-Delegate) for more on receiving automatic updates of observed satellites.

## Getting Satellite Positions
Once the _ZeitSatTrack_ manager has been initialized and configured with one or more TLE data sets, satellites can be queried to determine their positions by calling:

```swift
func locationForSatelliteNamed( _ name: String, targetDate: Date? = nil) -> GeoCoordinates?
```
Which returns the location for a singe named satellite, or 

```swift
locationsForSatellites(date: Date? = nil) -> [Dictionary<String, GeoCoordinates>]
```

Or, if a there is a list of satellite being observed, and the _ZeitSatTrackDelegate_ protocol is not being used:

```swift
observedSatelliteLocations(date: Date? = nil) -> [Dictionary<String, GeoCoordinates>]?
```

Both calls returns an array of dictionaries with location info for all satellites known to the manager.

### Satellite Position Data

Position data is represented by the `GeoCoordinates` structure. This is a very simple struct, consisting of latitude, longitude and altitude of satellite:

```swift
public struct GeoCoordinates {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var altitude: Double
    
    public func description() -> String {
        return "Location (\(self.latitude), \(self.longitude)); Altitude: \(self.altitude) KM"
    }
}
```


 - *Note:* if a specific date is provided and any given satellite (in either variant of the location call) would not have yet been in orbit (i.e., the specified date is _before the satellite's launch date_) a `nil` will be returned instead of the expected `GeoCoordinates`.

```swift
let satLoc = satTracker.locationForSatelliteNamed("NOAA 18")
```
Yields a result similar to:
```
NOAA 18: Location (-56.1372936362136, -109.455449551038); Altitude: 870.354212207491 KM
```

Where each result is a GeoCoordinates structure.

Other information about the orbital status of the satellite can be obtained by calling:

```swift
let orbitalInfo = satTracker.orbitalInfoForSatelliteNamed("NOAA 18", location: CLLocation(latitude: 37.780129, longitude: -122.392033))
```
Which will return a dictionary containing various orbital parameters that could be useful in visualizing the satellite's path, or locating the satellite visually from the ground.

> *Note*: if the `location` parameter is not supplied it is assumed to be available from the `location` property in the _ZeitSatTrack_ manager.  

> If the manager is configured for auto-updating -- which presumes the CoreLocation access permission has been granted -- then the information returned will be based on the location property as updated periodically by CoreLocation.  If the location property is neither set or provided, this call will return _nil_.

## Batch Satellite Updates
Another useful feature is the ability to get a dictionary of updates for a satellite's position across a range of times. This could be useful for visualizing known satellite over time instead of performing the calculations in real-time.

```swift
locationsForSatelliteNamed(_ name: String, from: Date? = nil, until: Date, interval: Int = 2 ) -> [Dictionary<Date, GeoCoordinates>]?
```
Which will return a dictionary of the named satellite's positions from the start date (or "now") if passed `nil` to the "until" date over the specified interval (whose default value is 2 seconds).

>*Note*: TLE files are updated semiweekly to account for such factors as changes in atmospheric drag, the reliability of GeoCoordinates for long periods in the future cannot be assured.

## Continuous Satellite Updates

By default you have to explicitly ask the library to get either an individual update or get updates for all known satellites. 

An additional available mode is auto-updating mode where the manager will fire off a periodic timer to update a list of satellites of interest.


### ZeitSatTrack Delegate
_ZeitSatTrack_ supports a delegate protocol that will automatically deliver information on observed Satellites.


# Satellite Data Sources
The most common source of two-line (TLE) element files is [Celestrack](https://www.celestrak.com) run by Dr. T.S Kelso.  The Celestrack site maintains a large list of TLE data file broken out by a number of useful categories (Weather, Amateur, Space stations, etc).

_ZeitSatTrack_ provides a consolidated list of these as part of the library resources build right into the library and individual categories and data sets inside those categories can be selected at run time and the current, up to date versions of the TLE files.

The list includes hundreds of satellites in the following areas:

- Common Interest (a selection from the categories below)
- Weather & Earth Resources Satellites
- Communications Satellites
- Navigation Satellites
- Scientific Satellites
- Miscellaneous Satellites

## Adding to the Default Sources
The data format for the _ZeitSatTrack_ data source file is a JSON file with an array of group stanzas  that contain dictionaries with the names and URLs of TLE files, for example:

```json
[{
  "group_name": "Common Interest",
  "files": [{
    "name": "Last 30 Days' Launches",
    "data_file": "https://www.celestrak.com/NORAD/elements/tle-new.txt"
  }, {
    "name": "Space Stations",
    "data_file": "https://www.celestrak.com/NORAD/elements/stations.txt"
  }, {
    "name": "100 (or so) Brightest",
    "data_file": "https://www.celestrak.com/NORAD/elements/visual.txt"
  }, {
    "name": "FENGYUN 1C Debris",
    "data_file": "https://www.celestrak.com/NORAD/elements/1999-025.txt"
  }, {
    "name": "IRIDIUM 33 Debris",
    "data_file": "https://www.celestrak.com/NORAD/elements/iridium-33-debris.txt"
  }, {
    "name": "COSMOS 2251 Debris",
    "data_file": "https://www.celestrak.com/NORAD/elements/cosmos-2251-debris.txt"
  }, {
    "name": "BREEZE-M R/B Breakup (2012-044C)",
    "data_file": "https://www.celestrak.com/NORAD/elements/2012-044.txt"
  }]
}

]
```

If you wanted to add a new set of TLE groups for use with the library, creating a file such as then adding it at run-time using the method
` adddTLESourcesFromFile(_ fileName:String, bundle: Bundle) ` 

which will add all groups in the presented file to the list of available TLE sources. Individual subgroups in your data sources may be added to the available satellites known to the manager by calling:
```swift
loadSatelliteSubGroup(subgroupName:String, group: String)
```


# Contributing & Conduct

This project welcomes contributions; all contributions must adhere to the project's [LICENSE](LICENSE). Please do not contribute any code or other resource that are covered by other people's or organization's copyrights, patents or are otherwise encumbered.  Such contributions will be rejected.

This project adheres to the [Contributor Covenant Code of Conduct](CONDUCT). By participating, you are expected to uphold this code. Please report unacceptable behavior to [info@zeitgeist.com](mailto:info@zeitgeist.com).

# License

 The ZeitSatTrack suite is distributed under the terms of the [Apache License](LICENSE)
