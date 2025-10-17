import SwiftUI
import MapKit
import CoreLocation

struct LocationMapView: View {
    let location: Location
    @Environment(\.dismiss) private var dismiss
    
    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    var body: some View {
        NavigationView {
            Group {
                if #available(iOS 17.0, *) {
                    Map(position: .constant(.region(region)))
                } else {
                    Map(coordinateRegion: .constant(region))
                }
            }
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LocationMapView(location: Location(
        name: "Gym",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    ))
} 
