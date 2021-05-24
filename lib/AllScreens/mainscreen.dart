import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider/AllScreens/loginScreen.dart';
import 'package:rider/AllScreens/registrationScreen.dart';
import 'package:rider/AllWidgets/Divider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rider/Assistants/assistantMethods.dart';
import 'package:rider/Assistants/geoFireAssistant.dart';
import 'package:rider/Assistants/requestAssistant.dart';
import 'package:rider/DataHandler/appData.dart';
import 'package:rider/AllWidgets/progressDialog.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:rider/Models/directDetails.dart';
import 'package:rider/Models/nearbyAvailableDrviers.dart';
import 'package:rider/configMaps.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey<ScaffoldState>();

  DirectionDetails tripDirectionDetails;
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;

  var geoLocator = Geolocator();

  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};

  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;

  double searchContainerHeight = 400.0;

  double requestRideContainerHeight = 0;

  bool drawerOpen = true;

  bool show = false;

  bool nearbyAvailableDriverKeysLoaded = false;

  String postLat;
  String postLong;

  DatabaseReference riderRequestRef;

  BitmapDescriptor nearbyIcon;

  static const colorizeColors = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 55.0,
    fontFamily: 'Signatra',
  );

  @override
  void initState() {
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    riderRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Requests").push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waitaing",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.nom,
      "rider_phone": userCurrentInfo.telephone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
    };

    riderRequestRef.push().set(rideInfoMap);
  }

  void cancelRideRequest() {
    riderRequestRef.remove();
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 400.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
    LatLng latLatPosition = LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition =
        new CameraPosition(target: latLatPosition, zoom: 14);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);

    initGeoFireListner();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Dio dio = new Dio();

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldkey,
      appBar: AppBar(
        title: Text("SCF les Dépanneurs"),
      ),
      drawer: Container(
        color: Colors.blue,
        width: 255.00,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset("assets/images/logo.png",
                          height: 65.0, width: 65.0),
                      SizedBox(
                        width: 16.0,
                      ),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Mon numéro",
                              style: TextStyle(
                                  fontSize: 16.0, fontFamily: "Brand-bold"),
                            ),
                            SizedBox(
                              height: 6.0,
                            ),
                            Text(FirebaseAuth.instance.currentUser.phoneNumber),
                          ])
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(
                height: 12.0,
              ),

              //drawer body controller

              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  "A propos",
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ), //fontFamily: "Brand-bold"
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(
                    "Déconnexion",
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ), //fontFamily: "Brand-bold"
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              setState(() {
                bottomPaddingOfMap = 300;
              });
              locatePosition();
            },
          ),
          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldkey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,
                  ),
                  radius: 20,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue,
                          blurRadius: 16.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.location_history, color: Colors.blue),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<AppData>(context)
                                              .pickUpLocation !=
                                          null
                                      ? Provider.of<AppData>(context)
                                          .pickUpLocation
                                          .placeName
                                      : "Ma position",
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  "Votre position actuelle ",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12.0),
                                ),
                              ],
                            ),
                          ),
                        ]),
                        SizedBox(height: 10.0),
                        DividerWidget(),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          color: Colors.blue[400],
                          textColor: Colors.white,
                          child: Container(
                            height: 60.0,
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_road,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  Center(
                                    child: Text(
                                      "   Sortie de route",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(12.0),
                          ),
                          onPressed: () async {
                            check().then((intenet) {
                              if (intenet != null && intenet) {
                                postDataToApi("Sortie de route 22");
                              } else {
                                _chechInternet();
                              }
                            });
                          },
                        ),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          color: Colors.blue[200],
                          textColor: Colors.white,
                          child: Container(
                            height: 60.0,
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history_edu,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  Center(
                                    child: Text(
                                      "   Panne",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(12.0),
                          ),
                          onPressed: () async {
                            check().then((intenet) {
                              if (intenet != null && intenet) {
                                postDataToApi("Panne véhicule");
                              } else {
                                _chechInternet();
                              }
                            });
                          },
                        ),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          color: Colors.red[200],
                          textColor: Colors.white,
                          child: Container(
                            height: 60.0,
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.car_rental,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  Center(
                                    child: Text(
                                      "   Accident",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(12.0),
                          ),
                          onPressed: () async {
                            check().then((intenet) {
                              if (intenet != null && intenet) {
                                postDataToApi("Accident niveau 1");
                              } else {
                                _chechInternet();
                              }
                            });
                          },
                        ),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          color: Colors.red[900],
                          textColor: Colors.white,
                          child: Container(
                            height: 60.0,
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.handyman,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  Center(
                                    child: Text(
                                      "   Accident grave",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(12.0),
                          ),
                          onPressed: () async {
                            check().then((intenet) {
                              if (intenet != null && intenet) {
                                postDataToApi("Accident grave avec dégats");
                              } else {
                                _chechInternet();
                              }
                            });
                          },
                        ),
                      ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgessDialog(
              message: "Veuillez patienter ...",
            ));

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodePoints);
    pLineCoordinates.clear();
    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
        title: initialPos.placeName,
        snippet: "Ma position",
      ),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: finalPos.placeName,
        snippet: "Destination",
      ),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffUpId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
        fillColor: Colors.blueAccent,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent,
        circleId: CircleId("pickUpId"));

    Circle dropOffLocCircle = Circle(
        fillColor: Colors.deepPurple,
        center: dropOffLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple,
        circleId: CircleId("dropOffUpId"));

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGeoFireListner() {
    Geofire.initialize("availableDrivers");
    //comment
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 15)
        .listen((map) {
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();

            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.nearbyAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }

            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();

            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();

            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();

            // Update your key's location
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            // All Intial Data is loaded

            break;
        }
      }

      setState(() {});
      //comment
    });
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMarkers = Set<Marker>();

    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: nearbyIcon,
        rotation: AssistantMethods.createRandomNumber(360),
      );

      tMarkers.add(marker);
    }

    setState(() {
      markersSet = tMarkers;
    });
  }

  void createIconMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, "assets/images/car_ios.png")
          .then((value) {
        nearbyIcon = value;
      });
    }
  }

  Future<void> postDataToApi(String type) async {
    show = true;
    show? showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgessDialog(message: "Veuillez patienter ...");
        }):"";

    var url = 'http://depanneurs.herokuapp.com/mobile/mobilepost/';

    String placeAddress = "";
    String placeIds = "";
    String uri =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${currentPosition.latitude},${currentPosition.longitude}&key=$mapkey";
    var response = await RequestAssistant.getRequest(uri);
    if (response != "failed") {
      placeAddress = response['results'][1]["formatted_address"];
      placeIds = response['results'][0]["place_id"];
      print(
          "*****************************************************************place id");
      print(placeIds);
    }

    double latitude = currentPosition.latitude;
    double longitude = currentPosition.longitude;

    Map data = {
      'latitude': currentPosition.latitude,
      'longitude': currentPosition.longitude,
      'description': type,
      'contact': FirebaseAuth.instance.currentUser.phoneNumber.toString(),
      'place': placeAddress,
      'placeId': placeIds,
      'response': response,
    };

    var body = json.encode(data);

    try {
      var response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);

      if (response.statusCode == 200) {
        displayToastMessage(
            "Demande envoyée , nous vous contacterons au plus vite",
            Colors.green[200],
            Colors.white,
            context);
      } else {
        displayToastMessage(
            "Une erreur est survenue", Colors.red, Colors.white, context);
      }
    } on FirebaseAuthException catch (e) {
      //  _serverError();

    }
    setState(() {
      show=false;
    });
     Navigator.pushNamedAndRemoveUntil(
                                  context, MainScreen.idScreen, (route) => false);
  }

  Future<bool> check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  Future<void> _chechInternet() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      //this means the user must tap a button to exit the Alert Dialog
      builder: (BuildContext context) {
        return AlertDialog(                                                                                                                                                                                                                                                                                                                                                                                                                               
          backgroundColor: Colors.red,
          title: Text(
            'HORS RESEAUX',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Icon(Icons.network_check, size: 100, color: Colors.white),
                Text(
                  "Verifiez votre connexion internet !",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              color: Colors.blue,
              child: Text(
                'Ok',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _serverError() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      //this means the user must tap a button to exit the Alert Dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: Text(
            'ERREUR INTERNE',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Icon(Icons.offline_bolt, size: 100, color: Colors.white),
                Text(
                  "Une erreur interne est survenue , veuillez reessayer plus tard.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              color: Colors.blue,
              child: Text(
                'Ok',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
