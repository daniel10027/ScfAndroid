import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/utils/typedefs.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rider/AllScreens/registrationScreen.dart';
import 'package:rider/AllWidgets/progressDialog.dart';
import 'mainscreen.dart';
import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';

class LoginScreen extends StatefulWidget {
  static const String idScreen = "login";

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  final _codeController = TextEditingController();

  bool show = false;

  Future<bool> loginUser(String phone, BuildContext context) async {
    try {
      FirebaseAuth _auth = FirebaseAuth.instance;

      _auth.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: Duration(seconds: 60),
          verificationCompleted: (AuthCredential credential) async {
            Navigator.of(context).pop();

            UserCredential result =
                await _auth.signInWithCredential(credential);

            User user = result.user;

            if (user != null) {
              Navigator.pushNamedAndRemoveUntil(
                  context, MainScreen.idScreen, (route) => false);
            } else {
              displayToastMessage(
                  "Une erreur est sruvenue", Colors.red, Colors.white, context);
            }

            //This callback would gets called when verification is done auto maticlly
          },
          verificationFailed: (FirebaseAuthException exception) {
            setState(() {
              show = false;
            });
            displayToastMessage(
                exception.message, Colors.red, Colors.white, context);
          },
          codeSent: (String verificationId, [int forceResendingToken]) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Code de confitmation"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      FlatButton(
                        child: Text("Confirmer"),
                        textColor: Colors.white,
                        color: Colors.blue,
                        onPressed: () async {
                          final code = _codeController.text.trim();
                          AuthCredential credential =
                              PhoneAuthProvider.credential(
                                  verificationId: verificationId,
                                  smsCode: code);

                          try {
                            UserCredential result =  await _auth.signInWithCredential(credential);
                            
                            User user = result.user;
                            
                            if (user != null) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, MainScreen.idScreen, (route) => false);
                            } else {
                              displayToastMessage("Une erreur est sruvenue",
                                  Colors.red, Colors.white, context);
                            }
                          }  catch (e) {
                                displayToastMessage("Veuillez entrer un code valide",
                                  Colors.red, Colors.white, context); 
                                  setState(() {});
                 // TODO
                          }


                        },
                      )
                    ],
                  );
                });
          },
          codeAutoRetrievalTimeout: (String verificationId) {});
    }on PlatformException catch (e) {
    print("Exception caught => ${e.code}");
    setState(() {});

    }
    if (show == true) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return ProgessDialog(message: "Veuillez patienter ...");
          });
    }
    setState(() {});

  }

  Country _selectedFilterdDialogCountry =
      CountryPickerUtils.getCountryByPhoneCode("225");
  String _countryCode = "+225";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 40),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(""),
                Text(
                  "Saisissez votre numéro de téléphone",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500),
                ),
                Icon(Icons.more_vert),
              ],
            ),
            SizedBox(height: 30),
            Text(
              "SCF va envoyer un message SMS pour vérifier votre numéro de téléphone.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            ListTile(
              onTap: _openFilterdCountryPickerDialog,
              title: _buildDialogItem(_selectedFilterdDialogCountry),
            ),
            Row(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(width: 1.50, color: Colors.blue)),
                  ),
                  child: Text("+${_selectedFilterdDialogCountry.phoneCode}"),
                  width: 80.0,
                  alignment: Alignment.center,
                  height: 42.0,
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Container(
                    height: 40,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      controller: _phoneController,
                      decoration: InputDecoration(
                          hintText: "N° de téléphone", counterText: ""),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              "Des frais d'opération pour les SMS peuvent s'appliquer",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 65.0,
                      ),
                      // Image(
                      //   image: AssetImage("assets/images/logo.png"),
                      //   width: 390.0,
                      //   height: 250.0,
                      //   alignment: Alignment.center,
                      // ),
                      SizedBox(
                        height: 15.0,
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 15.0,
                            ),
                            Form(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    height: 16,
                                  ),
                                  SizedBox(
                                    height: 50,
                                  ),
                                  Container(
                                    child: Align(
                                      child: MaterialButton(
                                        child: Text(
                                          "Vérifier",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        textColor: Colors.white,
                                        onPressed: () {
                                          final phone =
                                              "+${_selectedFilterdDialogCountry.phoneCode}" +
                                                  _phoneController.text.trim();
                                          // print(phone);

                                          check().then((intenet) {
                                            if (intenet != null && intenet) {
                                              setState(() {
                                                show = true;
                                              });
                                              if (_phoneController
                                                  .text.isEmpty) {
                                                displayToastMessage(
                                                    "Veuillez entrer un numéro de téléphone valide",
                                                    Colors.red,
                                                    Colors.white,
                                                    context);
                                              } else if (_phoneController.text
                                                      .trim()
                                                      .length <
                                                  8) {
                                                displayToastMessage(
                                                    "Le numéro de téléphone doit contenir au moins 8 chiffres",
                                                    Colors.red,
                                                    Colors.white,
                                                    context);
                                              } else if (_phoneController.text
                                                  .trim()
                                                  .contains(".")) {
                                                displayToastMessage(
                                                    "Veuillez entrer un numéro de téléphone valide",
                                                    Colors.red,
                                                    Colors.white,
                                                    context);
                                              } else if (_phoneController.text
                                                  .trim()
                                                  .contains("-")) {
                                                displayToastMessage(
                                                    "Veuillez entrer un numéro de téléphone valide",
                                                    Colors.red,
                                                    Colors.white,
                                                    context);
                                              } else {
                                                print(phone);
                                                try {
                                                  loginUser(phone, context);
                                                } on FirebaseAuthException catch (e) {
                                                       displayToastMessage(e.message, Colors.red, Colors.white, context);                                             // TODO
                                                }
                                              }
                                            } else {
                                              _chechInternet();
                                            }
                                          });
                                        },
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _openFilterdCountryPickerDialog() {
    showDialog(
      context: context,
      builder: (_) => Theme(
        data: Theme.of(context).copyWith(primaryColor: Colors.blue),
        child: CountryPickerDialog(
          titlePadding: EdgeInsets.all(8.0),
          searchCursorColor: Colors.black,
          searchInputDecoration: InputDecoration(hintText: "Recherche"),
          isSearchable: true,
          title: Text("Selectionnez votre pays"),
          onValuePicked: (Country country) {
            setState(() {
              _selectedFilterdDialogCountry = country;
              _countryCode = country.phoneCode;
            });
          },
          itemBuilder: _buildDialogItem,
        ),
      ),
    );
  }

  Widget _buildDialogItem(Country country) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.blue,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          CountryPickerUtils.getDefaultFlagImage(country),
          SizedBox(height: 8.0),
          Text(" +${country.phoneCode} "),
          SizedBox(height: 8.0),
          Text("${country.iso3Code}"),
          Spacer(),
          Icon(Icons.arrow_drop_down),
        ],
      ),
    );
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
          title: Text('HORS RESEAUX', textAlign: TextAlign.center, style: TextStyle(color: Colors.white),),
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
              child: Text('Ok',  style: TextStyle(color: Colors.white),),
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
