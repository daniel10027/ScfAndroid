import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rider/AllScreens/loginScreen.dart';
import 'package:rider/AllScreens/mainscreen.dart';
import 'package:rider/AllWidgets/progressDialog.dart';
import 'package:rider/main.dart';

class RegistrationScreen extends StatelessWidget {
  static const String idScreen = "register";

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(children: [
              SizedBox(
                height: 25.0,
              ),
              Image(
                image: AssetImage("assets/images/logo.png"),
                width: 390.0,
                height: 250.0,
                alignment: Alignment.center,
              ),
              SizedBox(
                height: 15.0,
              ),
              Text(
                "Inscription",
                style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bold"),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(children: [
                  SizedBox(
                    height: 15.0,
                  ),
                  TextField(
                    controller: nameTextEditingController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        labelText: "Nom",
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0)),
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  TextField(
                    controller: emailTextEditingController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0)),
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  TextField(
                    controller: phoneTextEditingController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: "Téléphone",
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0)),
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  TextField(
                    controller: passwordTextEditingController,
                    obscureText: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: "Password ",
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0)),
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  RaisedButton(
                    color: Colors.blue[400],
                    textColor: Colors.white,
                    child: Container(
                      height: 50.0,
                      child: Center(
                        child: Text(
                          "Inscription",
                          style: TextStyle(
                              fontSize: 18.0, fontFamily: "Brand Bold"),
                        ),
                      ),
                    ),
                    shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(24.0),
                    ),
                    onPressed: () {
                      if (nameTextEditingController.text.length < 4) {
                        displayToastMessage(
                            "Le nom doit contenir plus de 4 caractères",Colors.red, Colors.white,
                            context);
                      } else if (!emailTextEditingController.text
                          .contains("@")) {
                        displayToastMessage(
                            "L'adresse E-mail n'est pas valide", Colors.red, Colors.white, context);
                      } else if (phoneTextEditingController.text.isEmpty) {
                        displayToastMessage(
                            "Le numéro de téléphone est obligatoire",Colors.red, Colors.white, context);
                       } else if (phoneTextEditingController.text.length < 10) {
                        displayToastMessage(
                            "le numéro de téléphone doit comporter dix chiffres",Colors.red, Colors.white, context);
                      } else if (passwordTextEditingController.text.length <
                          6) {
                        displayToastMessage(
                            "Le mot de passe est trop court",Colors.red, Colors.white, context);
                      } else {
                        registerNewUser(context);
                      }
                    },
                  ),
                ]),
              ),
              FlatButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, LoginScreen.idScreen, (route) => false);
                  },
                  child: Text("Déja inscris ? Connexion "))
            ]),
          ),
        ));
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  registerNewUser(BuildContext context) async {


    showDialog(

      context: context,
      barrierDismissible: false,
      builder: (BuildContext context){ 
        return ProgessDialog(message: "Enregistrement des informations");

      }
    );

    
    final User firebaseUser = (await _firebaseAuth
            .createUserWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
               Navigator.pop(context);
      displayToastMessage("Erreur : " + errMsg.toString(),Colors.red, Colors.white, context);
    }))
        .user;

    if (firebaseUser != null) {
      //si l'utilisateur est crée

      Map userDataMap = {
        "nom": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "telephone": phoneTextEditingController.text.trim(),
      };
      usersRef.child(firebaseUser.uid).set(userDataMap);
      displayToastMessage("Félicitation votre compte a été crée",Colors.red, Colors.white, context);
      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.idScreen, (route) => false);
    } else {
      //en cas d'erreur
       Navigator.pop(context);
      displayToastMessage("Le compte n'a pas pu être crée", Colors.red, Colors.white, context);
    }
  }

  
}

displayToastMessage(String message, Color bg, Color col, BuildContext context) {
    Fluttertoast.showToast(msg: message, gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: bg,
        textColor: col,
        fontSize: 16.0);
  }