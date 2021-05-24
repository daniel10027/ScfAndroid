import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider/Assistants/requestAssistant.dart';
import 'package:rider/DataHandler/appData.dart';
import 'package:rider/Models/address.dart';
import 'package:rider/Models/allUsers.dart';
import 'package:rider/Models/directDetails.dart';
import 'package:rider/configMaps.dart';

class AssistantMethods {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = "";
   // String st0, st1, st2, st3, st4, st5, st6;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapkey";
    var response = await RequestAssistant.getRequest(url);
    if (response != "failed") {
     
     placeAddress = response['results'][1]["formatted_address"];

      // st0 = response['results'][0]["address_components"][0]['long_name'];
      // st1 = response['results'][0]["address_components"][1]['long_name'];
      // st2 = response['results'][0]["address_components"][2]['long_name'];
      // st3 = response['results'][0]["address_components"][3]['long_name'];
      // st4 = response['results'][0]["address_components"][4]['long_name'];
      // //   st5 = response['results'][0]["address_components"][5]['long_name'];

      // placeAddress = st0 + ", " + st1 + ", " + st2 + ", " + st3 + ", " + st4;

      Address userPickUpAddress = new Address();

      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .UpdatePickUpLocationAddress(userPickUpAddress);
    }
    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectionDetails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUlr =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapkey";

    var res = await RequestAssistant.getRequest(directionUlr);

    if (res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.encodePoints =
        res['routes'][0]['overview_polyline']['points'];
    directionDetails.distanceText =
        res['routes'][0]['legs'][0]['distance']['text'];
    directionDetails.distanceValue =
        res['routes'][0]['legs'][0]['distance']['value'];
    directionDetails.durationText =
        res['routes'][0]['legs'][0]['duration']['text'];
    directionDetails.durationValiue =
        res['routes'][0]['legs'][0]['duration']['value'];

    return directionDetails;
  }

  static int calculateFares(DirectionDetails directionDetails) {
    // en dollar usd
    double timeTraveldFare = (directionDetails.durationValiue / 60) * 0.20;
    double distanceTraveldFare =
        (directionDetails.durationValiue / 1000) * 0.20;
    double totalFareAmount = timeTraveldFare + distanceTraveldFare;
    //valur local
    //1$ = 500 Frs
    double totalLocalAmount = totalFareAmount * 500;
    return totalLocalAmount.truncate();
  }

  static void getCurrentOnlineUserInfo() async {
    firebaseUser = await FirebaseAuth.instance.currentUser;

    String userId = firebaseUser.uid;
    String phone = firebaseUser.phoneNumber;
    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child("users").child(userId);

    reference.once().then((DataSnapshot dataSnapShot) {
      if (dataSnapShot.value != null) {
        userCurrentInfo = Users.formSnapshot(dataSnapShot);
      }
    });
  }

  static double  createRandomNumber(int num){ 
    var random = Random();
    int radNumber =random.nextInt(num);
    return radNumber.toDouble();

  }
}
