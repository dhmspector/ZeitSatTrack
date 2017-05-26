//
//  ZeitSatTrackManager.swift
//  ZeitSatTrack
//
//  Created by David Spector on 5/22/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import CoreLocation
import Foundation

extension URLSession {
    func synchronousDataTask(with url: URL) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = self.dataTask(with: url) {
            data = $0
            response = $1
            error = $2
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}

enum ZeitSatTrackStatus{
    case uninitialized  // user has authed, but locationmanager has yet to return 1st position
    case running        // we're running, will update location as necessary
    case paused         // for some reason cllocation has paused locaton updates (usally poor GPS signal)
    case stopped        // cllocation manager updates have been stopped
}

private let TLESources   =   "satellite-tle-sources"


public protocol ZeitSatTrackManagerDelegate : class {
  
    /// ZeitSatTrack satellite observer did return data
    ///
    /// - Parameter satelliteList: An array of Dictionaries representing satellite positions
    func didObserveSatellites(satelliteList: [Dictionary<String, GeoCoordinates>])
}

open class ZeitSatTrackManager: NSObject, CLLocationManagerDelegate {
    open static let sharedInstance = ZeitSatTrackManager()
    
    open weak var delegate:               ZeitSatTrackManagerDelegate?
    
    var tleSources              = Array<Dictionary<String, Any>>()
    var satsInView              = [Satellite]()
    var satellites              = [Satellite]()
    var observedSatellites      = [String]()            // names of satellites to overerve
    var observedCount:  Int {
        get {
        return self.observedSatellites.count
        }
    }
    var updateTimer:            Timer?
    
    var locationManager:        CLLocationManager?
    var currentState:           ZeitSatTrackStatus = .uninitialized
    var locationAuthStatus:     CLAuthorizationStatus?
    var continuousUpdateMode    = true

    public var location:        CLLocation?         // user's current location
    public var radius:          CLCircularRegion?
    public var updateDistance   = 15.24             // 50' in meters.
    public var updateInterval   = TimeInterval(2.0) // requested update frequency
    var        lastUpdated:     Date?
    
