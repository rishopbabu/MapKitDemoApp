//
//  ViewController.swift
//  MapKit Demo App
//
//  Created by Mac-OBS-51 on 04/08/23.
//

import CoreLocation
import MapKit
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    private weak var mapView: MKMapView!
    var route: MKRoute?
    
    let locationManager = CLLocationManager()
    
    let sourceCoordinate = CLLocationCoordinate2D(latitude: 11.267630573827411, longitude: 76.97844623089712)
    let destinationCoordinate = CLLocationCoordinate2D(latitude: 12.507045, longitude: 78.223367)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        mapView.delegate = self
        
        showRouteOnMap(sourceCoordinate: sourceCoordinate, destination: destinationCoordinate)
        let sourceLocation = convertToCLLocation(coordinate: sourceCoordinate)
        let destinationLocation = convertToCLLocation(coordinate: destinationCoordinate)
        render(sourceLocation)
        render(destinationLocation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Consumes more battery
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupViews() {
        
        let mapViewItem = MKMapView()
        mapViewItem.translatesAutoresizingMaskIntoConstraints = false
        mapViewItem.backgroundColor = .red
        self.mapView = mapViewItem
        view.addSubview(mapViewItem)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
        
    }
    
    func convertToCLLocation(coordinate: CLLocationCoordinate2D) -> CLLocation {
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    func render(_ location: CLLocation) {
        
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate,
                                        span: span)
        mapView.setRegion(region, animated: true)
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
    }
    
    func showRouteOnMap(sourceCoordinate: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        let sourcePlaceMark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        let destinationMapItem = MKMapItem(placemark: destinationPlaceMark)
        
        let directtionRequest = MKDirections.Request()
        directtionRequest.source = sourceMapItem
        directtionRequest.destination = destinationMapItem
        directtionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directtionRequest)
        directions.calculate { (response, error) in
            guard let route = response?.routes.first else {
                return
            }
            
            self.route = route
            
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            
            if let firstStep = route.steps.first {
                self.navigationItem.title = firstStep.instructions
            }
            
            self.startUpdatingUserLocation()
        }
    }
    
    func startUpdatingUserLocation() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.delegate = self
    }

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let route = self.route else {
            return
        }
        
        let dis = convertToCLLocation(coordinate: route.polyline.coordinate)
        
        // Calculate the remaining distance to the destination
        let remainingDistance = route.distance - userLocation.location!.distance(from: dis)
        
        // Update the navigation instructions based on the user's location
        if let currentStep = route.steps.first(where: { $0.distance <= remainingDistance }) {
            self.navigationItem.title = currentStep.instructions
        }
    }
    
}
