//
//  ViewController.swift
//  ZeitSatTrack
//
//  Created by David HM Spector on 5/12/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import CoreLocation
import UIKit
import ZeitSatTrack

let kSatelliteMarkerImage = "satellite"

class ViewController: UIViewController, ZeitSatTrackManagerDelegate {
    let satTracker = ZeitSatTrackManager.sharedInstance
    
    private var theViewC: MaplyBaseViewController?
    private var vectorDict: [String:AnyObject]?
    var mapMarkers = Dictionary<String, MaplyMovingScreenMarker>()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let satGroups = satTracker.satelliteCollections()
        satTracker.delegate = self
        satTracker.location = CLLocation(latitude: 37.780129, longitude: -122.392033)
        _ = satTracker.loadSatelliteSubGroup(subgroupName: "100 (or so) Brightest", group: "Common Interest")
        self.setupWhirlyGlobe()

        satTracker.trackedSatsByName().forEach { (name) in
            _ = self.satTracker.startObservingSatelliteNamed(name)
        }
        satTracker.enableContinuousLocationUpdates()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: WhirlyGlobe setup and delegates
    func setupWhirlyGlobe() {
        theViewC = WhirlyGlobeViewController()
        
        self.view.addSubview(theViewC!.view)
        theViewC!.view.frame = self.view.bounds
        addChildViewController(theViewC!)
        
        let globeViewC = theViewC as? WhirlyGlobeViewController
        let mapViewC = theViewC as? MaplyViewController
        
        // we want a black background for a globe, a white background for a map.
        theViewC!.clearColor = (globeViewC != nil) ? UIColor.black : UIColor.white
        
        // and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
        theViewC!.frameInterval = 2
        
        // add the capability to use the local tiles or remote tiles
        let useLocalTiles = false
        let DoOverlay = true
        
        // we'll need this layer in a second
        let layer: MaplyQuadImageTilesLayer
        
        if useLocalTiles {
            guard let tileSource = MaplyMBTileSource(mbTiles: "geography-class_medres") else {
                // can't load local tile set
            }
            layer = MaplyQuadImageTilesLayer(tileSource: tileSource)!
        }
        else {
            // Because this is a remote tile set, we'll want a cache directory
            let baseCacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let tilesCacheDir = "\(baseCacheDir)/stamentiles/"
            let maxZoom = Int32(18)
            
            // Stamen Terrain Tiles, courtesy of Stamen Design under the Creative Commons Attribution License.
            // Data by OpenStreetMap under the Open Data Commons Open Database License.
            guard let tileSource = MaplyRemoteTileSource(
              baseURL: "http://tile.stamen.com/terrain/",    //terrain
              ext: "png",
                //baseURL: "http://map1.vis.earthdata.nasa.gov/wmts-webmerc/MODIS_Terra_CorrectedReflectance_TrueColor/default/2015-06-07/GoogleMapsCompatible_Level9/{z}/{y}/{x}",
                //ext: "jpg",
                minZoom: 0,
                maxZoom: maxZoom) else {
                    // can't create remote tile source
                    return
            }
            
            tileSource.cacheDir = tilesCacheDir
            layer = MaplyQuadImageTilesLayer(tileSource: tileSource)!
        }
        
        
        if DoOverlay {
            // For network paging layers, where we'll store temp files
            let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            if let tileSource = MaplyRemoteTileSource(baseURL: "http://map1.vis.earthdata.nasa.gov/wmts-webmerc/Sea_Surface_Temp_Blended/default/2015-06-25/GoogleMapsCompatible_Level7/{z}/{y}/{x}",
                                                      ext: "png",
                                                      minZoom: 0,
                                                      maxZoom: 9) {
                tileSource.cacheDir = "\(cacheDir)/sea_temperature/"
                //tileSource.tileInfo.cachedFileLifetime = 60*60*24 // invalidate OWM data after 24 hours
                if let temperatureLayer = MaplyQuadImageTilesLayer(tileSource: tileSource) {
                    temperatureLayer.coverPoles = false
                    temperatureLayer.handleEdges = false
                    globeViewC?.add(temperatureLayer)
                }
            }
        }
        theViewC!.add(layer)

        // Add the coiuntry outlines...
        vectorDict = [kMaplyColor: UIColor.white, kMaplySelectable: true as AnyObject, kMaplyVecWidth: 4.0 as AnyObject]
        addCountries()

        
        // Lastly, start up over Downtown SF
        if let globeViewC = globeViewC {
            globeViewC.height = 0.8
            globeViewC.animate(toPosition: MaplyCoordinateMakeWithDegrees(-122.407555, 37.787952), time: 1.0)
        }
        else if let mapViewC = mapViewC {
            mapViewC.height = 1.0
            mapViewC.animate(toPosition: MaplyCoordinateMakeWithDegrees(-122.407555, 37.787952), time: 1.0)
        }
    } // of setupWhirlyGlobe
    
