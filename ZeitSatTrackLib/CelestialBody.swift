//
//  ZeitSatTrackManager.swift
//  ZeitSatTrack
//
//  Created by David Spector on 5/22/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//
//  Planetary Calulations written by Ryan Pasecky on 10/12/17.
//
// These are all based on the formulas presented in
// Paul Schlyter's website
// http://www.stjarnhimlen.se/comp/ppcomp.html#5
//
// Check against values here: http://celestialchart.com/ephemeris/

import Foundation

public class CelestialBody {

  public var type: CelestialBodyType
  public var latitude: Float!
  public var longitude: Float!
  public var distanceFromEarthCenter: Float!
  public var altitude: Float?
  public var azimuth: Float?
  public var dateTimeOfCalculation: Float!
  public var fractionOfDate: Float!
  
  public weak var sun: CelestialBody?
  
  fileprivate var calculatedOrbitalParameters: Bool = false

  //Heliocentric coordinates
  var xh: Float!
  var yh: Float!
  var zh: Float!
  
  //Heliocentric coordinates
  var xg: Float!
  var yg: Float!
  var zg: Float!
  
  //Perturbations
  var Plong: Float!
  var Plat: Float!
  var Pr: Float!
  
  //Right Ascension & Declination
  var RA: Float!
  var Dec: Float!
  var GMST0: Float!
  var SIDTIME: Float!
  var HA_Deg: Float!
  var HA_return: Float!
  
  init(type: CelestialBodyType) {
    self.type = type
  }
  
  func initializeCalculations(forDate: Date, givenSun: CelestialBody) {
    self.sun = givenSun
    let (d, _) =  self.calculateOrbitalDate(forDate)
    self.celestialBodyPositionAt(date: d)
  }
  
  func updatePlanetCoordinates(forDate: Date) {
    
    let (d, _) = self.calculateOrbitalDate(forDate)
    self.celestialBodyPositionAt(date: d)
  }
  
  func updateAltitudeAndAzimuth(forDate: Date, fromCoordinates: GeoCoordinates) {
    let (d, _) = self.calculateOrbitalDate(forDate)
    
    self.celestialBodyPositionAt(date: d)
    self.calculateAltitudeAndAzimuth(coordinates: fromCoordinates)
  }
  
  public func calculateOrbitalDate(_ date: Date) -> (Float, Float) {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(abbreviation: "UTC")!
    
    let y = calendar.component(.year, from: date)
    let m = calendar.component(.month, from: date)
    let D = calendar.component(.day, from: date)
    let minutes = calendar.component(.minute, from: date)
    let hours = calendar.component(.hour, from: date)
    
    let d: Int = 367 * y - (7 * ( y + ((m + 9)/12))) / 4 + (275 * m)/9 + D - 730530
    
    let UT = (Float(minutes) + Float(hours * 60))/Float(1440.0)
    let dAdjustedForMinutes = Float(d) + UT
    
    self.dateTimeOfCalculation = dAdjustedForMinutes
    self.fractionOfDate = UT
    
    return (Float(d), UT)
  }
  
