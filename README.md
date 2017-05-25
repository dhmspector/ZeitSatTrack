# ZeitSatTrack - A Swift TLE Sat Tracking Library
## Author David HM Spector (spector@zeitgeist.com)

# Summary
# Installation 
# Usage / API
_ZeitSatTrack_ is provides as a manager class that can operated in one of several modes:
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

If you wanted to add a new set of TLE groups for use with the library, creating a file such as then adding it at run-time using the ```swift  adddTLESourcesF(fileName:String, bundle: Bundle) ``` method will add all groups in the file to the list of available TLE sources. Individual subgroups in your data sources may be added to the available satellites known to the manager by calling:
```swift
loadSatelliteSubGroup(subgroupName:String, group: String)
```
# Contributing & Conduct

This project welcomes contributions; all contributions must adhere to the project's [LICENSE](LICENSE). Please do not contribute any code or other resource that are covered by other people's pr organization's copyrights, patents or are otherwise encumbered.  Such contributions will be rejected.

This project adheres to the [Contributor Covenant Code of Conduct](CONDUCT). By participating, you are expected to uphold this code. Please report unacceptable behavior to [info@zeitgeist.com](mailto:info@zeitgeist.com).

# License

 The ZeitSatTrack suite is distributed under the terms of the [Apache License](LICENSE)
