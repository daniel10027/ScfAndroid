import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider/AllWidgets/Divider.dart';
import 'package:rider/AllWidgets/progressDialog.dart';
import 'package:rider/Assistants/requestAssistant.dart';
import 'package:rider/DataHandler/appData.dart';
import 'package:rider/Models/address.dart';
import 'package:rider/Models/placePredications.dart';
import 'package:rider/configMaps.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({Key key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();

  List<PlacePredications> placePredicationList = [];

  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
    pickUpTextEditingController.text = placeAddress;
    return Scaffold(
      appBar: AppBar(
        title: Text("Définir une destination"),
      ),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Container(
            height: 215.0,
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black,
                  blurRadius: 6.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7))
            ]),
            child: Padding(
              padding: EdgeInsets.only(
                  left: 25.0, top: 27.0, right: 25.0, bottom: 20.0),
              child: Column(
                children: [
                  SizedBox(height: 5.0),
                
                  Row(
                    children: [
                      Image.asset("assets/images/pickicon.png",
                          height: 16.0, width: 16.0),
                      SizedBox(height: 18.0),
                      Expanded(
                          child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            controller: pickUpTextEditingController,
                            decoration: InputDecoration(
                                hintText: "Obtenir ma position",
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11.0, top: 8.0, bottom: 8.0)),
                          ),
                        ),
                      ))
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Row(
                    children: [
                      Image.asset("assets/images/desticon.png",
                          height: 16.0, width: 16.0),
                      SizedBox(height: 18.0),
                      Expanded(
                          child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            onChanged: (val) {
                              findPlace(val);
                            },
                            controller: dropOffTextEditingController,
                            decoration: InputDecoration(
                                hintText: "Ou aller ?",
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11.0, top: 8.0, bottom: 8.0)),
                          ),
                        ),
                      ))
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          (placePredicationList.length > 0)
              ? Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListView.separated(
                    padding: EdgeInsets.all(0.0),
                    itemBuilder: (context, index) {
                      return PredictionTitle(
                        placePredications: placePredicationList[index],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        DividerWidget(),
                    itemCount: placePredicationList.length,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapkey&sessiontoken=1234567890&components=country:ci";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == "failed") {
        return;
      }
      if (res["status"] == "OK") {
        var predications = res['predictions'];
        var placesList = (predications as List)
            .map((e) => PlacePredications.fromJson(e))
            .toList();
        setState(() {
          placePredicationList = placesList;
        });
      }
    }
  }
}

class PredictionTitle extends StatelessWidget {
  final PlacePredications placePredications;

  PredictionTitle({Key key, this.placePredications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      padding: EdgeInsets.all(0.0),
      onPressed: () {
        getPlaceAddressDetails(placePredications.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(width: 10.0),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(
                  width: 14.0,
                ),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 8.0,
                        ),
                        Text(
                          placePredications.main_text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(
                          height: 2.0,
                        ),
                        Text(
                          placePredications.secondary_text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                      ]),
                )
              ],
            ),
            SizedBox(width: 10.0),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgessDialog(message: "Obtention des détail en cours..."));

    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapkey";

    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    Navigator.pop(context);

    if (res == "failed") {
      return;
    }

    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];
      print(
          "************************************************************************************************************************************************************************************");
      print(address.latitude);
      print(address.longitude);

      Provider.of<AppData>(context, listen: false)
          .UpdateDroppOffLocationAddress(address);
      print(
          "Votre destination est :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::");
      print(address.placeName);

      Navigator.pop(context, "Obtentiondeladirection");
    }
  }
}
