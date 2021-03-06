import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/pages/shopping_cart_page.dart';
import 'package:instashop/widgets/post_widget.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Post> posts = List();

class HomeFeedPage extends StatefulWidget {
  final ScrollController scrollController;
  final String userID;

  HomeFeedPage({this.scrollController, this.userID});

  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /*
  *  Generates feed off data fetched from Firestore
  *  TODO: Figure out a way to handle comment addition to posts more elegantly instead of doing double asynchronous tasks
  * */
  void _generateFeed(List<Map<String, dynamic>> feedData) async {
    print("Generating feed");
    List<Post> iposts = [];
    QuerySnapshot isSaved = await Firestore.instance
        .collection("insta_items")
        .document(currentUserModel.id)
        .collection("items")
        .getDocuments();

    // Add post comments to each post
    for (var postData in feedData) {
      Post post = Post.fromJSON(postData);
      await _retrieveComments(post.postId).then((comments) {
        setState(() {
          if (isSaved.documents != null) {
            isSaved.documents.forEach((element) {
              post.saved = element[post.postId];
            });
          }
          post.comments = comments;
        });
      });
      iposts.add(post);
    }
    setState(() {
      // Sorts posts based on timestamp
      iposts.sort(
          (a, b) => a.timestamp['_seconds'].compareTo(b.timestamp['_seconds']));
      posts = iposts;
    });
  }

  /*
  *  Retrieve post comments from Firestore
  * */
  Future<List<Comment>> _retrieveComments(String postID) async {
    List<Comment> comments = List();
    QuerySnapshot commentData = await Firestore.instance
        .collection("insta_comments")
        .document(postID)
        .collection("comments")
        .getDocuments();
    commentData.documents.forEach((element) {
      comments.add(Comment.fromDocument(element));
    });
    return comments;
  }

  /*
  *  Called when user refreshes the feed
  *  Fetches user specific feed from Firestore
  * */
  void _onRefresh() async {
    // monitor network fetch
    print("Staring getFeed");
    String result;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = currentUserModel.id.toString();
    var url =
        'https://us-central1-instashop-61ed4.cloudfunctions.net/getFeed?uid=' +
            userId;
    var httpClient = HttpClient();

    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
        prefs.setString("feed", json);
        List<Map<String, dynamic>> data =
            jsonDecode(json).cast<Map<String, dynamic>>();
        _generateFeed(data);
        result = "Success in http request for feed";
      } else {
        result =
            'Error getting a feed: Http status ${response.statusCode} | userId $userId';
      }
    } catch (exception) {
      result = 'Failed invoking the getFeed function. Exception: $exception';
    }
    print(result);
    _refreshController.refreshCompleted();
  }

  // Never called but required SmartRefresher args
  void _onLoading() async {
    _refreshController.loadComplete();
  }

  /*
  *  Scrolls to top of page
  * */
  void _scrollToTop() {
    if (widget.scrollController == null) {
      return;
    }
    widget.scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 250),
      curve: Curves.decelerate,
    );
  }

  // TODO: handle loading better instead of using placeholder text if no data exists
  @override
  Widget build(BuildContext context) {
    List<Post> postsReversed = posts.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        backgroundColor: Colors.grey[50],
        title: Row(
          children: <Widget>[
            GestureDetector(
              child: Text(
                'InstaShop',
                style: TextStyle(
                    fontFamily: 'Billabong',
                    color: Colors.black,
                    fontSize: 32.0),
              ),
              onTap: _scrollToTop,
            ),
          ],
        ),
        actions: <Widget>[
          Builder(builder: (BuildContext context) {
            return IconButton(
              color: Colors.black,
              icon: Icon(OMIcons.shoppingCart),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(builder: (BuildContext context) {
                return ShoppingCart();
              })),
            );
          }),
        ],
      ),
      body: SmartRefresher(
          enablePullDown: true,
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: posts.length > 0
              ? ListView.builder(
                  itemBuilder: (ctx, i) {
                    return PostWidget(postsReversed[i]);
                  },
                  itemCount: postsReversed.length,
                  controller: widget.scrollController,
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 200.0, left: 32.0, right: 32.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'This is your home feed. Start following people to see their latest items here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ],
                    ),
                  ),
                )),
    );
  }
}
