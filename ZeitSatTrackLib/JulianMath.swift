//
//  JulianMath.swift
//  ZeitSatTrack
//
//  Created by David HM Spector on 5/12/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import Foundation

class JulianMath {
    /**
     * Given a Gregorian date after 01-JAN-1970, return the Julian Date
     * @return the Julian date, or 0 if source date is before the base date of 01-JAN-1970
     */
    class func julianDateFromDate(date: Date) -> Double {
        let baseDate = Date(timeIntervalSince1970: date.timeIntervalSince1970 * -1) // 1970
        if date.compare(baseDate) == ComparisonResult.orderedAscending {
            // means the date provided is befor the base date ... and therefore invalid
            return 0
        }
        let JD_JAN_1_1970_0000GMT = 2440587.5;
        return JD_JAN_1_1970_0000GMT + date.timeIntervalSince1970 / 86400
    }

    /**
     * Returns the current time as the number of integer seconds since the first instant of 1 January 2001, GMT
     *
     * @return Current time in seconds since 1/1/1
     */
    class func secondsSinceReferenceDate(_ date: Date? = nil) -> Double {
        var theDate: Date?
        if date != nil {
            theDate = date
        } else {
            theDate = Date()
        }
        let refDate = theDate?.timeIntervalSinceReferenceDate
        return floor(refDate!)
    }
    
    /**
     * Returns the Julian date for the given number of seconds since the first second of 1 January 2001, GMT
     * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
     *
     * @param secondsSinceReferenceDate The number of seconds since the first instant of 1 January 2001, GMT
     * @return String timestamp
     */
    class func utcTimestampFromSecondsSinceReferenceDate(secondsSinceReferenceDate: Double) -> String {
        let date = Date(timeIntervalSinceReferenceDate: secondsSinceReferenceDate)
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en_US_POSIX")
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        dateformatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let timeString = dateformatter.string(from: date)
        return timeString
    }
    
    /**
     * Returns the Julian date for the given number of seconds since the first second of 1 January 2001, GMT
     * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
     *
     * @param secondsSinceReferenceDate The number of seconds since the first instant of 1 January 2001, GMT
     * @return Julian date for the given time
     */
    class func julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: Double) -> Double {
        let secondsPerDay = 86400.0
        return 2451910.5 + secondsSinceReferenceDate / secondsPerDay
    }
    
    
    /**
     * Returns a Julian date which corresponds to 0h UT for the given Julian Date
     * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
     *
     * @param julianDate The julian date
     * @return Julian date for 0h UT
     */
    class func zeroHourUTJulianDateforJulianDate(julianDate: Double) -> Double {
        return (floor(julianDate - 0.5) + 0.5)
    }
    
    /**
     * Returns the number of minutes (including fractional minutes) since 0h UT (aka midnight) for the given Julian Date
     * Note: Treats UTC as == UT (when in fact they can differ by 0 to 0.9 seconds)
     *
     * @param julianDate The julian date
     * @return Minutes since UT midnight
     */
    class func minutesSinceZeroHourUTforJulianDate(julianDate: Double) -> Double {
        let minutesPerDay = 1440.0
        let zeroHourUTJD = zeroHourUTJulianDateforJulianDate(julianDate: julianDate)
        return (minutesPerDay * (julianDate - zeroHourUTJD));
    }
    
    
    /**
     * Returns alpha g,o - the angle of the Greenwich meridian at 0h UT on the given Julian Date - in degrees
     * Based on http://aa.usno.navy.mil/faq/docs/GAST.php
     *
     * @param julianDate The julian date
     * @return Right ascension of the Greenwich meridian in degrees
     */
    class func angleofGreenwichMeridianAtZeroHourUTforJulianDate(julianDate: Double) -> Double {
        let zeroHourUTJulianDate = zeroHourUTJulianDateforJulianDate(julianDate: julianDate)
        let  julianDaysSince2000January1NoonUT = zeroHourUTJulianDate - 2451545.0
        let julianCenturiesSince2000 = floor(julianDaysSince2000January1NoonUT / 36525.0)
        var greenwichMeanSiderealTimeAtZeroHourUTInHours = 6.697374558 + 0.06570982441908 * julianDaysSince2000January1NoonUT + 0.000026 * julianCenturiesSince2000 * julianCenturiesSince2000
        // reduce it to 0 to 24 h
        let  days = floor( greenwichMeanSiderealTimeAtZeroHourUTInHours / 24.0 )
        greenwichMeanSiderealTimeAtZeroHourUTInHours = greenwichMeanSiderealTimeAtZeroHourUTInHours - days * 24
        // turn it into an angle
        return (greenwichMeanSiderealTimeAtZeroHourUTInHours * 360.0 / 24.0)
    }
    
    /**
     * Returns Omega e * T e - the angle the coordinate system attached to the earth (xr, yr, zr) has
     * rotated with respect to the geocentric equatorial coordinate system (xi, yi, zi)
     * for the given julianDate
     * Based on eq 2.51 from "Satellite Communications" by Timothy Pratt, 1986
     *
     * @param julianDate The julian date
     * @return Rotation in degrees
     */
    class func rotationFromGeocentricforJulianDate(julianDate: Double) -> Double {
        let  rightAscensionGreenwichAtZeroHour = angleofGreenwichMeridianAtZeroHourUTforJulianDate(julianDate: julianDate)
        let  minutesSinceUTMidnight = minutesSinceZeroHourUTforJulianDate(julianDate: julianDate)
        return (rightAscensionGreenwichAtZeroHour + 0.25068447 * minutesSinceUTMidnight);
    }
    
}
