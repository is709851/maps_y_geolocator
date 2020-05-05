import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

const kGoogleApiKey = "API_KEY";

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  Set<Marker> _mapMarkers = Set();
  GoogleMapController mapController;
  Position _currentPosition;
  static LatLng _center = const LatLng(20.608148, -103.417576);

  final homeScaffoldKey = GlobalKey<ScaffoldState>();

  LatLng _lastMapPosition = _center;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Mapa!'),
          backgroundColor: Colors.green[700],
        ),
        body: Stack(children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            markers: _mapMarkers,
            onLongPress: _setMarker,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(zoom: 16.0, target: _center),
            onCameraMove: _onCameraMove,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                children: <Widget>[
                  FloatingActionButton(
                    onPressed: _getCurrentPosition,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.filter_center_focus, size: 36.0),
                  ),
                  SizedBox(height: 16.0),
                  FloatingActionButton(
                    onPressed: _buscadorButton,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.search, size: 36.0),
                  ),
                  SizedBox(height: 16.0),
                  FloatingActionButton(
                    onPressed: () {
                      _setMarker(_lastMapPosition);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add_location, size: 36.0),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: coord.toString(),
            snippet: _markerAddress,
            onTap: () async {
              List<Placemark> placemark = await Geolocator()
                  .placemarkFromCoordinates(coord.latitude, coord.longitude);
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext bc) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white54,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: 16,
                          ),
                          Text('Localidad: ' + placemark[0].locality),
                          SizedBox(height: 16),
                          Text(placemark[0].subLocality +
                              ',' +
                              ' ' +
                              placemark[0].postalCode),
                          SizedBox(
                            height: 16,
                          ),
                          Text('Nombre: ' +
                              placemark[0].name +
                              '      País: ' +
                              placemark[0].country),
                          SizedBox(
                            height: 16,
                          ),
                          Text('Áreas administrativas: ' +
                              placemark[0].administrativeArea),
                          SizedBox(
                            height: 16,
                          ),
                          Text('Sub-áreas administrativas: ' +
                              placemark[0].subAdministrativeArea),
                          SizedBox(
                            height: 16,
                          ),
                        ],
                      ),
                    );
                  });
            },
          ),
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        infoWindow: InfoWindow(
          title: _currentPosition.toString(),
          snippet: _currentAddress,
        ),
      ),
    );

    // move camera
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }

  Future<void> _buscadorButton() async {
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      mode: Mode.overlay,
      language: "es",
      components: [Component(Component.country, "mex")],
    );

    displayPrediction(p, homeScaffoldKey.currentState);
  }

  Future<Null> displayPrediction(Prediction p, ScaffoldState scaffold) async {
    if (p != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      scaffold.showSnackBar(
        SnackBar(content: Text("${p.description} - $lat/$lng")),
      );
    }
  }
}