    override init() {
        super.init()
        
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager!.delegate = self
        }
        self.readTLESources()
    }
    
    
    // MARK: Primary API Functions
    /// Start continuous location updates
    ///
    /// - Returns: a CLAuthorizationStatus value depdning on if the user has authorized location usage
    open func enableContinuousLocationUpdates() -> CLAuthorizationStatus {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            self.locationManager?.startUpdatingLocation()
        }
        return authStatus
    }
    
    
    /// Start observing a satellite
    ///
    /// - Parameter name: the name of a satellite
    /// - Returns: A Bool - true if added, false if the named satellite cannot be found
    open func startObservingSatelliteNamed( _ name: String) -> Bool {
        var rv = false
        if alreadyExists(name: name) && !self.observedSatellites.contains(name){
            self.observedSatellites.append(name)
            rv = true
            if self.observedSatellites.count == 1 {
                // this is the first satellite - start the update timer/task
                self.startUpdateTimer()
            }
        }
        return rv
    }

    // MARK:  Observed Satellites
    
    /// Stop observing a satellite
    ///
    /// - Parameter name: the name of the stellite
    /// - Returns: A Bool - true if added, false if the named satellite cannot be found
    open func stopObservingSatelliteNamed( _ name: String) -> Bool {
        var rv = false
        if self.observedSatellites.contains(name){
            if let index = self.observedSatellites.index(of: name) {
                self.observedSatellites.remove(at:index)
                rv = true
                if self.observedSatellites.count == 0 {
                    // this is the first satellite - start the update timer/task
                    self.updateTimer?.invalidate()
                    self.updateTimer = nil
                }

            }
        }
        return rv
    }

    func postionsForObservedSatellites() {
        var rv = [Dictionary<String, GeoCoordinates>]()
        
        self.observedSatellites.forEach { (name) in
            let tmpPostion = self.locationForSatelliteNamed(name)
            rv.append([name:tmpPostion!])
        }
        self.delegate?.didObserveSatellites(satelliteList: rv)
    }
    
    func startUpdateTimer() {
        self.updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(postionsForObservedSatellites), userInfo: nil, repeats: true)
    }
    
    
    // MARK: Satellite Location API
    
    /// For a given named sat, get its current position or the position at the specifed date-time
    ///
    /// - Parameters:
    ///   - name: date at which the location is requested, or "now" if the no date is presented
    ///   - targetDate: The date for which the position info shojld be calculated
    /// - Returns: A GeoCoordinate struct
    open func locationForSatelliteNamed( _ name: String, targetDate: Date? = nil) -> GeoCoordinates? {
        var rv:GeoCoordinates? = nil
        if let satellite = self.satellites.filter({ sat in
            return sat.name == name
        }).first {
            rv = satellite.satellitePositionAt(date: targetDate == nil ? Date() : targetDate!)
        }
        return rv
    }
    

    /// Return a series of satellite positions between a specificed range of dates according to a deltermied interval in seconds
    ///
    /// - Parameters:
    ///   - name: the name of the satellite
    ///   - from: the starting date in the range (defaults to "now" if nil is passed)
    ///   - until: the ending date in the range
    ///   - interval: the number of seconds used as an interval (stride)
    /// - Returns: a dictionary keys on the date/interval and the resulting GeoCoodinates per interval
    open func locationsForSatelliteNamed(_ name: String, from: Date? = nil, until: Date, interval: Int = 2 ) -> Dictionary<Date, GeoCoordinates>? {
        var rv: Dictionary<Date, GeoCoordinates>?
        
        if self.alreadyExists(name: name) == true {
            var startDate: Date?
            var endDate: Date?

            if from == nil {
                startDate = Date()
            }
            rv = Dictionary<Date,GeoCoordinates>()
            // get the range of dates by _interval_
            // loop over then getting the sat poision 
            //for datesRange.each in date {
            //let tmPosition = self.locationForSatelliteNamed(name, targetDate: date)
            // }
        }
    return rv
    }

    
    /// return postions for observed satellites
    ///
    /// - Parameter date: target date
    /// - Returns: Array of dicitonaries with satellite names and Coordinates or nil
    open func observedSatelliteLocations(date: Date? = nil) -> [Dictionary<String, GeoCoordinates>]? {
        
        if self.observedSatellites.count == 0 {
            return nil
        }
        
        var rv = [Dictionary<String, GeoCoordinates>]()
        self.observedSatellites.forEach { (name) in
            let tmpPostion = self.locationForSatelliteNamed(name, targetDate: date != nil ? date! : Date() )
            rv.append([name:tmpPostion!])
        }
        return rv
    }

    
    /// return detailed orbital info for a satellite
    ///
    /// - Parameters:
    ///   - name: the name of the satellite
    ///   - targetDate: the date for which these paramets should be calculated
    /// - Returns: A dictionary with the orbital data
    open func orbitalInfoForSatelliteNamed(_ name: String, targetDate: Date? = nil) -> Dictionary<String, String>? {
        var rv = Dictionary<String,String>()
//        if let satellite = self.satellites.filter({ sat in
//            return sat.name == name
//        }).first {
//            rv = satellite.orbitalInfo()
//        }
        return rv
    }

    
    
    /// for all satellites, get  current position or the position at the specifed date-time
    ///
    /// - Parameter date: date at which the location is requested, or "now" if the no date is presented
    /// - Returns: an array of dictionaries containing the name and GeoCoordinates representing the lat/lon/alt of the satellite
    open func locationsForSatellites(date: Date? = nil) -> [Dictionary<String, GeoCoordinates>] {
        var allSatPositions = [Dictionary<String, GeoCoordinates>]()
        
        self.satellites.forEach { (satellite) in
            let position = satellite.satellitePositionAt(date: date == nil ? Date() : date!)
            let tmpDict = [satellite.name : position!]
            allSatPositions.append(tmpDict)
        }
        return allSatPositions
    }
    
    
    
    // MARK: Convenience Methods
    /// Return basic stats about contents of the satellite tracker
    ///
    /// - Returns: A dictionary containing basic stats
    open func stats() -> Dictionary<String, Any> {
        let locationStatus = CLLocationManager.authorizationStatus()
        return ["satellites": self.satellites.count,
                "visible": self.satsInView.count,
                "location":self.location as Any,
                "locatonPermissions" : locationStatus as Any
        ]
    }
    
    // Various ways of listing the satellites we've loaded
    
    
    /// Returns a the list of known satellites by name
    ///
    /// - Returns: a string array of satellite names
    open func trackedSatsByName() -> [String] {
        return self.satellites.map({$0.name})
    }
    
    /// Returns a the list of known satellites by catalog number
    ///
    /// - Returns: an Int array of satellite catalog numbers
    open func trackedSatsByCatalogNumber() -> [Int] {
        return self.satellites.map({$0.satCatNumber})
    }
    
    /// Returns a the list of known satellites by COSPAR number
    ///
    /// - Returns: a String array of satellite COSPAR numbers
    open func trackedSatsByCosparID() -> [String] {
        return self.satellites.map({$0.cosparID})
    }
    
    
    // MARK: Utils
    func alreadyExists(name: String) -> Bool {
        return self.satellites.first(where: { $0.name == name }) != nil
    }
    
    
    
    // MARK: CLLocationManagerDelegate Delegates
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
        self.lastUpdated = Date()
    }
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthStatus = status
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
          _ =  self.enableContinuousLocationUpdates()
        case .denied, .notDetermined, .restricted:
            self.locationManager?.stopUpdatingLocation()
        }
    }
    
    // MARK: TLE Reading/Parsing
    func readTLESources() {
        let bundle = Bundle(for: ZeitSatTrackManager.self)
        let path =  bundle.path(forResource: TLESources, ofType: "json")
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!)) {
            self.tleSources = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! Array<Dictionary<String, Any>>
        } else {
            print("Unable to read TLE Source file")
        }
    }
    

     /// Add a new master source list to the available catalog of satellite collections
     /// - Parameters:
     /// -  filename: JSON file containing group and TLE dictionaries
     /// -  bundle: the bundle from which this file can be loaded
    open func adddTLESourcesFromFile(_ fileName:String, bundle: Bundle) {
        let path =  bundle.path(forResource: fileName, ofType: "json")
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!)) {
            let newTLEs = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! Array<Dictionary<String, Any>>
            self.tleSources.append(contentsOf: newTLEs)
        } else {
            print("Unable to read TLE Source file")
        }
    }
    

    /// Loads collections of TLE data for the named satellite group into this manager
    ///
    /// - Parameter name: name of the group to load from the TLE Sources list
    open func loadSatelliteCollectionForGroup(name: String) {
        if let tleDictionary = self.tleListForGroupNamed(name) {
            tleDictionary.forEach({ (dict) in
                print("Processing \(dict["name"]!), TLE URL: \(dict["data_file"]!)...")
                if let tleData = self.tleDataForURL(dict["data_file"]!) {
                    self.addSatellitesFromTLEData(tleString: tleData)
                }
            })
        }
    }
    
    
    /// loads a specific subgroup of satellite TLEs from a larger group collection
    ///
    /// - Parameters:
    ///   - subgroupName: subgroupName - name of the specific satellite group
    ///   - group: name of the enclosing colleciton of satellites
    /// - Returns: nil, or Error if the group or subgroup cannot be found (404), or if there is a timeout or other network error (500)
    open func loadSatelliteSubGroup(subgroupName:String, group: String) -> Error? {
        var error: Error?
        
        if let tleDictionary = self.tleListForGroupNamed(group) {
            if let targetTLE = tleDictionary.filter({ dictionary in
                return dictionary["name"] == subgroupName
            }).first {
                if let tleData = self.tleDataForURL(targetTLE["data_file"]!) {
                    self.addSatellitesFromTLEData(tleString: tleData)
                } else {
                    // unable to get the TLE data from the remote site
                    error = NSError(domain: "Unable to load remote URL", code: 500, userInfo: nil)
                }
            } else {
                // unable to fine the specific TLE subgroup in the named group
                error = NSError(domain: "TLE Subgroup (\(subgroupName)) not found in specified group (\(group))", code: 404, userInfo: nil)
            }
        } else {
            // unable to find he specified salellite grou in our master list
            error = NSError(domain: "Satellite group (\(group)) not fond in master list", code: 404, userInfo: nil)
        }
        return error
    }
    
    
    /// Names of available satellite collections
    ///
    /// - Returns: an array of names of satellite collections known t this library
    open func satelliteCollections() -> [String] {
        return self.tleSources.map({ $0["group_name"]! as! String })
    }
    
    /// list of satellite collections contained inside the named group
    ///
    /// - Parameter name: Group to enumerate
    /// - Returns: An array of Strings with the names of the satellite colletions in the named group
    open func subGroupsForCollection(name:String) -> [String] {
        var rv = [String]()
        if let satGroup = self.tleListForGroupNamed(name) {
            rv = (satGroup.map({$0[$0.keys.first!]!}))
        }
        return rv
    }
    
    
    /// an array of dictionaries TLE name/URL pairs) for a given collection
    ///
    /// - Parameter name: name of the requested group
    /// - Returns: an array of dictionaries containing name/URL pairs representing a TLE collection
    open func tleListForGroupNamed(_ name: String) ->  [Dictionary<String, String>]? {
        var rv: [Dictionary<String, String>]?
        theLoop: for dict in self.tleSources {
            if dict["group_name"] as! String == name {
                rv = (dict["files"] as! [Dictionary<String, String>])
                break theLoop
            }
        }
        return rv
    }
    

    /// Get TLE data from the specified URL or nil if unavailable for any reason (timeouts, etc)
    ///
    /// - Parameter url: the UR of a remote TLE document
    /// - Returns: a string presenting the contents of a TLE file
    open func tleDataForURL(_ url:String) -> String? {
        var rv: String?
        
        if url.isEmpty == false {
            let (data, _, error) = URLSession.shared.synchronousDataTask(with: URL(string: url)!)
            if let data = data {
                //rv = String(data: data , encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                rv = String(data: data , encoding: .utf8)
            } else {
                if let error = error {
                    print("Errror retreiving data from \(url): \(error.localizedDescription)")
                }
            }
        }
        return rv
    }
    
    /// Fetch TLE file for a named satellite collection from CelesTrack.com
    ///
    /// - Parameters:
    ///   - name: satellite group name (from the tleSources managed by this library)
    ///   - subGroupName: subGroupName the satellie collection to fetch; this is a TLE collection file from CelesTrak.com
    /// - Returns: the TLE data for a given collection of Sats in the named group
    open func tleDataForSatelliteGroup(_ name:String, subGroupName: String) -> String? {
        var rv: String?
        var URLString = ""
        if let tleCollection  = self.tleListForGroupNamed(name) {
            theLoop: for element in tleCollection {
                if element["name"]  == subGroupName {
                    URLString = element["data_file"]!
                    break theLoop
                }
            }
        }
        if URLString.isEmpty == false {
            
            let (data, _, error) = URLSession.shared.synchronousDataTask(with: URL(string: URLString)!)
            if let data = data {
                rv = String(data: data , encoding: .utf8)
            } else {
                if let error = error {
                    print("Errror retreiving data from \(URLString): \(error.localizedDescription)")
                }
            }
        }
        return rv
    }
    
    
    // NB: this is pure oribtal info.  @TODO: we should make a different structure to hold meta-data
    // like descriptive info on each sat, using the sat's catalog name (or number) as the key
    
    /// Add satellites to the manager from a array of Two Line Elements
    ///
    /// - Parameter tleString: a string representing one or more TLE stanzas
    open func addSatellitesFromTLEData(tleString:String) {
        let responseArray = tleString.components(separatedBy: "\n")
        let tleCount = responseArray.count / 3
        
        for i in 0..<tleCount {
            let satName = responseArray[ i * 3].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let lineOne = responseArray[1 + i * 3]
            let lineTwo = responseArray[2 + i * 3]
            
            if satName.lengthOfBytes(using: .utf8) > 0  && alreadyExists(name: satName) == false {
                //print("\(satName)")
                let twoLineElementSet = TwoLineElementSet(nameOfSatellite: satName, lineOne: lineOne, lineTwo: lineTwo)
                let satellite = Satellite(twoLineElementSet: twoLineElementSet)
                self.satellites.append(satellite)
            } //of name length & duplication check
        } // of TLE processing loop
    }
    
    
    
}
