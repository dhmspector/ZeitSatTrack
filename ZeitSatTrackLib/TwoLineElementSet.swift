//
//  TwoLineElementZet.swift
//  ZeitSatTrack
//
//  Created by David HM Spector on 5/12/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import Foundation

extension String
{
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    // for convenience we should include String return
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
        let end = self.index(self.startIndex, offsetBy: r.upperBound)
        
        return self[start...end]
    }
}


class TwoLineElementSet {

    // Line 0
    var nameOfSatellite:        String = ""
    
    // Line 1
    var satcatNumber:            Int = 0                                    // http://en.wikipedia.org/wiki/Satellite_Catalog_Number
    var cosparID:                String = ""                                // http://en.wikipedia.org/wiki/International_Designator
    var epochYear:               Int = 0
    var epochJulianDateFraction: Double = 0.0
    
    // Line 2
    var inclination:            Double = 0.0                                // i, degrees
    var rightAscensionOfTheAscendingNode: Double = 0.0                      // Ω, degrees
    var eccentricity:           Double = 0.0                                // e, degrees
    var argumentOfPerigee:      Double = 0.0                                // degrees
    var meanAnomaly:            Double = 0.0                                // degrees
    var meanMotion:             Double = 0.0                                // The number of orbits the satellite completes in a day
    var revolutionNumber:       Int = 0
    
