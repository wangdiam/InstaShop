import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/utils/styles.dart';
import 'package:instashop/widgets/image_tile_widget.dart';
import 'package:instashop/widgets/post_widget.dart';
import 'package:intl/intl.dart';

class BagWidget extends StatefulWidget {
  String ownerId;
  List<String> posts;
  BagWidget(this.posts, this.ownerId);
  List<String> imgUrls = [];

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _BagWidgetState();
  }
}

class _BagWidgetState extends State<BagWidget> {
  var formatCurrency = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                //AvatarWidget(user: widget.post.ownerId),
                FutureBuilder(
                    future: Firestore.instance
                        .collection('insta_users')
                        .document(widget.ownerId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.data != null) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                openProfile(context, widget.ownerId, true);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                      snapshot.data.data['photoUrl']),
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 0.0),
                                    child: Text(snapshot.data.data['username'],
                                        style: boldStyle),
                                  ),
                                  onTap: () {
                                    openProfile(context, widget.ownerId, true);
                                  },
                                ),
                                Text("${widget.posts.length}" +
                                    ((widget.posts.length == 1)
                                        ? " item"
                                        : " items")),
                              ],
                            ),
                          ],
                        );
                      }

                      // snapshot data is null here
                      return Container();
                    }),
                Spacer(),
                FutureBuilder(
                    future: _getItems(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.data != null &&
                          snapshot.data.documents.length != 0) {
                        double totalPrice = 0;
                        snapshot.data.documents.forEach((element) {
                          if (widget.posts.indexOf(element['postId']) != -1) {
                            String price = element['price'];
                            price = price.replaceAll(",", "");
                            totalPrice += double.tryParse(price);
                          }
                        });
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 0.0, bottom: 0.0),
                                child: Text(
                                  "${formatCurrency.format(totalPrice)}",
                                  style: boldStyle,
                                ),
                              ),
                              Text(
                                "+ shipping",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w300),
                              )
                            ],
                          ),
                        );
                      }
                      return Container();
                    })
              ],
            ),
            SizedBox(
              height: 150,
              child: FutureBuilder(
                future: _getItems(),
                // ignore: missing_return
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  List<Post> posts = [];
                  if (snapshot.data != null) {
                    snapshot.data.documents.forEach((element) {
                      if (widget.posts.indexOf(element['postId']) != -1) {
                        posts.add(Post.fromDocument(element));
                      }
                    });
                    return posts.length != 0
                        ? ListView.builder(
                            itemBuilder: (ctx, i) {
                              return Stack(children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: ImageTile(PostWidget(posts[i])),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        height: 134,
                                        width: 134,
                                        decoration: new BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          gradient: new LinearGradient(
                                            end: const Alignment(0.0, -1),
                                            begin: const Alignment(0.0, 0.4),
                                            colors: <Color>[
                                              const Color(0x3A000000),
                                              Colors.grey.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        "${formatCurrency.format(double.tryParse(posts[i].price.replaceAll(",", "")))}",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0),
                                      ),
                                    ),
                                  ),
                                )
                              ]);
                            },
                            itemCount: widget.posts.length,
                            scrollDirection: Axis.horizontal,
                          )
                        : Container();
                  }
                  return Container();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ButtonTheme(
                minWidth: 400.0,
                height: 50.0,
                child: RaisedButton(
                  elevation: 5.0,
                  child: Text(
                    "Checkout",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.0,
                        fontWeight: FontWeight.w300),
                  ),
                  onPressed: () {},
                ),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }

  Future<QuerySnapshot> _getItems() async {
    return Firestore.instance
        .collection('insta_posts')
        .where("ownerId", isEqualTo: widget.ownerId)
        .getDocuments();
  }
}
