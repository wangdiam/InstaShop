import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/utils/location_utils.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:io';
import 'package:geocoder/geocoder.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class Uploader extends StatefulWidget {
  _Uploader createState() => _Uploader();
}

class _Uploader extends State<Uploader> {
  File file;
  //Strings required to save address
  Address address;

  Map<String, double> currentLocation = Map();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  MoneyMaskedTextController moneyMaskedTextController = MoneyMaskedTextController(decimalSeparator: '.', thousandSeparator: ',');

  bool uploading = false;

  @override
  initState() {
    //variables with location assigned as 0.0
    currentLocation['latitude'] = 0.0;
    currentLocation['longitude'] = 0.0;
    initPlatformState(); //method to call location
    super.initState();
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  //method to get Location and save into variables
  initPlatformState() async {
    Address first = await getUserLocation();
    //File defaultImageFile = await getImageFileFromAssets("images/ic_launcher.png");
    setState(() {
      //file = defaultImageFile;
      address = first;
    });
  }
  
  buildAddListingPhotos(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create New Listing",
        style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 300,
                child: RaisedButton(onPressed: () async {
                  File imageFile =
                  await ImagePicker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1200, imageQuality: 100);
                  setState(() {
                    file = imageFile;
                  });
                },
                  elevation: 5.0,
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(5.0)),
                  color: Colors.black,
                  child: new Text("Take a Photo",
                      style: new TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w300)),),
              ),
              SizedBox(
                width: 300,
                child: RaisedButton(
                  onPressed: () async {
                  File imageFile =
                  await ImagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1200, imageQuality: 100);
                  setState(() {
                    file = imageFile;
                  });
                },
                  elevation: 5.0,
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(5.0)),
                  color: Colors.black,
                  child: new Text("Choose From Gallery",
                      style: new TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w300)),),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return file == null
        ? buildAddListingPhotos(context)
        : Scaffold(
            resizeToAvoidBottomPadding: false,
            appBar: AppBar(
              backgroundColor: Colors.white70,
              leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: clearImage),
              title: const Text(
                'Selling',
                style: const TextStyle(color: Colors.black),
              ),
              actions: <Widget>[
              ],
            ),
            body: Column(
              children: [
                Flexible(
                  child: ListView(
                    children: <Widget>[
                      PostForm(
                        imageFile: file,
                        moneyMaskedTextController: moneyMaskedTextController,
                        descriptionController: descriptionController,
                        locationController: locationController,
                        loading: uploading,
                      ),
                      Divider(), //scroll view where we will show location to users
                      (address == null)
                          ? Container()
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.only(right: 5.0, left: 5.0),
                              child: Row(
                                children: <Widget>[
                                  buildLocationButton(address.featureName),
                                  buildLocationButton(address.subLocality),
                                  buildLocationButton(address.locality),
                                  buildLocationButton(address.subAdminArea),
                                  buildLocationButton(address.adminArea),
                                  buildLocationButton(address.countryName),
                                ],
                              ),
                            ),
                      (address == null) ? Container() : Divider(),
                    ],
                  ),
                ),
                SizedBox(
                  width: 400,
                  child: RaisedButton(onPressed: postImage,
                    elevation: 5.0,
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(5.0)),
                    color: Colors.black,
                    child: new Text("Post Listing",
                        style: new TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w300)),),
                )

              ],
            ));
  }

  //method to build buttons with location.
  buildLocationButton(String locationName) {
    if (locationName != null ?? locationName.isNotEmpty) {
      return InkWell(
        onTap: () {
          locationController.text = locationName;
        },
        child: Center(
          child: Container(
            //width: 100.0,
            height: 30.0,
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            margin: EdgeInsets.only(right: 3.0, left: 3.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Center(
              child: Text(
                locationName,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }


  void clearImage() {
    setState(() {
      file = null;
    });
  }

  void postImage() {
    setState(() {
      uploading = true;
    });
    uploadImage(file).then((String data) {
      postToFireStore(
          price: moneyMaskedTextController.text,
          mediaUrl: data,
          description: descriptionController.text,
          location: locationController.text);
    }).then((_) {
      setState(() {
        file = null;
        uploading = false;
      });
    });
  }
}

class PostForm extends StatelessWidget {
  final imageFile;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final MoneyMaskedTextController moneyMaskedTextController;
  final bool loading;
  PostForm(
      {this.imageFile,
      this.descriptionController,
      this.loading,
      this.locationController,
      this.moneyMaskedTextController});

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        loading
            ? LinearProgressIndicator()
            : Padding(padding: EdgeInsets.only(top: 0.0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 60.0,
                width: 60.0,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          alignment: FractionalOffset.topCenter,
                          image: FileImage(imageFile),
                        )),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom:8.0),
          child: Text("DESCRIPTION",
            style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w500
            ),),
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: MediaQuery.of(context).size.width-32,
                child: TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintMaxLines: 10,
                      hintText: "Describe your item with information about the brand, condition, size, colour and style", border: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom:8.0),
          child: Text("INFO",
            style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w500
            ),),
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom:8.0),
              child: Text("PRICE",
                style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w200
                ),),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 100,
                child: TextField(
                  controller: moneyMaskedTextController,
                  decoration: InputDecoration(
                      hintText: "Price", border: InputBorder.none,),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom:8.0),
              child: Text("LOCATION",
                style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w200
                ),),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 100,
                child: TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: "Location", border: InputBorder.none,),
                ),
              ),
            ),
//            ListTile(
//              leading: Icon(Icons.pin_drop),
//              title: Container(
//                width: 250.0,
//                child: TextField(
//                  controller: locationController,
//                  decoration: InputDecoration(
//                      hintText: "Location",
//                      border: InputBorder.none),
//                ),
//              ),
//            ),
          ],
        ),
      ],
    );
  }
}

Future<String> uploadImage(var imageFile) async {
  var uuid = Uuid().v1();
  StorageReference ref = FirebaseStorage.instance.ref().child("post_$uuid.jpg");
  StorageUploadTask uploadTask = ref.putFile(imageFile);

  String downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
  return downloadUrl;
}

void postToFireStore(
    {String price, String mediaUrl, String location, String description}) async {
  var reference = Firestore.instance.collection('insta_posts');

  reference.add({
    "username": currentUserModel.username,
    "location": location,
    "likes": {},
    "mediaUrl": mediaUrl,
    "description": description,
    "ownerId": currentUserModel.id,
    "timestamp": DateTime.now(),
    "price": price
  }).then((DocumentReference doc) {
    String docId = doc.documentID;
    reference.document(docId).updateData({"postId": docId});
  });
}
