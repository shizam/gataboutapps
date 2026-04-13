import CoreLocation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var locationError: Error?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }
    func requestLocation() { locationError = nil; manager.requestLocation() }

    var hasPermission: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: true
        default: false
        }
    }

    var needsPermissionRequest: Bool { authorizationStatus == .notDetermined }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last?.coordinate
        Task { @MainActor in self.currentLocation = location }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if self.hasPermission && self.currentLocation == nil { self.requestLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.locationError = error }
    }
}
