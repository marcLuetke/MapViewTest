// MapView.swift
// Created by Marc Lütke on 10.03.24.
//
// Copyright, 2023 - GapLabs, Schortens, Germany
// All rights reserved

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var mapView: MKMapView
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = mapView
        DispatchQueue.main.async(execute: {
            let guide = mapView.safeAreaLayoutGuide
            //MapCompass
            let compassButton = MKCompassButton(mapView: mapView)
            compassButton.frame.origin = CGPoint(x: mapView.frame.midX - 0, y: mapView.frame.minY - -60)
            compassButton.translatesAutoresizingMaskIntoConstraints = false
            compassButton.compassVisibility = .adaptive
            mapView.addSubview(compassButton)
            
            NSLayoutConstraint.activate([
                compassButton.rightAnchor.constraint(equalTo: guide.rightAnchor, constant: -20),
                // top margin is the top safe area
                compassButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 120),
            ])
        })
        
        mapView.delegate = context.coordinator
        mapView.setCameraZoomRange(.init(minCenterCoordinateDistance: 150.0, maxCenterCoordinateDistance: 100000.0), animated: true)
        mapView.mapType = .hybrid
        mapView.userTrackingMode = .none
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsScale = false
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the map view when necessary
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        // Implement map view delegate methods if needed
    }
}
