//
//  ZeitSatTrackLibTests.swift
//  ZeitSatTrackLibTests
//
//  Created by David Spector on 5/22/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import XCTest
@testable import ZeitSatTrackLib

class ZeitSatTrackLibTests: XCTestCase {
    
  var sun: CelestialBody!
  var moon: CelestialBody!
  var mars: CelestialBody!
  
  override func setUp() {
    super.setUp()
    
    sun = CelestialBody(type: .sun)
    moon = CelestialBody(type: .moon)
    mars = CelestialBody(type: .mars)
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    sun = nil
    moon = nil
    mars = nil
    super.tearDown()
  }
  
  func testJan1_2000() {
    
    // 1. given
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let components = DateComponents(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0)
    let testDate = calendar.date(from: components)!
    
    //Chandigarh
    let testCoordinates = GeoCoordinates(latitude: 30.7333, longitude: 76.7794, altitude: 0)
    
    
    // 2. when
    sun.initializeCalculations(forDate: testDate, givenSun: sun)
    sun.calculateAltitudeAndAzimuth(coordinates: testCoordinates)
    
    moon.initializeCalculations(forDate: testDate, givenSun: sun)
    moon.calculateAltitudeAndAzimuth(coordinates: testCoordinates)
    
    mars.initializeCalculations(forDate: testDate, givenSun: sun)
    mars.calculateAltitudeAndAzimuth(coordinates: testCoordinates)
    
    
    // 3. then    //Check values against 3rd party
    XCTAssertEqual(sun.latitude, -23.07201, "Sun latitude incorrect for test date 1")
    XCTAssertEqual(sun.longitude, 180.766785, "Sun longitude incorrect for test date 1")
    XCTAssertEqual(sun.altitude, -23.0425529, "Sun altitude incorrect for test date 1")
    XCTAssertEqual(sun.azimuth, 104.037621, "Sun azimuth incorrect for test date 1")
    
    XCTAssertEqual(moon.latitude, -9.134998, "moon latitude incorrect for test date 1")
    XCTAssertEqual(moon.longitude, 115.872955, "moon longitude incorrect for test date 1")
    XCTAssertEqual(moon.altitude, 34.78246, "moon altitude incorrect for test date 1")
    XCTAssertEqual(moon.azimuth, 129.630264, "moon azimuth incorrect for test date 1")
    
    XCTAssertEqual(mars.latitude, -13.32201, "mars latitude incorrect for test date 1")
    XCTAssertEqual(mars.longitude, 230.175415, "mars longitude incorrect for test date 1")
    XCTAssertEqual(mars.altitude, -59.9539452, "mars altitude incorrect for test date 1")
    XCTAssertEqual(mars.azimuth, 60.4970245, "mars azimuth incorrect for test date 1")
  }
    
}
