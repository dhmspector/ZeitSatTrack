# ZeitSatTrack - A Swift TLE Satellite Tracking Library
## Author David HM Spector (spector@zeitgeist.com)

# Summary
_ZeitSatTrack_ will provide position (lat/lon, altitude) information for satellites based on standard TLE (Two Line Element) format orbital parameter descriptions.

This library provider discrete or continuous tracking of satellites.

# Installation 

_Baseline OS support:_  **Xcode 8.2+, Swift 3.1**; the project targets are configured for iOS but may be compiled under macOS as well. 

## Cocoapods
```ruby
use_frameworks!
pod 'ZeitSatTrack'
```
**import** ZeitSatTrack into your Swift files 
```swift
import ZeitSatTrack
```

## Carthage
TBD
## Directly
You can either download the _ZeitSatTrack_ git repo as a git sub-module, or compile directly and either drag _ZeitSatTrack.framework_ into your project, or add it as a subproject/dependency in Xcode. 

# Usage / API

_ZeitSatTrack_ is provides as a manager class that can operated in one of 2 modes: auto-updating and manual.

- _Autoupdating mode_ will fire off calls to  _ZeitSatTrackDelegate_ to notify subscribers that satellites of interest have new positions. 

- _Manual mode_ allows the calling application to ask for updates to a specific satellite by name; the value return will be the name of the satellite and a set of GeoCoordinate presenting the position (lat/lon) and altitude of the satellite.  Other info about a specific satellite can be requests of the satellite object  via other convenience APIs listed below.

## Setup and Initialization
## Instantiating
```swift
let satTracker = ZeitSatTrackManager.sharedInstance
```

Once instantiated, the library will read from its internal dataset of available source groups.  These can be listed by calling 

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

Lastly, you can add satellites explicitly by providing a string containing TLE data with:

```swift
addSatellitesFromTLEData(tleString:String) 
```
Where the string is in the [Two-Line Element format](https://en.wikipedia.org/wiki/Two-line_element_set).  The string can contain one or more TLEs provided they adhere to the format and are separated by newline characters between each TLE entry.

## Getting Satellite Positions
Once the _ZeitSatTrack_ manager has been initialized and configured with one or more TLE data sets, each satellite can be queried to determine its position by calling:

```swift
func locationForSatelliteNamed( _ name: String, targetDate: Date? = nil) -> GeoCoordinates?
```
Which returns the location for the named satellite, or 

```swift
locationsForSatellites(date: Date? = nil) -> [Dictionary<String, GeoCoordinates>]
```

Which returns an array of dictionaries with location info for all satellites known to the manager.

The `GeoCoordinates` structure is very simple consisting of latitude, longitude and altitude of satellite at the time specified in the call -- or "now" if called without a specific date:

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
Where each call 

# Satellite Data Sources
The most common source of two-line (TLE) element files is [Celestrack](https://www.celestrack.com) run by T.S Kelso.  The Celestrack site maintains a large list of TLE data file broken out by a number of useful categories (Weather, Amateur, Space stations, etc).

_ZeitSatTrack_ provides a consolidated list of these as part of the library resources build right into the library and individual categories and data sets inside those categories can be selected at run time and the current, up to date versions of the TLE files.

The list includes hundreds of satellites in the following areas:

- Common Interest (a selection from the categories below)
- Weather & Earth Resources Satellites
- Communications Satellites
- Navigation Satellites
- Scientific Satellites
- Miscellaneous Satellites

## Adding to the Default Sources
The data format for the _ZeitSatTrack_ data source file is a JSON file with an array of group stanzas that contain the names and URLs of TLE files, for example:

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
},
//: ...more stanzas with more groups and specific satellite subgroups...
]
```

If you wanted to add a new set of TLE groups for use with the library, creating a file such as then adding it at run-time using the method
` adddTLESourcesF(fileName:String, bundle: Bundle) ` 

which will add all groups in the presented file to the list of available TLE sources. Individual subgroups in your data sources may be added to the available satellites known to the manager by calling:
```swift
loadSatelliteSubGroup(subgroupName:String, group: String)
```


# Contributing & Conduct

This project welcomes contributions; all contributions must adhere to the project's [LICENSE](LICENSE). Please do not contribute any code or other resource that are covered by other people's pr organization's copyrights, patents or are otherwise encumbered.  Such contributions will be rejected.

This project adheres to the [Contributor Covenant Code of Conduct](CONDUCT). By participating, you are expected to uphold this code. Please report unacceptable behavior to [info@zeitgeist.com](mailto:info@zeitgeist.com).

# License

 The ZeitSatTrack suite is distributed under the terms of the [Apache License](LICENSE)
