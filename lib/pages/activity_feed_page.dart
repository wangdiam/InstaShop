import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/widgets/image_tile_widget.dart';
import 'package:instashop/widgets/post_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeedPage extends StatefulWidget {
  @override
  _ActivityFeedPageState createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends State<ActivityFeedPage>
    with AutomaticKeepAliveClientMixin<ActivityFeedPage> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Activity",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: _buildActivityFeed(),
    );
  }

  /*
  *  Activity feed widget
  * */
  Widget _buildActivityFeed() {
    return Container(
      child: FutureBuilder(
          future: _getFeed(),
          builder: (context, snapshot) {
            // If snapshot has no data, show CircularProgressIndicator
            // Else create a list view of snapshot's data
            if (!snapshot.hasData)
              return Container(
                  alignment: FractionalOffset.center,
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CircularProgressIndicator());
            else {
              return ListView(children: snapshot.data);
            }
          }),
    );
  }

  /*
  *  Retrieves feed data from Firestore
  * */
  Future<List<ActivityFeedItem>> _getFeed() async {
    List<ActivityFeedItem> items = [];
    var snap = await Firestore.instance
        .collection('insta_a_feed')
        .document(currentUserModel.id)
        .collection("items")
        .orderBy("timestamp")
        .getDocuments();

    for (var doc in snap.documents) {
      items.insert(0, ActivityFeedItem.fromDocument(doc));
    }
    return items;
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;
}

/*
*  Activity feed item widget
* */
class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // types include liked photo, follow user, comment on photo
  final String mediaUrl;
  final String mediaId;
  final String userProfileImg;
  final String commentData;
  var timestamp;

  ActivityFeedItem(
      {this.username,
      this.userId,
      this.type,
      this.mediaUrl,
      this.mediaId,
      this.userProfileImg,
      this.commentData,
      this.timestamp});

  factory ActivityFeedItem.fromDocument(DocumentSnapshot document) {
    return ActivityFeedItem(
        username: document['username'],
        userId: document['userId'],
        type: document['type'],
        mediaUrl: document['mediaUrl'],
        mediaId: document['postId'],
        userProfileImg: document['userProfileImg'],
        commentData: document["commentData"],
        timestamp: document["timestamp"]);
  }

  Widget mediaPreview = Container(
    height: 45.0,
  );
  String actionText;

  /*
  *  Replaces mediaPreview with post image
  * */
  void configureItem(BuildContext context) {
    if (type == "like" || type == "comment") {
      mediaPreview = GestureDetector(
        onTap: () {
          openPost(context, mediaId, true);
        },
        child: Container(
          height: 45.0,
          width: 45.0,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                fit: BoxFit.fill,
                alignment: FractionalOffset.topCenter,
                image: NetworkImage(mediaUrl),
              )),
            ),
          ),
        ),
      );
    }

    if (type == "like") {
      actionText = " liked your post.";
    } else if (type == "follow") {
      actionText = " is following you.";
    } else if (type == "comment") {
      actionText = " commented: $commentData";
    } else {
      actionText = "Error - invalid activityFeed type: $type";
    }
  }

  /*
  *  Returns difference between DateTime.now() and activity's timestamp in timeago format
  * */
  String timeAgo() {
    final now = DateTime.now();
    try {
      return timeago.format(now.subtract(now.difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000))));
    } catch (e) {
      // Catch error because for some reason the timestamp saved on Firestore can be either a DateTime object or a Map<String, int>
      return timeago.format(now.subtract(now.difference(
          timestamp.runtimeType == DateTime ? timestamp : timestamp.toDate())));
    }
  }

  @override
  Widget build(BuildContext context) {
    configureItem(context);
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 15.0),
          child: GestureDetector(
            onTap: () {
              openProfile(context, userId, true);
            },
            child: CircleAvatar(
              radius: 23.0,
              backgroundImage: NetworkImage(userProfileImg),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      child: Text(
                        username,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        openProfile(context, userId, true);
                      },
                    ),
                    Flexible(
                      child: Container(
                        child: Text(
                          actionText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Text(
                timeAgo(),
                style: TextStyle(fontSize: 10.0, color: Colors.black26),
              ),
            ],
          ),
        ),
        Container(
            child: Align(
                child: Padding(
                  child: mediaPreview,
                  padding: EdgeInsets.all(15.0),
                ),
                alignment: AlignmentDirectional.bottomEnd))
      ],
    );
  }
}

/*
*  public function openPost that opens up a post given current context, imageId
*  and whether a back button is needed in the app bar
*
*  TODO: move this somewhere else
* */
openPost(BuildContext context, String imageId, bool backButtonNeeded) {
  print("the image id is $imageId");
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return Center(
      child: Scaffold(
          appBar: AppBar(
            leading: backButtonNeeded
                ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    color: Colors.black,
                    onPressed: () => Navigator.pop(context, false),
                  )
                : null,
            title: Text('Photo',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
          ),
          body: ListView(
            children: <Widget>[
              Container(
                child: PostWidgetFromId(id: imageId),
              ),
            ],
          )),
    );
  }));
}
