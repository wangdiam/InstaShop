import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/choice.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/comment_screen_page.dart';
import 'package:instashop/pages/messaging/chat_page.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/utils/heart_icon_animator.dart';
import 'package:instashop/utils/heart_overlay_animator.dart';
import 'package:instashop/utils/styles.dart';
import 'package:instashop/widgets/image_tile_widget.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:instashop/widgets/comment_widget.dart';
import 'package:instashop/utils/ui_utils.dart';

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Report this post', icon: Icons.flag),
];

class PostWidget extends StatefulWidget {
  final Post post;

  PostWidget(this.post);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final StreamController<void> _doubleTapImageEvents =
      StreamController.broadcast();
  int _currentImageIndex = 0;
  int _selectedChoice = 0;
  int likeCount = 0;
  bool liked;
  bool showHeart = false;
  bool _isSaved = false;
  var reference = Firestore.instance.collection('insta_posts');
  List<String> likedUsers = List();
  List<String> likedUsersId = List();

  @override
  void initState() {
    super.initState();
    
    // Checks if post is liked by current user
    liked = widget.post.likes[currentUserModel.id] != null &&
        widget.post.likes[currentUserModel.id][currentUserModel.username];
    if (widget.post.likes != null) {
      widget.post.likes.forEach((key, value) {
        value.forEach((k, v) {
          if (v.toString() == true.toString()) {
            likedUsers.add(k);
            likedUsersId.add(key);
          }
        });
      });
    }
    
    // Checks if post is added to current user's cart
    if (widget.post.saved != null && widget.post.saved != false) {
      setState(() {
        _isSaved = true;
      });
    }
    _currentImageIndex = 0;
  }

  @override
  void dispose() {
    _doubleTapImageEvents.close();
    super.dispose();
  }

  /*
  *  Current user action: like or unlike this post
  * */
  void _likePost() {
    var userId = currentUserModel.id;
    var userName = currentUserModel.username;
    if (liked) {
      print('removing like');
      reference.document(widget.post.postId).updateData({
        'likes.$userId.$userName': false,
        //firestore plugin doesnt support deleting, so it must be nulled / falsed
      });

      setState(() {
        likedUsers.remove(currentUserModel.username);
        likeCount = likeCount - 1;
        liked = false;
        widget.post.likes[userId] = {userName: false};
      });

      removeActivityFeedItem();
    } else if (!liked) {
      print('liking');
      reference
          .document(widget.post.postId)
          .updateData({'likes.$userId.$userName': true});

      addActivityFeedItem();

      setState(() {
        likedUsers.add(currentUserModel.username);
        likeCount = likeCount + 1;
        liked = true;
        widget.post.likes[userId] = {userName: true};
        showHeart = true;
      });
    }
  }

  /*
  *  Add activity event to owner's activity feed
  * */
  void addActivityFeedItem() {
    Firestore.instance
        .collection("insta_a_feed")
        .document(widget.post.ownerId)
        .collection("items")
        .document(widget.post.postId)
        .setData({
      "username": currentUserModel.username,
      "userId": currentUserModel.id,
      "type": "like",
      "userProfileImg": currentUserModel.photoUrl,
      "mediaUrl": widget.post.mediaUrl,
      "timestamp": DateTime.now(),
      "postId": widget.post.postId,
    });
  }

  /*
  *  Removes activity event from owner's activity feed
  * */
  void removeActivityFeedItem() {
    Firestore.instance
        .collection("insta_a_feed")
        .document(widget.post.ownerId)
        .collection("items")
        .document(widget.post.postId)
        .delete();
  }

  /*
  *  Updates image index for ImageCarousel
  *  TODO: Implement this carousel
  * */
  void _updateImageIndex(int index) {
    setState(() => _currentImageIndex = index);
  }

  /*
  *  Triggers when user double taps photo of post
  * */
  void _onDoubleTapLikePhoto() {
    _doubleTapImageEvents.sink.add(null);
    _likePost();
  }

  /*
  *  Toggle item saved to current user's cart
  * */
  void _toggleIsSavedToCart() {
    setState(() {
      _isSaved = !_isSaved;
      widget.post.saved = _isSaved;
    });
    if (_isSaved) {
      _addItemToCart(widget.post, currentUserModel.id);
      showSnackbar(context, "Item has been added to cart!");
    } else {
      _removeItemFromCart(widget.post, currentUserModel.id);
      showSnackbar(context, "Item has been removed from cart!");
    }
  }

