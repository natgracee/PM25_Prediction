//
//  PM25SpreadOverlay.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 17/08/26.
//


import SwiftUI
import MapKit

struct PM25SpreadOverlay: MapContent {

    let coordinate: CLLocationCoordinate2D
    let directionDegrees: Double
    let lengthMeters: Double
    let visibility: Double

    @MapContentBuilder
    var body: some MapContent {

        MapPolygon(
            coordinates: plumeCoordinates(
                widthMeters: lengthMeters * 0.45,
                lengthMeters: lengthMeters
            )
        )
        .foregroundStyle(
            .orange.opacity(0.10 * visibility)
        )

        MapPolygon(
            coordinates: plumeCoordinates(
                widthMeters: lengthMeters * 0.28,
                lengthMeters: lengthMeters * 0.75
            )
        )
        .foregroundStyle(
            .orange.opacity(0.12 * visibility)
        )

        MapPolygon(
            coordinates: plumeCoordinates(
                widthMeters: lengthMeters * 0.12,
                lengthMeters: lengthMeters * 0.45
            )
        )
        .foregroundStyle(
            .orange.opacity(0.16 * visibility)
        )
    }

    private func plumeCoordinates(
        widthMeters: Double,
        lengthMeters: Double
    ) -> [CLLocationCoordinate2D] {

        let center = MKMapPoint(coordinate)

        let metersPerMapPoint =
            1.0 / MKMapPointsPerMeterAtLatitude(
                coordinate.latitude
            )

        let length = lengthMeters * metersPerMapPoint
        let width = widthMeters * metersPerMapPoint

        let angle = directionDegrees * .pi / 180

        let directionX = sin(angle)
        let directionY = cos(angle)

        let perpendicularX = cos(angle)
        let perpendicularY = -sin(angle)

        let tip = MKMapPoint(
            x: center.x + directionX * length,
            y: center.y - directionY * length
        )

        let left = MKMapPoint(
            x: center.x + perpendicularX * width,
            y: center.y + perpendicularY * width
        )

        let right = MKMapPoint(
            x: center.x - perpendicularX * width,
            y: center.y - perpendicularY * width
        )

        let leftMid = MKMapPoint(
            x: center.x
                + directionX * length * 0.45
                + perpendicularX * width * 0.65,
            y: center.y
                - directionY * length * 0.45
                + perpendicularY * width * 0.65
        )

        let rightMid = MKMapPoint(
            x: center.x
                + directionX * length * 0.45
                - perpendicularX * width * 0.65,
            y: center.y
                - directionY * length * 0.45
                - perpendicularY * width * 0.65
        )

        return [
            left,
            leftMid,
            tip,
            rightMid,
            right
        ]
        .map(\.coordinate)
    }
}
