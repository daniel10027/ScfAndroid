class PlacePredications {
  String secondary_text;
  String main_text;
  String place_id;


  PlacePredications({this.secondary_text, this.main_text, this.place_id});
  PlacePredications.fromJson(Map<String, dynamic> json){
    place_id  = json["place_id"];
    main_text = json['structured_formatting']["main_text"];
    secondary_text  = json['structured_formatting']["secondary_text"];
  }
}