  /*
  *  Add item to current user's cart
  * */
  void _addItemToCart(Post post, String userID) async {
    Firestore.instance
        .collection('insta_items')
        .document(currentUserModel.id)
        .collection("items")
        .document(post.ownerId)
        .setData({"${post.postId}": true}, merge: true);
  }

  /*
  *  Remove item from current user's cart
  * */
  void _removeItemFromCart(Post post, String userID) async {
    Firestore.instance
        .collection('insta_items')
        .document(currentUserModel.id)
        .collection("items")
        .document(post.ownerId)
        .setData({"${post.postId}": false}, merge: true);
  }

  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _selectedChoice = 0;
      //TODO: submit postID of post for report
      //TODO: Implement delete post if current user is post's owner
    });
  }

  Container loadingPlaceHolder = Container(
    height: 400.0,
    child: Center(child: CircularProgressIndicator()),
  );

  /*
  *  Fetch post owner's user data from Firestore
  * */
  Future<DocumentSnapshot>_fetchOwnerData() async {
    var docs = await Firestore.instance
        .collection('insta_users')
        .document(widget.post.ownerId)
        .get();
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    String postOwnerPhotoUrl;
    String postOwnerName;
    return Column(
      children: <Widget>[
        // User Details
        Row(
          children: <Widget>[
            //AvatarWidget(user: widget.post.ownerId),
            FutureBuilder(
                future: _fetchOwnerData(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    postOwnerPhotoUrl = snapshot.data.data['photoUrl'];
                    postOwnerName = snapshot.data.data['username'];
                    return Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                                snapshot.data.data['photoUrl']),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              child: Text(snapshot.data.data['username'],
                                  style: boldStyle),
                              onTap: () {
                                openProfile(context, widget.post.ownerId, true);
                              },
                            ),
                            Text(widget.post.location),
                          ],
                        )
                      ],
                    );
                  }

                  // snapshot data is null here
                  return Container();
                }),
            Spacer(),
            PopupMenuButton<Choice>(
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return choices.map((Choice choice) {
                  return PopupMenuItem<Choice>(
                    value: choice,
                    child: Text(choice.title),
                  );
                }).toList();
              },
            ),
          ],
        ),
        // Photo Carousel
        // TODO: Include feature for multi picture posts
        GestureDetector(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CarouselSlider(
                items: [
                  CachedNetworkImage(
                    imageUrl: widget.post.mediaUrl,
                    fit: BoxFit.fitWidth,
                    width: MediaQuery.of(context).size.width,
                    placeholder: (context, url) => loadingPlaceHolder,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ],
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                aspectRatio: 1,
                onPageChanged: _updateImageIndex,
              ),
              HeartOverlayAnimator(
                  triggerAnimationStream: _doubleTapImageEvents.stream),
            ],
          ),
          onDoubleTap: _onDoubleTapLikePhoto,
        ),
        // Action Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: HeartIconAnimator(
                isLiked: liked, //widget.post.isLikedBy(currentUserModel),
                size: 28.0,
                onTap: _likePost,
                triggerAnimationStream: _doubleTapImageEvents.stream,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              iconSize: 28.0,
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(builder: (BuildContext context) {
                return CommentScreen(
                  postId: widget.post.postId,
                  postOwner: widget.post.ownerId,
                  postMediaUrl: widget.post.mediaUrl,
                );
              })),
            ),
            (widget.post.ownerId != currentUserModel.id)
                ? IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 28.0,
                    icon: Icon(OMIcons.nearMe),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                            builder: (BuildContext context) {
                      return Chat(
                          peerId: widget.post.ownerId,
                          peerAvatar: postOwnerPhotoUrl,
                          peerUserName: postOwnerName);
                    })),
                  )
                : SizedBox(),
            Spacer(),
