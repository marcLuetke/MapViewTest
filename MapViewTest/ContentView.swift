// MKMapViewExtension.swift
// Created by Marc Lütke on 10.03.24.
//
// Copyright, 2023 - GapLabs, Schortens, Germany
// All rights reserved

import SwiftUI
import MapKit

// Das Ziel ist es die Karte nach links zu verschieben, sobald die DetailView gezeigt wird.
// Das ist momentan der Fall, wenn man den Button DETAIL drückt.
// Diese Funktionalität möchte ich auch gerne haben, wenn der User getrackt wird.
// Also wenn UserTracking an ist und man die DetailView zeigt, soll sich alles nach links verschieben, damit in dem noch sichtbaren Teil der Karte die Position des Users mittig im unteren drittel der Karte angezeigt wird. Das Drehen der Karte beim Tracking berücksichtigen.

struct ContentView: View {
    @ObservedObject private var locationManager = LocationManager()
    @State private var mapView: MKMapView = MKMapView()
    @State private var isDetailViewVisible: Bool = false
    @State private var isTrackingUserWithCamera: Bool = false
    @State private var isTrackingUserFollowWithHeading: Bool = false
    
    var body: some View {
        ZStack {
            MapView(mapView: $mapView)
                .ignoresSafeArea()
            if isTrackingUserWithCamera {
                Text("UserHeading: \(locationManager.trueHeading)")
                    .offset(y: 50)
            }
            if isDetailViewVisible {
                DetailView()
            }
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    Button("User") {
                        jumpToUser()
                    }
                    Button("Tracking mit Kamera") {
                        setUserTrackingForCamera()
                    }
                    .tint(isTrackingUserWithCamera ? .green : .red)
                    Button("Tracking FollowWithHeading") {
                        setUserTrackingFollowWithHeading()
                    }
                    .tint(isTrackingUserFollowWithHeading ? .green : .red)
                    Button("Detail") {
                        toggleDetailView()
                    }
                    .tint(isDetailViewVisible ? .green : .red)
                    Button("+Marker") {
                        addMarkerAtUserLocation()
                    }
                    Button("-Marker") {
                        mapView.removeAnnotations(mapView.annotations)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.leading, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .onAppear(perform: {
            locationManager.requestLocation()
        })
        .onChange(of: locationManager.trueHeading) {
            setCameraForUserTracking()
        }
        .onChange(of: isDetailViewVisible) {
            observeDetailViewState()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension ContentView {
    func jumpToUser() {
        if let location = locationManager.location?.coordinate {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            withAnimation {
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func setUserTrackingForCamera() {
        isTrackingUserFollowWithHeading = false
        if !isTrackingUserWithCamera {
            isTrackingUserWithCamera = true
            locationManager.manager.startUpdatingLocation()
            locationManager.manager.startUpdatingHeading()
        } else {
            isTrackingUserWithCamera = false
            locationManager.manager.stopUpdatingLocation()
            locationManager.manager.stopUpdatingHeading()
        }
    }
    
    func setUserTrackingFollowWithHeading() {
        // Wenn User getrackt wird und man dann die DetailView öffnet, springt das Tracking wieder auf .none
        locationManager.manager.stopUpdatingLocation()
        locationManager.manager.stopUpdatingHeading()
        isTrackingUserWithCamera = false
        if mapView.userTrackingMode == .none {
            isTrackingUserFollowWithHeading = true
            mapView.userTrackingMode = .followWithHeading
        } else {
            isTrackingUserFollowWithHeading = false
            mapView.userTrackingMode = .none
        }
    }
    
    func toggleDetailView() {
        if !isDetailViewVisible {
            withAnimation {
                isDetailViewVisible = true
            }
        } else {
            withAnimation {
                isDetailViewVisible = false
            }
        }
    }
    
    func addMarkerAtUserLocation() {
        if let location = locationManager.location {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = location.coordinate.latitude
            annotation.coordinate.longitude = location.coordinate.longitude
            mapView.addAnnotation(annotation)
        }
    }
    
    func setCameraForUserTracking() {
        // Generell gibt es hier ein Problem. Die Richtung, in der man das Gerät bewegt entspricht nicht der Richtung in der sich die Karte dreht. Auch die Ausrichtung der Kamera ist entgegen der eigentlichen Blickrichtung des Users. Es scheint einmal komplett gespiegelt zu sein.
        if let location = locationManager.location {
            let centerCoordinate = mapView.offsetPosition(coordinates: location.coordinate, radius: 10, heading: locationManager.trueHeading)
            let eyeCoordinate = mapView.offsetPosition(coordinates: location.coordinate, radius: 5, heading: locationManager.trueHeading + 180)
            mapView.setCamera(
                MKMapCamera(lookingAtCenter: centerCoordinate, fromEyeCoordinate: eyeCoordinate, eyeAltitude: 0),
                animated: false
            )
        }
    }
    
    func observeDetailViewState() {
        if isTrackingUserWithCamera {
            setCameraForUserTracking()
        } else {
            if isDetailViewVisible {
                mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: UIEdgeInsets(top: 0, left: -200, bottom: 0, right: 200), animated: true)
            } else {
                mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: UIEdgeInsets(top: 0, left: 200, bottom: 0, right: -200), animated: true)
            }
        }
    }
}

struct DetailView: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.blue)
                .frame(maxWidth: 200, maxHeight: 400)
                .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}
