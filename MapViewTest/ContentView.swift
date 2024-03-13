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

// Referenzen:
// Hier habe ich das her mit dem Verschieben der Karte und Einblenden der DetailView: https://stackoverflow.com/questions/43098546/how-to-offset-mkmapview-to-put-coordinates-under-specified-point

// Hab mir dann noch folgende Seiten dazu angeschaut:
// https://stackoverflow.com/questions/15421106/centering-mkmapview-on-spot-n-pixels-below-pin
// https://stackoverflow.com/questions/37288138/how-can-i-center-my-mapview-so-that-the-selected-pin-is-not-in-the-middle-of-the
// https://stackoverflow.com/questions/67709028/how-to-offset-map-center
// https://stackoverflow.com/questions/51246045/mkmapview-offset-map-to-make-the-annotation-visible
// https://stackoverflow.com/questions/24509112/set-current-location-icon-lower-side-in-mkmapview

// Die MKMApViewExtension habe ich auch nach langem Suchen gefunden. Diese scheint aber nicht ganz korrekt zu funktionieren. Beschreibung dazu in der Funktion setCameraForUserTracking() weiter unten.
// Ich möchte mit dieser UI zB auch später eine Navigation zu den angelegten Markern haben. Wenn es dann funktioniert, und ich denke es wird über das Setzen einer Kamera gesteuert, kann man das ja dann auf den Navigationsteil übertragen.
// Wenn du so willst, soll es nachher ungefähr so aussehen wie Apple Karten im CarPlay oder auf dem iPhone im Querformat. Da ist die Position auch nach rechts oder links verschoben und die Details werden an der Seite eingeblendet.

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