    convenience init(nameOfSatellite: String, lineOne: String, lineTwo:String) {
        self.init()
        
    // An example TLE
    //
    //           1         2         3         4         5         6         7
    // 01234567890123456789012345678901234567890123456789012345678901234567890123456789
    // 1 25544U 98067A   14332.12480567  .00017916  00000-0  30378-3 0  4720
    // 2 25544  51.6474   6.7919 0007352  75.3130 346.0866 15.51558891916767

        self.nameOfSatellite = nameOfSatellite
        //print("Sat name \(self.nameOfSatellite)")
        
        //print("line 1: \"\(lineOne.trimmingCharacters(in: CharacterSet.newlines))\"")

        let satCatNumberOffset = 2
        let satCatNumberLength = (satCatNumberOffset + 5) - 1
        let tmpCatNumberString = lineOne[satCatNumberOffset..<satCatNumberLength]
        satcatNumber = Int(tmpCatNumberString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("tmpCatNumberString \"\(tmpCatNumberString)\"")
        
        let launchYearStringOffset = 9
        let launchYearStringLength = (launchYearStringOffset + 2) - 1
        let launchYearString = lineOne[launchYearStringOffset..<launchYearStringLength]
        var launchYear = Int(launchYearString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("launchYearString \"\(launchYearString)\"")
        
        if 57 > launchYear {
            launchYear += 2000;
        } else {
            launchYear += 1900;
        }
        
        let launchSequentialIdentiferOffset = 11
        let launchSequentialIdentiferLength = (launchYearStringOffset + 4) - 1
        let launchSequentialIdentiferString = lineOne[launchSequentialIdentiferOffset..<launchSequentialIdentiferLength]
        
        cosparID = "\(launchYear)-\(launchSequentialIdentiferString.trimmingCharacters(in: CharacterSet.whitespaces))"
        //print("launchSequentialIdentiferString \"\(launchSequentialIdentiferString)\" cosparID \"\(cosparID)\" ")
        
        
        let epochYearOffset = 18
        let epochYearLength = (epochYearOffset + 2) - 1
        let epochYearString = lineOne[epochYearOffset..<epochYearLength]
        var epochYear = Int(epochYearString.trimmingCharacters(in: CharacterSet.whitespaces))
        //print("epochYearString \"\(epochYearString)\"")
        
        if (epochYear! >= 57) {
            epochYear = epochYear! + 1900;
        } else {
            epochYear = epochYear! + 2000;
        }
        
        
        let epochJulianDateFractionOffset = 20
        let epochJulianDateFractionLength = (epochJulianDateFractionOffset + 12) - 1
        let epochJulianDateFractionString = lineOne[epochJulianDateFractionOffset..<epochJulianDateFractionLength]
        epochJulianDateFraction = Double(epochJulianDateFractionString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("epochJulianDateFractionString \"\(epochJulianDateFractionString)\"")
        
        let inclinationOffset = 9 // was 8
        let inclinationLength = (inclinationOffset + 8) - 1
        let inclinationString = lineTwo[inclinationOffset..<inclinationLength]
        inclination = Double(inclinationString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("inclinationString \"\(inclinationString)\"")
        
        
        let rightAscensionOfTheAscendingNodeOffset = 17
        let rightAscensionOfTheAscendingNodeLength = (rightAscensionOfTheAscendingNodeOffset + 7)
        let rightAscensionOfTheAscendingNodeString = lineTwo[rightAscensionOfTheAscendingNodeOffset..<rightAscensionOfTheAscendingNodeLength]
        rightAscensionOfTheAscendingNode = Double(rightAscensionOfTheAscendingNodeString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("rightAscensionOfTheAscendingNodeString \"\(rightAscensionOfTheAscendingNodeString)\"")
        
        let eccentricityStringOffset = 26
        let eccentricityStringLength = (eccentricityStringOffset + 7)  - 1
        let eccentricityString = lineTwo[eccentricityStringOffset..<eccentricityStringLength]
        let eccentricityStringAsDouble = "0.\(eccentricityString.trimmingCharacters(in: CharacterSet.whitespaces))"
        eccentricity = Double(eccentricityStringAsDouble)!
        //print("eccentricityString \"\(eccentricityString)\"  eccentricityStringAsDouble  \"\(eccentricityStringAsDouble)\" ")
        
        let argumentOfPerigeeOffset = 34
        let argumentOfPerigeeLength = (argumentOfPerigeeOffset + 8)
        let arguementOfPerigeeString = lineTwo[argumentOfPerigeeOffset..<argumentOfPerigeeLength]
        argumentOfPerigee = Double(arguementOfPerigeeString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("arguementOfPerigeeString \"\(arguementOfPerigeeString)\"")
        
        let meanAnomalyOffset = 43
        let meanAnomalyLength = (meanAnomalyOffset + 8) - 1
        let meanAnomalyString = lineTwo[meanAnomalyOffset..<meanAnomalyLength]
        meanAnomaly = Double(meanAnomalyString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("meanAnomolyString \"\(meanAnomalyString)\"")
        
        let meanMotionOffset = 52
        let meanMotionLength = (meanMotionOffset + 11) - 1
        let meanMotionString = lineTwo[meanMotionOffset..<meanMotionLength]
        meanMotion = Double(meanMotionString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("meanMotionString \"\(meanMotionString)\"")
        
        let revolutionNumberOffset = 63
        let revolutionNumberLength = (revolutionNumberOffset + 5)
        let revolutionNumberString = lineTwo[revolutionNumberOffset..<revolutionNumberLength]
        revolutionNumber = Int(revolutionNumberString.trimmingCharacters(in: CharacterSet.whitespaces))!
        //print("revolutionNumberString \"\(revolutionNumberString)\"")
        
    }
    
    
    func semimajorAxis() -> Double {
      let keplersConstant = 398613.52   // km^3/s^2
      let meanMotionPerSec = self.meanMotion / 86400.0
      return pow(keplersConstant / (4.0 * .pi * .pi * meanMotionPerSec * meanMotionPerSec), 1.0/3.0);
    }
    
    
    func orbitalPeriod() -> Double {
        return (86400.0 / self.meanMotion);
    }
    
    func meanMotionAsAngularVelocity() -> Double {
        let orbitalPeriod = self.orbitalPeriod()
       return 360.0 / orbitalPeriod
    }


    
    func epochAsJulianDate() -> Double {
        var calendar =  Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = DateComponents()
        components.year = self.epochYear
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        let epochFirstDayOfYear = calendar.date(from: components)
        let epochFirstDayOfYearSecondsSinceReferenceDate = floor((epochFirstDayOfYear?.timeIntervalSinceReferenceDate)!)
        let epochFirstDayOfYearJulianDate = 2451910.5 + epochFirstDayOfYearSecondsSinceReferenceDate / 86400.0
        
         return epochFirstDayOfYearJulianDate + self.epochJulianDateFraction - 1.0; // TLE contains julian day of year (therefore first day is day 1 not 0)
    }

    
    func meanAnomalyForJulianDate(julianDate: Double) -> Double {
        let epochJulianDate = self.epochAsJulianDate()
        let daysSinceEpoch = julianDate - epochJulianDate
        let revolutionsSinceEpoch = self.meanMotion * daysSinceEpoch
        let  meanAnomalyForJulianDate = self.meanAnomaly + revolutionsSinceEpoch * 360.0
        let fullRevolutions = floor(meanAnomalyForJulianDate / 360.0)
        return meanAnomalyForJulianDate - 360.0 * fullRevolutions
    }
    
    
    
    func eccentricAnomalyForMeanAnomaly(meanAnomaly: Double) -> Double {
        // For a circular orbit, the Eccentric Anomaly and the Mean Anomaly are equal

        if self.eccentricity == 0 {
            return meanAnomaly
        }
        
        // Otherwise, do Newton–Raphson to solve Kepler's Equation : M = E - e * sin(E)
        // Start with the estimate = meanAnomaly converted to radians

        var estimate = 0.0
        var estimateError = 0.0
        let meanAnomalyInRadians = meanAnomaly * .pi / 180.0
        var previousEstimate = meanAnomalyInRadians;
        
        // Now, iterate until the delta < 0.0001
        repeat {
            estimate = previousEstimate - (previousEstimate - self.eccentricity * sin(previousEstimate) - meanAnomalyInRadians) / ( 1 - self.eccentricity * cos(previousEstimate) );
            estimateError = fabs(estimate - previousEstimate);
            previousEstimate = estimate;
        } while (estimateError > 0.0001);
        
        return (estimate * 180.0 / .pi)
    }
    
    /**
     * Based on http://en.wikipedia.org/wiki/True_anomaly
     */
    func trueAnomalyForEccentricAnomaly(eccentricAnomaly: Double) -> Double {
        let halfEccentricAnomalyRad = (eccentricAnomaly * .pi / 180.0) / 2.0
        return 2.0 * atan2(sqrt(1 + self.eccentricity) * sin(halfEccentricAnomalyRad), sqrt(1 - self.eccentricity) * cos(halfEccentricAnomalyRad)) * 180.0 / .pi
    }
} // of Two Line Element
