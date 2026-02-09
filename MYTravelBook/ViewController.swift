//
//  ViewController.swift
//  MYTravelBook
//
//  Created by Emirhan Çitgez on 18/03/2025.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate{
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var chooseLatitude = Double()
    var chooseLongitude = Double()
    
    var selectedName = ""
    var selectedId : UUID?
    
    var annotationName = ""
    var annotationComment = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedName != "" {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let name = result.value(forKey: "name") as? String {
                            annotationName = name
                            
                            if let comment = result.value(forKey: "comment") as? String {
                                annotationComment = comment
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationName
                                        annotation.subtitle = annotationComment
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        
                                        nameText.text = annotationName
                                        commentText.text = annotationComment
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch {
                print("Error")
            }
        }
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            
            let touchedPoint = gestureRecognizer.location(in: mapView)
            let touchedCoordinate = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chooseLatitude = touchedCoordinate.latitude
            chooseLongitude = touchedCoordinate.longitude
            
            let annonation = MKPointAnnotation()
            annonation.coordinate = touchedCoordinate
            annonation.title = nameText.text
            annonation.subtitle = commentText.text
            self.mapView.addAnnotation(annonation)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            
        if annotation is MKUserLocation {
            return nil
        }
            
        let reuseId = "MyAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "reuseID") as? MKMarkerAnnotationView
            
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.lightGray
                
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else {
            pinView?.annotation = annotation
        }
            
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                //closure
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: (placemark[0]))
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationName
                        let launchOption = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOption)
                    }
                }
                
            }
            
        }
    }
    
    

    @IBAction func saveButton(_ sender: UIButton) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "name")
        newPlace.setValue(commentText.text, forKey: "comment")
        newPlace.setValue(chooseLatitude, forKey: "latitude")
        newPlace.setValue(chooseLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
        do{
           try context.save()
            print("Success")
        }
        catch{
            print("Error")
        }
    }
    
}

