//
//  EarthStation.swift
//  ZeitSatTrack
//
//  Created by David HM Spector on 5/14/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//
import CoreLocation
import Foundation

class EarthStation {
    var  coordinate: CLLocationCoordinate2D?
    var  altitude: Double?
    
    init() {
        altitude = 0.0
        coordinate = CLLocationCoordinate2DMake(0, 0)
    }
    
    
    func lookAngleForSatelliteAt(satelliteCoordinates: GeoCoordinates) -> LookAngle {
        
        var lookAngle: LookAngle
        
        let latitudeRad = self.coordinate!.latitude * .pi / 180.0
        let longitudeRad = self.coordinate!.longitude * .pi / 180.0
        
        let satelliteLatitudeRad = satelliteCoordinates.latitude * .pi / 180.0
        let satelliteLongitudeRad = satelliteCoordinates.longitude * .pi / 180.0
        
        // calculate gamma, the angle between the earth station, the center of the earth, and the subsatellite point
        let gamma = acos(sin(satelliteLatitudeRad) * sin(latitudeRad) + cos(satelliteLatitudeRad)*cos(latitudeRad)*cos(satelliteLongitudeRad - longitudeRad))
        
        let radiusRatio = (self.altitude! + 6370.0) / (satelliteCoordinates.altitude + 6370.0)
        let elevationRad = atan((cos(gamma) - radiusRatio) / sqrt(1.0 - cos(gamma) * cos(gamma)))
        
        // calculate alpha, the azimuth angle (but we'll need to tweak it a bit before we can use it)
        let alpha = asin(sin(fabs(longitudeRad - satelliteLongitudeRad)) * cos(satelliteLatitudeRad) / gamma)
        
        // TODO: Test at Greenwich, east of Greenwich, south of the equator
        var azimuthRad = 0.0
        if (satelliteLatitudeRad > latitudeRad) { // satellite is North of earth station
            
            if (satelliteLongitudeRad > longitudeRad) // satellite is East of us
            {
                azimuthRad = alpha
            } else { // satellite is West of us
                azimuthRad = 2 * .pi - alpha
            }
        } else { // satellite is South of earth station
            if (satelliteLongitudeRad > longitudeRad)  { // satellite is East of us
                
                azimuthRad = .pi - alpha;
            } else { // satellite is West of us
                azimuthRad = .pi + alpha
            }
        }
        
        let elevation = elevationRad * 180.0 / .pi
        let azimuth = azimuthRad * 180.0 / .pi
        lookAngle = LookAngle(azimuth: azimuth, elevation: elevation)
        return lookAngle;
    }
    
}
