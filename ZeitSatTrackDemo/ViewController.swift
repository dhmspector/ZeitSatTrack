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


class ViewController: UIViewController, ZeitSatTrackManagerDelegate {
    let satTracker = ZeitSatTrackManager.sharedInstance
    
    private var theViewC: MaplyBaseViewController?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let satGroups = satTracker.satelliteCollections()

        satTracker.delegate = self
        satTracker.location = CLLocation(latitude: 37.780129, longitude: -122.392033)
        satTracker.loadSatelliteCollectionForGroup(name: satGroups[1])

        
        let globeViewC = theViewC as? WhirlyGlobeViewController
        let mapViewC = theViewC as? MaplyViewController

        theViewC = WhirlyGlobeViewController()
        self.view.addSubview(theViewC!.view)
        theViewC!.view.frame = self.view.bounds
        addChildViewController(theViewC!)

        // we want a black background for a globe, a white background for a map.
        theViewC!.clearColor = (globeViewC != nil) ? UIColor.black : UIColor.white
        
        // and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
        theViewC!.frameInterval = 2
        
        // set up the data source
        if let tileSource = MaplyMBTileSource(mbTiles: "geography-class_medres"),
            let layer = MaplyQuadImageTilesLayer(tileSource: tileSource) {
            layer.handleEdges = (globeViewC != nil)
            layer.coverPoles = (globeViewC != nil)
            layer.requireElev = false
            layer.waitLoad = false
            layer.drawPriority = 0
            layer.singleLevelLoading = false
            theViewC!.add(layer)
        }
        
        // start up over Madrid, center of the old-world
        if let globeViewC = globeViewC {
            globeViewC.height = 0.8
            globeViewC.animate(toPosition: MaplyCoordinateMakeWithDegrees(-3.6704803, 40.5023056), time: 1.0)
        }
        else if let mapViewC = mapViewC {
            mapViewC.height = 1.0
            mapViewC.animate(toPosition: MaplyCoordinateMakeWithDegrees(-3.6704803, 40.5023056), time: 1.0)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

// MARK: ZeitSatTrackManagerDelegate
    
    func didObserveSatellites(satelliteList: [Dictionary<String, GeoCoordinates>]) {
        print("We got: \(satelliteList)")
    }
}

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
