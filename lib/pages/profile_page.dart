import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/edit_profile_page.dart';
import 'package:instashop/pages/messaging/messages_page.dart';

import 'dart:async';

import 'package:instashop/pages/root_page.dart';
import 'package:instashop/widgets/image_tile_widget.dart';
import 'package:instashop/widgets/post_widget.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({this.userId, this.backButtonNeeded});

  final String userId;
  final bool backButtonNeeded;

  _ProfilePage createState() => _ProfilePage(this.userId);
}

class _ProfilePage extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin<ProfilePage> {
  final String profileId;
  String currentUserId = currentUserModel.id;
  String view = "grid"; // default view
  bool isFollowing = false;
  bool followButtonClicked = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  _ProfilePage(this.profileId);

  @override
  void initState() {
    super.initState();
    _getPostCount();
  }

  /*
  *  Get post count from SharedPreferences
  *  If value does not exist, postCount will be set to 0
  * */
  void _getPostCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    postCount = prefs.getInt("postCount${widget.userId}") != null
        ? prefs.getInt("postCount${widget.userId}")
        : 0;
    print(postCount);
  }

  /*
  *  Update SharedPreferences with new post count
  * */
  void _updatePostCountPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("postCount${widget.userId}", postCount);
  }

  /*
  *  Navigates to EditProfilePage
  * */
  void editProfile() {
    EditProfilePage editPage = EditProfilePage();

    Navigator.of(context)
        .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
      return Center(
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                color: Colors.black,
                onPressed: () {
                  Navigator.maybePop(context);
                },
              ),
              title: Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              actions: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.check,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () {
                      editPage.applyChanges();
                      Navigator.maybePop(context);
                    })
              ],
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: editPage,
                ),
              ],
            )),
      );
    }));
  }

  /*
  *  Set state on following a user
  *  Updates Firestore of followed users
  * */
  void _followUser() {
    setState(() {
      this.isFollowing = true;
      followButtonClicked = true;
    });

    Firestore.instance.document("insta_users/$profileId").updateData({
      'followers.$currentUserId': true
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });

    Firestore.instance.document("insta_users/$currentUserId").updateData({
      'following.$profileId': true
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });

    //updates activity feed
    Firestore.instance
        .collection("insta_a_feed")
        .document(profileId)
        .collection("items")
        .document(currentUserId)
        .setData({
      "ownerId": profileId,
      "username": currentUserModel.username,
      "userId": currentUserId,
      "type": "follow",
      "userProfileImg": currentUserModel.photoUrl,
      "timestamp": DateTime.now()
    });
  }

  /*
  *  Set state on unfollowing a user
  *  Updates Firestore of followed users
  * */
  void _unfollowUser() {
    setState(() {
      isFollowing = false;
      followButtonClicked = true;
    });

    Firestore.instance.document("insta_users/$profileId").updateData({
      'followers.$currentUserId': false
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });

    Firestore.instance.document("insta_users/$currentUserId").updateData({
      'following.$profileId': false
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });

    Firestore.instance
        .collection("insta_a_feed")
        .document(profileId)
        .collection("items")
        .document(currentUserId)
        .delete();
  }

  /*
  *  Set state of button bar to either list view or grid view
  * */
  void _changeView(String viewName) {
    setState(() {
      view = viewName;
    });
  }

  /*
  *  Count followers/followings given a map
  * */
  int _countFollowings(Map followings) {
    int count = 0;

    void countValues(key, value) {
      if (value) {
        count += 1;
      }
    }

    followings.forEach(countValues);

    return count;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    /*
    *  Builds user following/follower stats widget
    * */
    Column _buildStatColumn(String label, int number) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            number.toString(),
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          ),
          Container(
              margin: const EdgeInsets.only(top: 4.0),
              child: Text(
                label,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400),
              ))
        ],
      );
    }

    /*
    *  Build follow/unfollow button
    * */
    Row _buildFollowButton(
        {String text,
        Color backgroundcolor,
        Color textColor,
        Color borderColor,
        Function function}) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        FlatButton(
            onPressed: function,
            child: Container(
              decoration: BoxDecoration(
                  color: backgroundcolor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(5.0)),
              alignment: Alignment.center,
              child: Text(text,
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              width: 300,
              height: 27.0,
            )),
      ]);
    }

    /*
    *  Build follow/unfollow/edit profile button based on current state
    * */
    Row _buildProfileFollowButton(User user) {
      // viewing your own profile - should show edit button
      if (currentUserId == profileId) {
        return _buildFollowButton(
          text: "Edit Profile",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey,
          function: editProfile,
        );
      }

      // already following user - should show unfollow button
      if (isFollowing) {
        return _buildFollowButton(
          text: "Unfollow",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey,
          function: _unfollowUser,
        );
      }

      // does not follow user - should show follow button
      if (!isFollowing) {
        return _buildFollowButton(
          text: "Follow",
          backgroundcolor: Colors.blue,
          textColor: Colors.white,
          borderColor: Colors.blue,
          function: _followUser,
        );
      }

      return _buildFollowButton(
          text: "loading...",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey);
    }

    /*
    *  Changes button color based on current posts view state
    * */
    Row _buildImageViewButtonBar() {
      Color isActiveButtonColor(String viewName) {
        if (view == viewName) {
          return Colors.blueAccent;
        } else {
          return Colors.black26;
        }
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Container(
            child: IconButton(
              icon: Icon(Icons.grid_on, color: isActiveButtonColor("grid")),
              onPressed: () {
                _changeView("grid");
              },
            ),
          ),
          Container(
            child: IconButton(
              icon: Icon(Icons.list, color: isActiveButtonColor("feed")),
              onPressed: () {
                _changeView("feed");
              },
            ),
          ),
        ],
      );
    }

    /*
    *  Retrieves comments from Firestore
    *  TODO: I believe previously cached comments can be used in some way. Need to figure it out.
    * */
    Future<List<Comment>> _retrieveComments(String postID) async {
      List<Comment> comments = List();
      QuerySnapshot data = await Firestore.instance
          .collection("insta_comments")
          .document(postID)
          .collection("comments")
          .getDocuments();
      data.documents.forEach((element) {
        comments.add(Comment.fromDocument(element));
      });
      return comments;
    }

    /*
    *  Builds feed-like view
    * */
    Container _buildUserPosts() {
      Future<List<PostWidget>> getPosts() async {
        List<PostWidget> widgets = [];
        var snap = await Firestore.instance
            .collection('insta_posts')
            .where('ownerId', isEqualTo: profileId)
            .orderBy("timestamp")
            .getDocuments();
        for (var doc in snap.documents) {
          Post post = Post.fromDocument(doc);
          List<Comment> comments = await _retrieveComments(post.postId);
          post.comments = comments;
          widgets.add(PostWidget(post));
        }
        setState(() {
          postCount = snap.documents.length;
          _updatePostCountPrefs();
        });
        return widgets.reversed.toList();
      }

      return Container(
          child: FutureBuilder<List<PostWidget>>(
        future: getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                padding: const EdgeInsets.only(top: 10.0),
                child: CircularProgressIndicator());
          else if (view == "grid") {
            // build the grid
            return GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
//                    padding: const EdgeInsets.all(0.5),
                mainAxisSpacing: 1.5,
                crossAxisSpacing: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data.map((PostWidget imagePost) {
                  return GridTile(child: ImageTile(imagePost));
                }).toList());
          } else if (view == "feed") {
            return Column(
                children: snapshot.data.map((PostWidget imagePost) {
              return imagePost;
            }).toList());
          } else {
            return Container();
          }
        },
      ));
    }

    /*
    *  Builds actual Profile page
    * */
    return StreamBuilder(
        stream: Firestore.instance
            .collection('insta_users')
            .document(profileId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator());

          User user = User.fromDocument(snapshot.data);

          // Checks if users are in following/follower list
          if (user.followers.containsKey(currentUserId) &&
              user.followers[currentUserId] &&
              followButtonClicked == false) {
            isFollowing = true;
          }

          return Scaffold(
              appBar: AppBar(
                leading: widget.backButtonNeeded
                    ? IconButton(
                        icon: Icon(Icons.arrow_back),
                        color: Colors.black,
                        onPressed: () => Navigator.pop(context, false),
                      )
                    : null,
                actions: <Widget>[
                  Builder(builder: (BuildContext context) {
                    return IconButton(
                      color: Colors.black,
                      icon: Icon(OMIcons.email),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<bool>(
                              builder: (BuildContext context) {
                        return MainChatScreen(
                          currentUserId: currentUserModel.id,
                        );
                      })),
                    );
                  }),
                ],
                title: Text(
                  user.username,
                  style: const TextStyle(color: Colors.black),
                ),
                backgroundColor: Colors.white,
              ),
              body: ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 40.0,
                              backgroundColor: Colors.grey,
                              backgroundImage: NetworkImage(user.photoUrl),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16.0, right: 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Expanded(
                                          child: _buildStatColumn(
                                              "Posts", postCount),
                                          flex: 1,
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildStatColumn("Followers",
                                              _countFollowings(user.followers)),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildStatColumn("Following",
                                              _countFollowings(user.following)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        Container(
                            alignment: Alignment.centerLeft,
                            padding:
                                const EdgeInsets.only(top: 15.0, bottom: 4.0),
                            child: Text(
                              user.displayName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(user.bio),
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              _buildProfileFollowButton(user)
                            ]),
                      ],
                    ),
                  ),
                  Divider(),
                  _buildImageViewButtonBar(),
                  Divider(height: 0.0),
                  _buildUserPosts(),
                ],
              ));
        });
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;
}
