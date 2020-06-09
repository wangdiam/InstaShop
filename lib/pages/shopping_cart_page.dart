import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/widgets/bag_widget.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

// TODO: Implement checkout feature which means integrating a 3rd party payment solution
class ShoppingCart extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ShoppingCartState();
  }
}

class _ShoppingCartState extends State<ShoppingCart> {
  Map savedItems = {};
  int itemCount = 0;

  @override
  void initState() {
    _fetchSavedItems();
    super.initState();
  }

  /*
  *  Fetch saved items by user from Firestore
  * */
  void _fetchSavedItems() async {
    Map<String, List<String>> combined = {};
    int count = 0;
    var ref = Firestore.instance
        .collection("insta_items")
        .document(currentUserModel.id)
        .collection("items");
    QuerySnapshot snap = await ref.getDocuments();
    snap.documents.forEach((value) {
      List<String> items = [];
      value.data.forEach((k, v) {
        if (v) {
          items.add(k);
          count++;
        }
      });
      if (items.length != 0) {
        combined[value.documentID] = items;
      }
    });
    setState(() {
      savedItems = combined;
      itemCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              OMIcons.close,
              color: Colors.black,
            ),
            onPressed: () => {Navigator.pop(context)},
          ),
          title: Text(
            "Bag",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
        body: savedItems.isNotEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 8.0, bottom: 4.0, left: 16.0),
                    child: Text(
                        "$itemCount items from ${savedItems.length} ${savedItems.length == 1 ? "shop" : "shops"}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(),
                  ),
                  Flexible(
                    child: ListView.builder(
                      itemBuilder: (ctx, i) {
                        String key = savedItems.keys.elementAt(i);
                        return BagWidget(savedItems[key], key);
                      },
                      itemCount: savedItems.length,
                      //controller: widget.scrollController,
                    ),
                  ),
                ],
              )
            : Container());
  }
}
