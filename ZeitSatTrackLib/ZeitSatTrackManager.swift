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

//@objc protocol ZeitSatTrackManagerDelegate : class {
//    @objc optional func assetDidComeIntoView(satellites: NSArray)
//    @objc optional func assetDidLeaveView(satellites:NSArray)
//}

open class ZeitSatTrackManager: NSObject, CLLocationManagerDelegate {
    open static let sharedInstance = ZeitSatTrackManager()
    
    //weak var delegate:               ZeitSatTrackManagerDelegate?
    
    var tleSources              = Array<Dictionary<String, Any>>()
    var satsInView              = [Satellite]()
    var satellites              = [Satellite]()

    var locationManager:        CLLocationManager?
    var currentState:           ZeitSatTrackStatus = .uninitialized
    var continuousUpdateMode    = true
    var location:               CLLocationCoordinate2D? // user's current location
    var radius:                 CLCircularRegion?
    
    override init() {
        super.init()
        
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager!.delegate = self
        }
        self.readTLESources()
    }
    
    

    // MARK: Satellite Location API
    
    /**
     * for a given named sat, get its current position or the position at the specifed date-time
     * @param date at which the location is requested, or "now" if the no date is presented
     * @return GeoCoordinates representing the lat/lon/alt of the satellite
     */
    open func locationForSatelliteNamed( _ name: String, targetDate: Date? = nil) -> GeoCoordinates? {
        var rv:GeoCoordinates? = nil
        if let satellite = self.satellites.filter({ sat in
            return sat.name == name
        }).first {
            rv = satellite.satellitePositionAt(date: targetDate == nil ? Date() : targetDate!)
        }
        return rv
    }
    
    /**
     * for all satellites, get  current position or the position at the specifed date-time
     * @param date at which the location is requested, or "now" if the no date is presented
     * @return an array of dictionaries containing the name and GeoCoordinates representing the lat/lon/alt of the satellite
     */
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
    open func stats() -> Dictionary<String, Any> {
        let locationStatus = CLLocationManager.authorizationStatus()
        return ["satellites": self.satellites.count,
                "visible": self.satsInView.count,
                "location":self.location as Any,
                "locatonPermissions" : locationStatus as Any
        ]
    }
    
    // Various ways of listing the satellites we've loaded
    open func trackedSatsByName() -> [String] {
        return self.satellites.map({$0.name})
    }
    
    open func trackedSatsByCatalogNumber() -> [Int] {
        return self.satellites.map({$0.satCatNumber})
    }
    
    open func trackedSatsByCosparID() -> [String] {
        return self.satellites.map({$0.cosparID})
    }
    
    
    // MARK: Utils
    func alreadyExists(name: String) -> Bool {
        return self.satellites.first(where: { $0.name == name }) != nil
    }
    
    
    
    // MARK: CLLocationManagerDelegate Delegates
    // TBD
    
    
    // MARK: TLE Reading/Parsing
    // reads in our json source of sat TLE files
    func readTLESources() {
        let bundle = Bundle(for: ZeitSatTrackManager.self)
        let path =  bundle.path(forResource: TLESources, ofType: "json")
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!)) {
            self.tleSources = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! Array<Dictionary<String, Any>>
        } else {
            print("Unable to read TLE Source file")
        }
    }

    /**
     * Add a new master source list to the available catalog of satellite collections
     * @param filename - JSON file containing group and TLE dictionaries
     * @param bindle - the bundle from which this file can be loaded
     */
    open func adddTLESourcesF(fileName:String, bundle: Bundle) {
        let path =  bundle.path(forResource: fileName, ofType: "json")
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!)) {
            let newTLEs = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! Array<Dictionary<String, Any>>
            self.tleSources.append(contentsOf: newTLEs)
        } else {
            print("Unable to read TLE Source file")
        }
    }

    /**
     * Loads collections of TLE data for the named satellite group into this manager
     * @param name of the group to load from the TLE Sources list
     */
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
    
    
    /**
     * loads a specific subgroup of satellite TLEs from a larger group collection
     * @param subgroupName - name of the specific satellite group
     * @param group - name of the enclosing colleciton of satellites
     * @return nil, or error if the group or subgroup cannot be found (404), or if there is a timeout or other network error (500)
     */
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
    
    
    /**
     * Names of available satellite collections
     * @return an array of names of satellite collections known t this library
     */
    open func satelliteCollections() -> [String] {
        return self.tleSources.map({ $0["group_name"]! as! String })
    }
    
    // returns an array of dictionaries TLE name/URL pairs) for a given collection
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
    
    /**
     * Get TLE data from the specified URL or nil if unavailable for any reason (timeouts, etc)
     * @return a string presenting the contents of a TLE file
     */
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
    
    /**
     * Fetch TLE file for a named satellite collection from CelesTrack.com
     * @param satellite group name (from the tleSources managed by this library)
     * @param subGroupName the satellie collection to fetch; this is a TLE collection file from CelesTrak.com
     * @returns the TLE data for a given collection of Sats in the named group
     */
    // returns the TLE data for a given collection of Sats in the named group
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
                //rv = String(data: data , encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
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
    
    /**
     * Add satellites to the manager from a array of Two Line Elements
     */
    func addSatellitesFromTLEData(tleString:String) {
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
