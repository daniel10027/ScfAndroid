import 'package:flutter/material.dart';
import 'package:rider/Models/address.dart';

class AppData extends ChangeNotifier{ 

  Address pickUpLocation, dropOffLocation;

  // ignore: non_constant_identifier_names
  void UpdatePickUpLocationAddress(Address pickUpAddress){
    pickUpLocation = pickUpAddress; 
    notifyListeners();
  }

   // ignore: non_constant_identifier_names
   void UpdateDroppOffLocationAddress(Address dropOffAddress){
    dropOffLocation = dropOffAddress; 
    notifyListeners();
  }

}