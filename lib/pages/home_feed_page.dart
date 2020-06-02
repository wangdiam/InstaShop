import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/models/like.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/pages/login_signup_page.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/utils/data_parse_util.dart';
import 'package:instashop/utils/ui_utils.dart';
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

class _HomeFeedPageState extends State<HomeFeedPage> with AutomaticKeepAliveClientMixin<HomeFeedPage>{
  RefreshController _refreshController =
  RefreshController(initialRefresh: true);
  double _lastFeedScrollOffset = 0;


  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("FEED PAGE REBUILD");
  }
  

  void _generateFeed(List<Map<String, dynamic>> feedData) async {
    print("Generating feed");
    List<Post> iposts = [];
    for (var postData in feedData) {
      Post post = Post.fromJSON(postData);
      await retrieveComments(post.postId).then((comments) {
        setState(() {
          post.comments = comments;
        });
      });
      iposts.add(post);
    }
    setState(() {
      posts = iposts;
    });
  }

  Future<List<Comment>> retrieveComments(String postID) async {
    List<Comment> comments = List();
    QuerySnapshot data = await Firestore.instance
        .collection("insta_comments")
        .document(postID)
        .collection("comments")
        .getDocuments();
    data.documents.forEach((element) {
      print("ADDING COMMENT");
      comments.add(Comment.fromDocument(element));
    });
    return comments;
  }


  void _onRefresh() async {
    // monitor network fetch
    print("Staring getFeed");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(currentUserModel);
    String userId = currentUserModel.id.toString();
    var url =
        'https://us-central1-instashop-61ed4.cloudfunctions.net/getFeed?uid=' + userId;
    var httpClient = HttpClient();

    String result;
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

  void _onLoading() async{
    print("LOADING");
    _refreshController.loadComplete();
  }

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


  @override
  Widget build(BuildContext context) {
    print("BUILD HOME FEED");
    List<Post> postsReversed = posts.reversed.toList();
    postsReversed.forEach((element) {print(element.postId);});
    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        backgroundColor: Colors.grey[50],
        title: Row(
          children: <Widget>[
//            Builder(builder: (BuildContext context) {
//              return GestureDetector(
//                child: Icon(OMIcons.cameraAlt, color: Colors.black, size: 32.0),
//                onTap: () => showSnackbar(context, 'Add Photo'),
//              );
//            }),
            //SizedBox(width: 12.0),
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
              icon: Icon(OMIcons.nearMe),
              onPressed: () => showSnackbar(context, 'My Messages'),
            );
          }),
        ],
      ),
      body: SmartRefresher(
        enablePullDown: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: posts.length > 0 ? ListView.builder(
          itemBuilder: (ctx, i) {
            print("itembuilder");
            print(postsReversed[i].postId);
            print("end of itembuilder");
            return PostWidget(postsReversed[i], currentUserModel.id);
          },
          itemCount: postsReversed.length ,
          controller: widget.scrollController,
        ) :
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 200.0, left: 32.0, right: 32.0),
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
        )
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