  func celestialBodyPositionAt(date: Float) {
    
    //MARK: Calculate Orbital Parameters
    var NPlanet: Float!
    var iPlanet: Float!
    var wPlanet: Float!
    var aPlanet: Float!
    var ePlanet: Float!
    var MPlanet: Float!
    
    switch self.type {
    case .mercury:
      NPlanet =  48.3313 + 3.24587E-5   * date
      iPlanet = 7.0047 + 5.00E-8 * date
      wPlanet = 29.1241 + 1.01444E-5 * date
      aPlanet = 0.387098
      ePlanet = 0.205635 + 5.59E-10  * date
      MPlanet = 168.6562 + 4.0923344368 * date
      
    case .venus:
      NPlanet =  76.6799 + 2.46590E-5  * date
      iPlanet = 3.3946 + 2.75E-8 * date
      wPlanet = 54.8910 + 1.38374E-5 * date
      aPlanet = 0.723330
      ePlanet = 0.006773 - 1.302E-9 * date
      MPlanet = 48.0052 + 1.6021302244 * date
      
    case .mars:
      NPlanet =  49.5574 + 2.11081E-5 * date
      iPlanet = 1.8497 - 1.78E-8 * date
      wPlanet = 286.5016 + 2.92961E-5 * date
      aPlanet = 1.523688
      ePlanet = 0.093405 + 2.516E-9  * date
      MPlanet = 18.6021 + 0.5240207766 * date
      
    case .jupiter:
      NPlanet =  100.4542 + 2.76854E-5  * date
      iPlanet = 1.3030 - 1.557E-7 * date
      wPlanet = 273.8777 + 1.64505E-5 * date
      aPlanet = 5.20256
      ePlanet = 0.048498 + 4.469E-9  * date
      MPlanet = 19.8950 + 0.0830853001 * date
      
    case .saturn:
      NPlanet =  113.6634 + 2.38980E-5 * date
      iPlanet =   2.4886 - 1.081E-7 * date
      wPlanet = 339.3939 + 2.97661E-5 * date
      aPlanet = 9.55475
      ePlanet = 0.055546 - 9.499E-9 * date
      MPlanet = 316.9670 + 0.0334442282 * date
      
    case .uranus:
      NPlanet =  74.0005 + 1.3978E-5 * date
      iPlanet =  0.7733 + 1.9E-8 * date
      wPlanet = 96.6612 + 3.0565E-5 * date
      aPlanet = 19.18171 - 1.55E-8 * date
      ePlanet = 0.047318 + 7.45E-9 * date
      MPlanet = 142.5905 + 0.011725806  * date
      
    case .neptune:
      NPlanet =  131.7806 + 3.0173E-5 * date
      iPlanet =   1.7700 - 2.55E-7 * date
      wPlanet = 272.8461 - 6.027E-6 * date
      aPlanet = 30.05826 + 3.313E-8 * date
      ePlanet = 0.008606 + 2.15E-9 * date
      MPlanet = 260.2471 + 0.005995147  * date
      
    case .sun:
      NPlanet =  0
      iPlanet =  0
      wPlanet = 282.9404 + 4.70935E-5 * date
      aPlanet = 1
      ePlanet = 0.016709 - 1.151E-9 * date
      MPlanet = 356.0470 + 0.9856002585 * date
      
    case .moon:
      
      NPlanet = 125.1228 - 0.0529538083 * date
      iPlanet = 5.1454
      wPlanet = 318.0634 + 0.1643573223 * date
      aPlanet = 60.2666
      ePlanet = 0.054900
      MPlanet = 115.3654 + 13.0649929509 * date
      
    }
    
    let ecl = 23.4393 - 3.563E-7 * date
    
    
    let wSun = 282.9404 + 4.70935E-5 * date
    let MSun = 356.0470 + 0.9856002585 * date
    let L = clampTo360(wSun + MSun)
    
    NPlanet = clampTo360(NPlanet)
    wPlanet = clampTo360(wPlanet)
    MPlanet = clampTo360(MPlanet)
    
    let EPlanet1 =  ( 1.0 + ePlanet * cos(MPlanet * Float.pi / 180) )
    let EPlanet2 = ePlanet * (180 / Float.pi) * sin(MPlanet * Float.pi / 180)
    let EPlanet = MPlanet + EPlanet1 * EPlanet2      // Eccentric anomaly
    
    calculatedOrbitalParameters = true
    
    //MARK: Calculate Geocentric Coordinates
    
    // xv, yv: elliptical coordinates of Planet
    let xv: Float = aPlanet * (cos(EPlanet * Float.pi / 180) - ePlanet)
    let yv1: Float = sqrt(1.0 - ePlanet * ePlanet)
    let yv2: Float = sin(EPlanet * Float.pi / 180)
    let yv: Float = aPlanet * (yv1 * yv2)
    
    // v: true anomaly
    let vRad = atan2( yv, xv )
    var v: Float = vRad * 180 / Float.pi
    v = clampTo360(v)
    
    // r: Planet distance from earth (center to center)
    let r = sqrt( xv * xv + yv * yv )
    
    // xh, yh, zh: planet position in 3D space (heliocentric)
    xh = r * ( cos(NPlanet * .pi / 180) * cos((v + wPlanet) * .pi / 180) - sin(NPlanet * .pi / 180) * sin((v + wPlanet) * .pi / 180) * cos(iPlanet * .pi / 180) )
    yh = r * ( sin(NPlanet * .pi / 180) * cos((v + wPlanet) * .pi / 180) + cos(NPlanet * .pi / 180) * sin((v + wPlanet) * .pi / 180) * cos(iPlanet * .pi / 180) )
    zh = r * ( sin((v + wPlanet) * .pi / 180) * sin(iPlanet * .pi / 180) )
    
    // lonecl, latecl: ecliptic longitude
    var lonecl: Float = atan2(yh, xh) * 180 / Float.pi
    lonecl = clampTo360(lonecl)
    var latecl: Float = atan2(zh, sqrt(xh * xh + yh * yh)) * 180 / Float.pi
    latecl = clampLatitude(latecl)
    
    //convert from heliocentric coordinates to geocentric
    
    
    switch self.type {
    case .sun:
      xg = 0 + xh
      yg = 0 + yh
      zg = 0 + zh
    default:
      xg = sun!.xg + xh
      yg = sun!.yg + yh
      zg = sun!.zg + zh
    }
    
    
    //rotate coordinates to fit the earths equatorial system
    let xe: Float = xg
    let ye: Float = yg * cos(ecl  * .pi / 180) - zg * sin(ecl * .pi / 180)
    let ze: Float = yg * sin(ecl * .pi / 180) + zg * cos(ecl * .pi / 180)
    
    
    //calculate perturbations to the latitude and longitude caused by the gravity field of
    //nearby planets
    
    if calculatedOrbitalParameters == false {
      self.celestialBodyPositionAt(date: date)
    }
    
    switch self.type {
    case .jupiter:
      
      let Ms: Float = clampTo360(316.9670 + 0.0334442282 * date)
      
      Plong =
        -0.332 * sin(2 * MPlanet - 5 * Ms - 67.6)
        - 0.056 * sin(2 * MPlanet - 2 * Ms + 21)
        + 0.042 * sin(3 * MPlanet - 5 * Ms + 21)
        - 0.036 * sin(MPlanet - 2 * Ms)
        + 0.022 * cos(MPlanet - Ms)
        + 0.023 * sin(2 * MPlanet - 3 * Ms + 52)
        - 0.016 * sin(MPlanet - 5 * Ms - 69)
      
      Plat = 0
      Pr = 0
    case .saturn:
      let Mj: Float = clampTo360(19.8950 + 0.0830853001 * date)
      Plong =
        0.812 * sin(2 * Mj - 5 * MPlanet - 67.6)
        - 0.229 * cos(2 * Mj - 4 * MPlanet - 2)
        + 0.119 * sin(Mj - 2 * MPlanet - 3)
        + 0.046 * sin(2 * Mj - 6 * MPlanet - 69)
        + 0.014 * sin(Mj - 3 * MPlanet + 32)
      
      Plat = -0.020 * cos(2 * Mj - 4 * MPlanet - 2)
        + 0.018 * sin(2 * Mj - 6 * MPlanet - 49)
      
      Pr = 0
      
    case .uranus:
      let Mj: Float = clampTo360(19.8950 + 0.0830853001 * date)
      let Ms: Float = clampTo360(316.9670 + 0.0334442282 * date)
      
      Plong =
        +0.040 * sin(Ms - 2 * MPlanet + 6)
        + 0.035 * sin(Ms - 3 * MPlanet + 33)
        - 0.015 * sin(Mj - MPlanet + 20)
      
      Plat = 0
      Pr = 0
      
    case .moon:
      let Ms: Float = clampTo360(356.0470 + 0.9856002585 * date)
      let Mm: Float = MPlanet
      let ws: Float = clampTo360(282.9404 + 4.70935E-5 * date)
      let wm: Float = wPlanet
      let Ls: Float = Ms + ws
      let Lm: Float = MPlanet + wPlanet
      let D: Float = Lm - Ls
      let F: Float =  Lm - NPlanet
      
      Plong = -1.274 * sin((Mm - 2 * D) * .pi / 180)
        + 0.658 * sin(2 * D * .pi / 180)
        - 0.186 * sin(Ms * .pi / 180)
        - 0.059 * sin((2 * Mm - 2 * D) * .pi / 180)
        - 0.057 * sin((Mm - 2 * D + Ms) * .pi / 180)
        + 0.053 * sin((Mm + 2 * D) * .pi / 180)
        + 0.046 * sin((2 * D - Ms) * .pi / 180)
        + 0.041 * sin((Mm - Ms) * .pi / 180)
        - 0.035 * sin(D * .pi / 180)
        - 0.031 * sin((Mm + Ms) * .pi / 180)
        - 0.015 * sin((2 * F - 2 * D) * .pi / 180)
        + 0.011 * sin((Mm - 4 * D) * .pi / 180)
      
      Plat = -0.173 * sin((F - 2 * D) * .pi / 180)
        - 0.055 * sin((Mm - F - 2 * D) * .pi / 180)
        - 0.046 * sin((Mm + F - 2 * D) * .pi / 180)
        + 0.033 * sin((F + 2 * D) * .pi / 180)
        + 0.017 * sin((2 * Mm + F) * .pi / 180)
      
      Pr = -0.58 * cos((Mm - 2 * D) * .pi / 180)
        - 0.46 * cos(2 * D * .pi / 180)
      
    default:
      Plat = 0
      Plong = 0
      Pr = 0
    }
    
    let xe2: Float = xe * xe
    let ye2: Float = ye * ye
    let ze2: Float = ze * ze
    
    let sumOfSquares: Float = xe2 + ye2 + ze2
    
    distanceFromEarthCenter = sqrt(sumOfSquares) + Pr
    
    //MARK: Right Ascention and Declination
    
    RA  = atan2( ye, xe ) * 180 / Float.pi
    RA = clampTo360(RA)
    Dec = atan2( ze, sqrt(xe * xe + ye * ye) ) * 180 / Float.pi
    Dec = clampLatitude(Dec + Plat)
    
    let UT: Float = fractionOfDate
    //correct for time of day
    
    GMST0 = clampTo360(L + 180)
    GMST0 = GMST0 / 15

    SIDTIME = GMST0 + UT * 24 + 0/15
    HA_Deg = SIDTIME * 15 - RA
    HA_return = clampTo360(360 - HA_Deg + Plong)
    
    latitude = Dec
    longitude = HA_return
    
    //DEBUG
    //print("planet: \(self.type.rawValue), lat: \(self.latitude!), long: \(self.longitude!)")
  }
  
