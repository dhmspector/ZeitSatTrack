//
//  FullMapViewController.swift
//  ZeitSatTrack
//
//  Created by David HM Spector on 5/29/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import UIKit
import ZeitSatTrack


class FullMapViewController: UIViewController, ZeitSatTrackManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    let kSatelliteMarkerImage = "satellite"
    let satTracker = ZeitSatTrackManager.sharedInstance
    let markers = [MKAnnotation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMap()
        // Do any additional setup after loading the view.
        let satGroups = satTracker.satelliteCollections()
        satTracker.delegate = self
        satTracker.location = CLLocation(latitude: 37.780129, longitude: -122.392033)
        _ = satTracker.loadSatelliteSubGroup(subgroupName:"NOAA", group:  "Weather & Earth Resources Satellites")
        _ = satTracker.loadSatelliteSubGroup(subgroupName:"GEOS", group:  "Weather & Earth Resources Satellites")
        
        
        satTracker.trackedSatsByName().forEach { (name) in
            _ = self.satTracker.startObservingSatelliteNamed(name)
        }
        _ = satTracker.enableContinuousLocationUpdates()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: Utilities
    
    func setupMap() {
        let span = MKCoordinateSpanMake(CLLocationDegrees(180.0), CLLocationDegrees(360.0))
        let region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0.0000, 0.0000), span)
        self.mapView.setRegion(region, animated: true)
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location. guard !(annotation is MKUserLocation) else { return nil }
        
        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "satellite")
        }
        
        return annotationView
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: ZeitSatTrackManagerDelegate
    
    func didObserveSatellites(satelliteList: Dictionary<String, GeoCoordinates>) {
        //print("We got: \(satelliteList)")
        satelliteList.forEach { (dict) in
            let geoDict = dict.value
            let satName = dict.key
            let tmpLocation = CLLocation(latitude: geoDict.latitude, longitude: geoDict.longitude)
            
        }
        
    }
    
    func didRemoveObservedSatellitesNamed(_ names: [String]) {
        names.forEach { (name) in
            // remove the marker
        }
        
    }
} // of FullMapViewController
