import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Users{ 
  String id;
  String email;
  String nom;
  String telephone;
  

  Users({this.id, this.email, this.nom, this.telephone,});

  Users.formSnapshot(DataSnapshot dataSnapshot){
      id = dataSnapshot.key;
      email = dataSnapshot.value["email"];
      nom = dataSnapshot.value["nom"];
      telephone = dataSnapshot.value["telephone"];
  }
}