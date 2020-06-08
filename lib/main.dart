import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/activity_feed_page.dart';
import 'package:instashop/pages/create_listing_page.dart';
import 'package:instashop/pages/profile_page.dart';
import 'package:instashop/pages/search_page.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:instashop/pages/home_feed_page.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new InstaShop());
  });
}

class InstaShop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        primaryColor: Colors.black,
      ),
      home: RootPage()//
      // MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  MainScaffold({Key key, this.userId, this.logoutCallback})
      : super(key: key);

  final VoidCallback logoutCallback;
  final String userId;

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _tabSelectedIndex = 0;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

 

  final PageStorageBucket bucket = PageStorageBucket();

  // Save the home page scrolling offset,
  // used when navigating back to the home page from another tab.
  double _lastFeedScrollOffset = 0;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //_disposeScrollController();
    super.dispose();
  }

  signOut() async {
    try {
      await baseAuth.signOut();
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


  void _onTabTapped(BuildContext context, int index) {
    if (index == _tabSelectedIndex && index == 0) {
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
        return HomeFeedPage(scrollController: _scrollController, userID: currentUserModel.id);
      case 1:
        return SearchPage();
      case 2:
        return Uploader();
      case 3:
        return ActivityFeedPage();
      case 4:
        return ProfilePage(userId: currentUserModel.id, backButtonNeeded: false);
      default:
        const tabIndexToNameMap = {
          0: 'Home',
          1: 'Search',
          2: 'Add Photo',
          3: 'Notifications',
          4: 'Profile',
        };
        //_disposeScrollController();
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
      body: PageStorage(
        child: _buildBody(currentUserModel.id),
        bucket: bucket,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}

