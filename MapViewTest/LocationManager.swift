// LocationManager.swift
// Created by Marc Lütke on 10.03.24.
//
// Copyright, 2023 - GapLabs, Schortens, Germany
// All rights reserved

import SwiftUI
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var manager: CLLocationManager = CLLocationManager()
    @Published var permissionDenied: Bool = false
    @Published var location: CLLocation? = nil
    @Published var trueHeading: CLLocationDirection = 0
    
    override init() {
        super.init()
        setHeadingOrientation()
        manager.showsBackgroundLocationIndicator = true
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestWhenInUseAuthorization()
        manager.requestAlwaysAuthorization()
        manager.delegate = self
    }
    
    func setHeadingOrientation() {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            manager.headingOrientation = .landscapeLeft
        case .landscapeRight:
            manager.headingOrientation = .landscapeRight
        default:
            break
        }
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied:
            // Alert
            permissionDenied.toggle()
        case .notDetermined:
            // Requesting
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.location = location
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 { return }
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        trueHeading = heading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        // Error:
        print(error.localizedDescription)
    }
}
