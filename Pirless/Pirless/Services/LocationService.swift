//
//  LocationService.swift
//  Pirless
//
//  Created by Graceila Natasya on 19/08/26.
//


//
//  LocationService.swift
//  Pirless
//
//  Created by Graceila Natasya on 18/08/26.
//


//
//  LocationService.swift
//  Pirless
//
//  Mengelola lokasi perangkat.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService:
    NSObject,
    ObservableObject,
    CLLocationManagerDelegate {

    private let locationManager =
        CLLocationManager()


    @Published var latitude: Double?

    @Published var longitude: Double?


    @Published var authorizationStatus:
        CLAuthorizationStatus = .notDetermined


    override init() {

        super.init()

        locationManager.delegate =
            self

        authorizationStatus =
            locationManager.authorizationStatus
    }


    func requestLocationPermission() {

        locationManager.requestWhenInUseAuthorization()
    }


    func requestCurrentLocation() {

        locationManager.requestLocation()
    }


    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        authorizationStatus =
            manager.authorizationStatus


        if manager.authorizationStatus ==
            .authorizedWhenInUse ||
            manager.authorizationStatus ==
            .authorizedAlways {

            manager.requestLocation()
        }
    }


    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations:
            [CLLocation]
    ) {

        guard let location =
                locations.last
        else {
            return
        }


        latitude =
            location.coordinate.latitude

        longitude =
            location.coordinate.longitude
    }


    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        print(
            "❌ Location error: \(error)"
        )
    }
}