  func calculateAltitudeAndAzimuth(coordinates: GeoCoordinates) {
    
    let wSun: Float = 282.9404 + 4.70935E-5 * self.dateTimeOfCalculation
    let MSun: Float = 356.0470 + 0.9856002585 * self.dateTimeOfCalculation
    let L: Float = clampTo360(wSun + MSun)
    
    let UT = fractionOfDate
    //correct for time of day
    GMST0 = clampTo360(L + 180)
    GMST0 = GMST0 / 15
    SIDTIME = GMST0 + UT! * 24 + Float(coordinates.longitude/15)
    HA_Deg = SIDTIME * 15 - RA
    HA_return = clampTo360(360 - HA_Deg + Plong)
    
    // xi, yi, zi: HA, Dec in rectangular coordinates
    let xi: Float = cos(HA_Deg * .pi/180) * cos(Dec * .pi/180)
    let yi: Float = sin(HA_Deg * .pi/180) * cos(Dec * .pi/180)
    let zi: Float = sin(Dec * .pi/180)
    
    // xhor, yhor, zhor: Rotate coordinates to align z-axis with the zenith
    let xhor: Float =   xi * sin(Float(coordinates.latitude) * .pi/180)
                      - zi * cos(Float(coordinates.latitude) * .pi/180)
    let yhor: Float = yi
    let zhor: Float =   xi * cos(Float(coordinates.latitude) * .pi/180)
                      + zi * sin(Float(coordinates.latitude) * .pi/180)
    
    //TO-DO: Add in return for altitude and azimuth
    azimuth  = atan2(yhor, xhor) * 180 / .pi + 180
    altitude = atan2(zhor, sqrt( xhor * xhor + yhor * yhor )) * 180 / .pi
    
    //DEBUG
    //print("altitude: \(String(describing: altitude)), azimuth: \(String(describing: azimuth))")
  }
  
