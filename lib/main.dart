import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instashop/models/post.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:instashop/pages/home_feed_page.dart';
import 'package:instashop/utils/ui_utils.dart';
import 'package:instashop/services/authentication.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/models/user.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        primaryColor: Colors.black,
      ),
      home: RootPage(auth: Auth())//
      // MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  MainScaffold({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with AutomaticKeepAliveClientMixin<MainScaffold>{
  static const _kAddPhotoTabIndex = 2;
  int _tabSelectedIndex = 0;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  StreamSubscription<Event> _onPostAddedSubscription;

  Query _postQuery;
  Query _userInfoQuery;
  List<Post> _postList;
 

  final PageStorageBucket bucket = PageStorageBucket();

  // Save the home page scrolling offset,
  // used when navigating back to the home page from another tab.
  double _lastFeedScrollOffset = 0;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _postList = List();
    _postQuery = _database
        .reference()
        .child("posts");
    //_onPostAddedSubscription = _postQuery.onChildAdded.listen(onPostAdded);
    _userInfoQuery = _database.reference().child("users");
    //print("MAIN: " + currentUser.toJson().toString());
  }

  @override
  void dispose() {
    _disposeScrollController();
    super.dispose();
  }



  onPostAdded(Event event) {
    //print("post added!");
    Post post = Post.fromSnapshot(event.snapshot);
    setState(() {
      _postList.add(post);
    });
  }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  void _scrollToTop() {
    if (_scrollController == null) {
      return;
    }
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 250),
      curve: Curves.decelerate,
    );
  }

  // Call this when changing the body that doesn't use a ScrollController.
  void _disposeScrollController() {
    if (_scrollController != null) {
      _lastFeedScrollOffset = _scrollController.offset;
      _scrollController.dispose();
      _scrollController = null;
    }
  }

  void _onTabTapped(BuildContext context, int index) {
    if (index == _kAddPhotoTabIndex) {
      //print("BEFORE post: " + currentUser.toJson().toString());
      Post post = Post(
          user: currentUser,
          imageUrls: [
            'assets/images/balenciaga_kicks.jpg',
            'assets/images/yeezys.jpg'
          ],
          likedUsers: [],
          comments: [],
          location: 'Singapore',
          postedAt: DateTime.now().millisecondsSinceEpoch.toString()
      );
      _database.reference().child("posts").push().set(post.toJson());
    } else if (index == _tabSelectedIndex) {
      _scrollToTop();
    } else {
      setState(() => _tabSelectedIndex = index);
    }
  }


  Widget _buildPlaceHolderTab(String tabName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 64.0),
        child: Column(
          children: <Widget>[
            Text(
              'Oops, the $tabName tab is\n under construction!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28.0),
            ),
            Image.asset('assets/images/building.gif'),
            MaterialButton(
                onPressed: signOut,
                child: Text("Sign Out"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String userID) {
    switch (_tabSelectedIndex) {
      case 0:
        _scrollController =
            ScrollController(initialScrollOffset: _lastFeedScrollOffset);
        //print("REBUILDING BODY");
        return HomeFeedPage(scrollController: _scrollController, posts: _postList, userID: userID);
      default:
        const tabIndexToNameMap = {
          0: 'Home',
          1: 'Search',
          2: 'Add Photo',
          3: 'Notifications',
          4: 'Profile',
        };
        _disposeScrollController();
        return _buildPlaceHolderTab(tabIndexToNameMap[_tabSelectedIndex]);
    }
  }

  // Unselected tabs are outline icons, while the selected tab should be solid.
  Widget _buildBottomNavigation() {
    const unselectedIcons = <IconData>[
      OMIcons.home,
      Icons.search,
      OMIcons.addBox,
      Icons.favorite_border,
      Icons.person_outline,
    ];
    const selecteedIcons = <IconData>[
      Icons.home,
      Icons.search,
      Icons.add_box,
      Icons.favorite,
      Icons.person,
    ];
    final bottomNavigationItems = List.generate(5, (int i) {
      final iconData =
          _tabSelectedIndex == i ? selecteedIcons[i] : unselectedIcons[i];
      return BottomNavigationBarItem(icon: Icon(iconData), title: Container());
    }).toList();

    return Builder(builder: (BuildContext context) {
      return BottomNavigationBar(
        iconSize: 32.0,
        type: BottomNavigationBarType.fixed,
        items: bottomNavigationItems,
        currentIndex: _tabSelectedIndex,
        onTap: (int i) => _onTabTapped(context, i),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        backgroundColor: Colors.grey[50],
        title: Row(
          children: <Widget>[
            Builder(builder: (BuildContext context) {
              return GestureDetector(
                child: Icon(OMIcons.cameraAlt, color: Colors.black, size: 32.0),
                onTap: () => showSnackbar(context, 'Add Photo'),
              );
            }),
            SizedBox(width: 12.0),
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
      body: PageStorage(
        child: _buildBody(widget.userId),
        bucket: bucket,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
