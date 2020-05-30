import 'package:flutter/material.dart';
import 'package:instashop/widgets/post_widget.dart';
import 'package:instashop/models/models.dart';

class HomeFeedPage extends StatefulWidget {
  final ScrollController scrollController;
  final List<Post> posts;
  final String userID;


  HomeFeedPage({this.scrollController, this.posts, this.userID});

  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> with AutomaticKeepAliveClientMixin<HomeFeedPage>{


  @override
  void dispose() {
    super.dispose();
  }

  /*
    *//*
    TODO: Fetch from Firebase
    * *//*
    Post(
      user: user2,
      imageUrls: [
        'assets/images/balenciaga_kicks.jpg',
      ],
      likes: [
        Like(user: user1),
        Like(user: user3),
        Like(user: user4),
        Like(user: user5),
      ],
      comments: [
        Comment(
          text: 'Fresh new kicks from Balenciaga!',
          commentedAt: DateTime(2020, 5, 23, 12, 35, 0),
          user: user2,
          likes: [],
        ),
        Comment(
          text: 'Wow nice!',
          user: user1,
          commentedAt: DateTime(2020, 5, 23, 14, 35, 0),
          likes: [Like(user: user1)],
        ),
      ],
      location: 'Earth',
      postedAt: DateTime(2020, 5, 23, 12, 35, 0),
    ),
    Post(
      user: user1,
      imageUrls: ['assets/images/yeezys.jpg'],
      likes: [],
      comments: [],
      location: 'Singapore',
      postedAt: DateTime(2020, 5, 21, 6, 0, 0),
    ),
    Post(
      user: user6,
      imageUrls: ['assets/images/off_white_shoes.jpg'],
      likes: [
        Like(user: user1),
        Like(user: user3),],
      comments: [
        Comment(
          text: "ss20 women's Off-White™ black leather sandals with lace-up closure with knots now available online at off---white.com",
          user: user6,
          commentedAt: DateTime(2020, 5, 2, 0, 0, 0),
          likes: []
        )
      ],
      location: 'Bukit Timah',
      postedAt: DateTime(2020, 5, 2, 0, 0, 0),
    ),
  ]*/

  @override
  Widget build(BuildContext context) {
    List<Post> posts = widget.posts.reversed.toList();
    return ListView.builder(
      itemBuilder: (ctx, i) {
        return PostWidget(posts[i], widget.userID);
      },
      itemCount: widget.posts.length ,
      controller: widget.scrollController,
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