  //Degree values should not go above 360, below 0
  func clampTo360(_ num: Float) -> Float {
    var returnedNum: Float = num
    if returnedNum > 360 {
      while returnedNum > 360 {
        returnedNum = returnedNum - 360
      }
    } else if returnedNum < 0 {
      while returnedNum < 0 {
        returnedNum = returnedNum + 360
      }
    }
    return returnedNum
  }
  
  //Latitude values should not go above 180, below -180
  func clampLatitude(_ num: Float) -> Float {
    var returnedNum: Float = num
    if returnedNum > 180 {
      while returnedNum > 360 {
        returnedNum = returnedNum - 360
      }
    } else if returnedNum < -180 {
      while returnedNum < 0 {
        returnedNum = returnedNum + 360
      }
    }
    return returnedNum
  }
  
}

public enum CelestialBodyType: String {
  case mercury
  case venus
  case mars
  case jupiter
  case saturn
  case uranus
  case neptune
  case sun
  case moon
  
  static let allPlanets: [CelestialBodyType] = [.mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune]
  static let allBodies: [CelestialBodyType] = [.mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .sun, .moon]
}

public struct CelestialBodyCoordinates {
  public var latitude: Float
  public var longitude: Float
  public var distanceFromEarthCenter: Float
  public var altitude: Float?
  public var azimuth: Float?
  public var identifier: CelestialBodyType
  
  public func description() -> String {
    return "Location (\(self.latitude), \(self.longitude)); Altitude: \(self.distanceFromEarthCenter) KM"
  }
}



