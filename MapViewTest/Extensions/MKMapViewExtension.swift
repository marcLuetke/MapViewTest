// MKMapViewExtension.swift
// Created by Marc Lütke on 10.03.24.
//
// Copyright, 2023 - GapLabs, Schortens, Germany
// All rights reserved

import Foundation
import MapKit

extension MKMapView {
    func offsetPosition(coordinates:CLLocationCoordinate2D, radius:Double, heading:Double) -> CLLocationCoordinate2D {
        let offsetLatitude = cos(heading.toRadiant()) * radius
        let offsetLongitude = sin(heading.toRadiant()) * radius
        var offsetPoint = MKMapPoint(coordinates)
        let metersPerPoint = MKMetersPerMapPointAtLatitude(coordinates.latitude)
        offsetPoint.y += offsetLatitude / metersPerPoint
        offsetPoint.x += offsetLongitude / metersPerPoint
        return offsetPoint.coordinate
    }
}