//            if (widget.post.imageUrls.length > 1)
//              PhotoCarouselIndicator(
//                photoCount: widget.post.imageUrls.length,
//                activePhotoIndex: _currentImageIndex,
//              ),
            Spacer(),
            Spacer(),
            (widget.post.ownerId != currentUserModel.id)
                ? IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 28.0,
                    icon: _isSaved
                        ? Icon(OMIcons.removeShoppingCart)
                        : Icon(OMIcons.addShoppingCart),
                    onPressed: _toggleIsSavedToCart,
                  )
                : SizedBox()
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0, right: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Liked by
              if (likedUsers.length > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: <Widget>[
                      Text('Liked by '),
                      Text.rich(TextSpan(
                          text: likedUsers[0],
                          style: bold,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              openProfile(
                                  context,
                                  likedUsersId[
                                      likedUsers.indexOf(likedUsers[0])],
                                  true);
                            })),
                      if (likedUsers.length > 1) ...[
                        Text(' and'),
                        Text(' ${likedUsers.length - 1} others', style: bold),
                      ]
                    ],
                  ),
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(builder: (BuildContext context) {
                  return CommentScreen(
                    postId: widget.post.postId,
                    postOwner: widget.post.ownerId,
                    postMediaUrl: widget.post.mediaUrl,
                  );
                })),
                child: Column(
                  children: [
                    if (widget.post.description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0.0),
                        child: Column(children: [
                          CommentWidget.description(
                              description: widget.post.description,
                              username: widget.post.username,
                              userId: widget.post.ownerId),
                        ]),
                      ),
                    // Comments
                    if (widget.post.comments != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Column(
                          children: widget.post.comments
                              .sublist(widget.post.comments.length > 3
                                  ? widget.post.comments.length - 2
                                  : 0)
                              .map((Comment c) => CommentWidget(c))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Text(
                  "Price: \$${widget.post.price}",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w900),
                ),
              ),
              // Add a comment...
//              Row(
//                children: <Widget>[
//                  AvatarWidget(
//                    user: currentUserModel,
//                    padding: EdgeInsets.only(right: 8.0),
//                  ),
//                  GestureDetector(
//                    child: Text(
//                      'Add a comment...',
//                      style: TextStyle(color: Colors.grey),
//                    ),
//                    onTap: _showAddCommentModal,
//                  ),
//                ],
//              ),
              // Posted Timestamp
              Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.post.timeAgo(),
                  style: TextStyle(color: Colors.grey, fontSize: 11.0),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class PhotoCarouselIndicator extends StatelessWidget {
  final int photoCount;
  final int activePhotoIndex;

  PhotoCarouselIndicator({
    @required this.photoCount,
    @required this.activePhotoIndex,
  });

  Widget _buildDot({bool isActive}) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(left: 3.0, right: 3.0),
        child: Container(
          height: isActive ? 7.5 : 6.0,
          width: isActive ? 7.5 : 6.0,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(photoCount, (i) => i)
          .map((i) => _buildDot(isActive: i == activePhotoIndex))
          .toList(),
    );
  }
}

class AddCommentModal extends StatefulWidget {
  final User user;
  final ValueChanged<String> onPost;

  AddCommentModal({@required this.user, @required this.onPost});

  @override
  _AddCommentModalState createState() => _AddCommentModalState();
}

class _AddCommentModalState extends State<AddCommentModal> {
  final _textController = TextEditingController();
  bool _canPost = false;

  @override
  void initState() {
    _textController.addListener(() {
      setState(() => _canPost = _textController.text.isNotEmpty);
    });
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        //AvatarWidget(user: widget.user),
        Expanded(
          child: TextField(
            controller: _textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: InputBorder.none,
            ),
          ),
        ),
        FlatButton(
          child: Opacity(
            opacity: _canPost ? 1.0 : 0.4,
            child: Text('Post', style: TextStyle(color: Colors.blue)),
          ),
          onPressed:
              _canPost ? () => widget.onPost(_textController.text) : null,
        )
      ],
    );
  }
}

class PostWidgetFromId extends StatelessWidget {
  final String id;

  const PostWidgetFromId({this.id});

  getImagePost() async {
    var document =
        await Firestore.instance.collection('insta_posts').document(id).get();
    Post post = Post.fromDocument(document);
    return PostWidget(post);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getImagePost(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                padding: const EdgeInsets.only(top: 10.0),
                child: CircularProgressIndicator());
          return snapshot.data;
        });
  }
}
