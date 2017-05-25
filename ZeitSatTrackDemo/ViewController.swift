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


class ViewController: UIViewController {
    let satTracker = ZeitSatTrackManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let satGroups = satTracker.satelliteCollections()
//        print("Satellite Groups: \(satGroups)")
//        let satCollections = satTracker.tleListForGroupNamed(satGroups[1])
//        print("Satellite list for \(satGroups[1]): \(String(describing: satCollections))")
//        let tleData = satTracker.tleDataForSatelliteGroup(satGroups[1], subGroupName: satCollections![0]["name"]!)
//        print("TLE URL: \(String(describing: tleData))")
        satTracker.loadSatelliteCollectionForGroup(name: satGroups[1])
        satTracker.loadSatelliteCollectionForGroup(name: satGroups[2])
        satTracker.loadSatelliteCollectionForGroup(name: satGroups[3])
        
       satTracker.location = CLLocation(latitude: 37.780129, longitude: -122.392033)
        let subGroups = satTracker.subGroupsForCollection(name:satGroups[2])
        
        let error = satTracker.loadSatelliteSubGroup(subgroupName: "Radar Calibration", group: "Miscellaneous Satellites")
        print("\(satTracker.stats())")
        //print("Satellite names: \(satTracker.trackedSatsByName())")
        //print("Loctions of all tracked sats: \(satTracker.locationsForSatellites())")
        satTracker.locationsForSatellites().forEach { (satLocationDict) in
            let locString = satLocationDict[satLocationDict.keys.first!]!.description()
            print("\(satLocationDict.keys.first!):  \(locString)")
        }
        
        let satLoc = satTracker.locationForSatelliteNamed("NOAA 18")
        print("NOAA 18: \(satLoc != nil ?  satLoc!.description() : "NOT FOUND!")")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