    private func addCountries() {
        DispatchQueue.global().async {
            let bundle = Bundle.main
            let allOutlines = bundle.paths(forResourcesOfType: "geojson", inDirectory: "country_json_50m")
            
            for outline in allOutlines {
                if let jsonData = NSData(contentsOfFile: outline),
                    let wgVecObj = MaplyVectorObject(fromGeoJSON: jsonData as Data) {
                    // the admin tag from the country outline geojson has the country name ­ save
                    
                     let attrs = wgVecObj.attributes
                     let vecName = attrs.object(forKey: "ADMIN") as? NSObject
                     if attrs.count > 0 && vecName != nil {
                        wgVecObj.userObject = vecName
                    }
                    // add the outline to our view
                    let compObj = self.theViewC?.addVectors([wgVecObj], desc: self.vectorDict)
                    // If you ever intend to remove these, keep track of the MaplyComponentObjects above.
                }
            }
        }
    }

    // MARK: Markers
    /// Add a moving marker at a specified position
    ///
    /// - Parameter location: the MaplyCoordinate (lat/lon) for the marker
    /// - Parameter imageName: the name of am image reasoiurce to load
    /// - Returns: A MaplyMovingScreenMarker or nil if unsuccessful
    func newMarkerAt(location: CLLocation, iamgeName: String) -> MaplyMovingScreenMarker? {
        let maplyLoc = MaplyCoordinateMakeWithDegrees(Float(location.coordinate.longitude), Float(location.coordinate.latitude))
        let rv = MaplyMovingScreenMarker()
        rv.image = UIImage(named: "satellite")
        rv.size = CGSize(width: 32.0, height: 32.0)
        rv.layoutImportance = MAXFLOAT
        rv.selectable = false
        rv.loc = maplyLoc
        rv.endLoc = maplyLoc
        return rv
    }
    
    func update(marker:MaplyMovingScreenMarker, location:CLLocation) {
        let lastLoction = CLLocation(latitude: CLLocationDegrees(marker.endLoc.y), longitude: CLLocationDegrees(marker.endLoc.x))
        if lastLoction != location {
            self.theViewC?.removeActiveObjects([marker as Any])

            marker.loc = marker.endLoc
            marker.endLoc =  MaplyCoordinateMakeWithDegrees(Float(location.coordinate.longitude), Float(location.coordinate.latitude))
            marker.duration = 0.1
            self.theViewC?.addScreenMarkers([marker as Any], desc: nil)
        }
    }

    
    
    
    // MARK: ZeitSatTrackManagerDelegate

    func didObserveSatellites(satelliteList: Dictionary<String, GeoCoordinates>) {
        //print("We got: \(satelliteList)")
        satelliteList.forEach { (dict) in

            let geoDict = dict.value
            print("\(dict.key) - \(geoDict.description())")
            
//            let tmpLocation = CLLocation(latitude: geoDict.latitude, longitude: geoDict.longitude)
//            if let thisMarker = self.mapMarkers[dict.key] {
//                self.update(marker: thisMarker, location: tmpLocation)
//                //print("Updated marker for \(dict.key) at \(tmpLocation)")
//            } else { // no marker - make a new one
//                let tmpMarker = self.newMarkerAt(location: tmpLocation, iamgeName: kSatelliteMarkerImage)
//                self.mapMarkers[dict.key] = tmpMarker
//                self.theViewC?.addScreenMarkers([tmpMarker as Any], desc: nil)
//                //print("Added marker for \(dict.key) at \(tmpLocation)")
//            }
        }
    }
    
    func didRemoveObservedSatellitesNamed(_ names: [String]) {
        names.forEach { (name) in
            // remove the marker
        }
        
    }
} // of viewcontroller





/*
 // Do any additional setup after loading the view, typically from a nib.
 let satGroups = satTracker.satelliteCollections()
 
 
 
 //        print("Satellite Groups: \(satGroups)")
 //        let satCollections = satTracker.tleListForGroupNamed(satGroups[1])
 //        print("Satellite list for \(satGroups[1]): \(String(describing: satCollections))")
 //        let tleData = satTracker.tleDataForSatelliteGroup(satGroups[1], subGroupName: satCollections![0]["name"]!)
 //        print("TLE URL: \(String(describing: tleData))")
 satTracker.loadSatelliteCollectionForGroup(name: satGroups[1])
 //        satTracker.loadSatelliteCollectionForGroup(name: satGroups[2])
 //        satTracker.loadSatelliteCollectionForGroup(name: satGroups[3])
 
 //let subGroups = satTracker.subGroupsForCollection(name:satGroups[2])
 
 let error = satTracker.loadSatelliteSubGroup(subgroupName: "Radar Calibration", group: "Miscellaneous Satellites")
 print("\(satTracker.stats())")
 //print("Satellite names: \(satTracker.trackedSatsByName())")
 //print("Loctions of all tracked sats: \(satTracker.locationsForSatellites())")
 
 //satTracker.locationsForSatellites().forEach { (satLocationDict) in
 //    let locString = satLocationDict[satLocationDict.keys.first!]!.description()
 //    print("\(satLocationDict.keys.first!):  \(locString)")
 //}
 
 let satLoc = satTracker.locationForSatelliteNamed("NOAA 18")
 print("NOAA 18: \(satLoc != nil ?  satLoc!.description() : "NOT FOUND!")")
 let noaa18Added = self.satTracker.startObservingSatelliteNamed("NOAA 18")
 print("NOAA18 added: \(noaa18Added)")
 
 */
