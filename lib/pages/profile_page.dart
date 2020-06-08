import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/edit_profile_page.dart';
import 'package:instashop/pages/messaging/messages_page.dart';

import 'dart:async';

import 'package:instashop/pages/root_page.dart';
import 'package:instashop/widgets/post_widget.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<PostWidget> postWidgets = [];

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
    postWidgets = [];
    getPostCount();

  }



  getPostCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    postCount = prefs.getInt("postCount${widget.userId}") != null ? prefs.getInt("postCount${widget.userId}") : 0;
    print(postCount);
  }

  updatePostCountPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("postCount${widget.userId}", postCount);
  }

  editProfile() {
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

  followUser() {
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

  unfollowUser() {
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // reloads state when opened again
    Column buildStatColumn(String label, int number) {
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

    Row buildFollowButton(
        {String text,
        Color backgroundcolor,
        Color textColor,
        Color borderColor,
        Function function}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlatButton(
            onPressed: function,
            child: Container(
              decoration: BoxDecoration(
                  color: backgroundcolor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(5.0)),
              alignment: Alignment.center,
              child: Text(text,
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.bold)),
              width: 300,
              height: 27.0,
            )),
      ]
      );
    }

    Row buildProfileFollowButton(User user) {
      // viewing your own profile - should show edit button
      if (currentUserId == profileId) {
        return buildFollowButton(
          text: "Edit Profile",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey,
          function: editProfile,
        );
      }

      // already following user - should show unfollow button
      if (isFollowing) {
        return buildFollowButton(
          text: "Unfollow",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey,
          function: unfollowUser,
        );
      }

      // does not follow user - should show follow button
      if (!isFollowing) {
        return buildFollowButton(
          text: "Follow",
          backgroundcolor: Colors.blue,
          textColor: Colors.white,
          borderColor: Colors.blue,
          function: followUser,
        );
      }

      return buildFollowButton(
          text: "loading...",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey);
    }

    Row buildImageViewButtonBar() {
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
                changeView("grid");
              },
            ),
          ),
          Container(
            child: IconButton(
              icon: Icon(Icons.list, color: isActiveButtonColor("feed")),
              onPressed: () {
                changeView("feed");
              },
            ),
          ),
        ],
      );
    }

    Future<List<Comment>> retrieveComments(String postID) async {
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

    Container buildUserPosts() {
      Future<List<PostWidget>> getPosts() async {
        List<PostWidget> widgets = [];
        var snap = await Firestore.instance
            .collection('insta_posts')
            .where('ownerId', isEqualTo: profileId)
            .orderBy("timestamp")
            .getDocuments();
        for (var doc in snap.documents) {
          Post post = Post.fromDocument(doc);
          List<Comment> comments = await retrieveComments(post.postId);
          post.comments = comments;
          widgets.add(PostWidget(post));
        }
        setState(() {
          postCount = snap.documents.length;
          updatePostCountPrefs();
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

          if (user.followers.containsKey(currentUserId) &&
              user.followers[currentUserId] &&
              followButtonClicked == false) {
            isFollowing = true;
          }

          return Scaffold(
              appBar: AppBar(
//                automaticallyImplyLeading: true,
                leading: widget.backButtonNeeded ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  color: Colors.black,
                  onPressed: () => Navigator.pop(context,false),
                ) : null,
                actions: <Widget>[
                  Builder(builder: (BuildContext context) {
                    return IconButton(
                      color: Colors.black,
                      icon: Icon(OMIcons.email),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
                        return MainChatScreen(currentUserId: currentUserModel.id,);
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
                    padding: const EdgeInsets.fromLTRB(16.0,16.0,16.0,16.0),
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
                                    padding: const EdgeInsets.only(left:16.0,right:0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Expanded(
                                            child: buildStatColumn("Posts", postCount),
                                          flex: 1,
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: buildStatColumn("Followers",
                                              _countFollowings(user.followers)),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: buildStatColumn("Following",
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
                            padding: const EdgeInsets.only(top: 15.0, bottom: 4.0),
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
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              buildProfileFollowButton(user)
                            ]),
                      ],
                    ),
                  ),
                  Divider(),
                  buildImageViewButtonBar(),
                  Divider(height: 0.0),
                  buildUserPosts(),
                ],
              ));
        });
  }

  changeView(String viewName) {
    setState(() {
      view = viewName;
    });
  }

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

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;
}

class ImageTile extends StatelessWidget {
  final PostWidget imagePost;

  ImageTile(this.imagePost);

  clickedImage(BuildContext context) {
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
              title: Text('Photo',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: imagePost,
                ),
              ],
            )),
      );
    }));
  }

  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => clickedImage(context),
        child: Image.network(imagePost.post.mediaUrl, fit: BoxFit.cover));
  }
}

void openProfile(BuildContext context, String userId, bool backButtonNeeded) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return ProfilePage(userId: userId, backButtonNeeded: backButtonNeeded);
  }));
}
