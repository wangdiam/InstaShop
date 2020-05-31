import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/utils/data_parse_util.dart';
import 'package:instashop/widgets/post_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeFeedPage extends StatefulWidget {
  final ScrollController scrollController;
  final List<Post> posts;
  final String userID;


  HomeFeedPage({this.scrollController, this.posts, this.userID});

  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> with AutomaticKeepAliveClientMixin<HomeFeedPage>{
  RefreshController _refreshController =
  RefreshController(initialRefresh: false);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _onRefresh();
  }

  void _onRefresh() async {
    // monitor network fetch
    final dbRef = FirebaseDatabase.instance.reference().child("posts").once().then((value) {
      widget.posts.clear();
      value.value.forEach((k, v) {
        setState(() {
          widget.posts.add(DataParseUtils().mapToPost(k, v));
        });
      });
      widget.posts.sort((a,b) => int.parse(a.postedAt).compareTo(int.parse(b.postedAt)));
      _refreshController.refreshCompleted();
    });
    // if failed,use refreshFailed()
  }

  void _onLoading() async{
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    //items.add((items.length+1).toString());
    if(mounted)
      setState(() {

      });
    _refreshController.loadComplete();
  }


  @override
  Widget build(BuildContext context) {
    List<Post> posts = widget.posts.reversed.toList();
    return SmartRefresher(
      enablePullDown: true,
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: ListView.builder(
        itemBuilder: (ctx, i) {
          return PostWidget(posts[i], currentUser.userID);
        },
        itemCount: widget.posts.length ,
        controller: widget.scrollController,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
