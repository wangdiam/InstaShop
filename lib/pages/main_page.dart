import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instashop/pages/activity_feed_page.dart';
import 'package:instashop/pages/create_listing_page.dart';
import 'package:instashop/pages/profile_page.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/pages/search_page.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:instashop/pages/home_feed_page.dart';

class MainScaffold extends StatefulWidget {
  MainScaffold({Key key, this.logoutCallback}) : super(key: key);

  final VoidCallback logoutCallback;

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _tabSelectedIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();

  // Save the home page scrolling offset,
  // used when navigating back to the home page from another tab.
  double _lastFeedScrollOffset = 0;
  ScrollController _scrollController = ScrollController();

  /*
  * Scrolls to the top of the view
  * */
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

  /*
  * Helper function of BottomNavigationBar when a tab is tapped
  * */
  void _onTabTapped(BuildContext context, int index) {
    // If index is 0, current page is the feed page
    // _scrollToTop() will only be called when the current page is the feed page
    if (index == 0 && _tabSelectedIndex == index) {
      _scrollToTop();
    } else {
      // Set state of current tapped BottomNavigationBar item to be selected
      // Unselected tabs are outline icons, while the selected tab should be solid.
      setState(() => _tabSelectedIndex = index);
    }
  }

  /*
  * Builds individual pages when corresponding BottomNavigationBar item is selected
  * */
  Widget _buildBody(String userID) {
    switch (_tabSelectedIndex) {
      // Home Feed Page
      case 0:
        _scrollController =
            ScrollController(initialScrollOffset: _lastFeedScrollOffset);
        return HomeFeedPage(
            scrollController: _scrollController, userID: currentUserModel.id);

      // Search Page
      case 1:
        return SearchPage();

      // Upload Page
      case 2:
        return Uploader();

      // Activity Feed Page
      case 3:
        return ActivityFeedPage();

      // Profile Page
      case 4:
        return ProfilePage(
            userId: currentUserModel.id, backButtonNeeded: false);

      default:
        // Will never be called
        return Container();
    }
  }

/*
*  Builds a BottomNavigationBar
* */
  Widget _buildBottomNavigation() {
    const unselectedIcons = <IconData>[
      OMIcons.home,
      OMIcons.search,
      OMIcons.addBox,
      Icons.favorite_border,
      Icons.person_outline,
    ];
    const selectedIcons = <IconData>[
      Icons.home,
      Icons.search,
      Icons.add_box,
      Icons.favorite,
      Icons.person,
    ];
    /*
    * Generates bottom navigation items
    * Icons' selected state will be based on the current selected icon
    * unselectedIcons will be built for icons that are not currently selected
    * selectedIcons will be build for icons that are currently selected
    */
    final bottomNavigationItems = List.generate(5, (int i) {
      final iconData =
          _tabSelectedIndex == i ? selectedIcons[i] : unselectedIcons[i];
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
