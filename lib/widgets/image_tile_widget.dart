import 'package:flutter/material.dart';
import 'package:instashop/pages/profile_page.dart';
import 'package:instashop/widgets/post_widget.dart';

class ImageTile extends StatelessWidget {
  final PostWidget imagePost;

  ImageTile(this.imagePost);

  /*
  *  Navigates to post when user clicks on image
  * */
  void _clickedImage(BuildContext context) {
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
        onTap: () => _clickedImage(context),
        child: Image.network(imagePost.post.mediaUrl, fit: BoxFit.cover));
  }
}

/*
*  Public function that opens profile of a user given context, userId and whether if a back button is needed in the appbar
* */
void openProfile(BuildContext context, String userId, bool backButtonNeeded) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return ProfilePage(userId: userId, backButtonNeeded: backButtonNeeded);
  }));
}
