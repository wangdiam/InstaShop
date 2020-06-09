import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/utils/ui_utils.dart';
import 'package:instashop/widgets/image_tile_widget.dart';

class CommentWidget extends StatefulWidget {
  Comment comment;
  String firstHalf;
  String secondHalf;
  String username;
  String description;
  String userId;

  CommentWidget(this.comment);
  CommentWidget.description({this.username, this.description, this.userId});

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool flag = false;

  @override
  void initState() {
    super.initState();
    if (widget.comment != null) flag = widget.comment.flag;
    //print("COMMENT WIDGET TEXT: " + this.widget.comment.toJson().toString());
  }

  @override
  void dispose() {
    super.dispose();
  }

  /*
  *  Toggle the comment's expanded state
  *  TODO: Actually add this into comments
  * */
  void _toggleCommentIsExpanded() {
    if (flag) flag = false;
    setState(() => widget.comment.isExpanded(flag));
  }

  /*
  *  Build text span for a comment
  * */
  Container _buildRichText() {
    var textSpans;
    if (widget.comment != null) {
      var currentTextData = StringBuffer();
      textSpans = <TextSpan>[
        TextSpan(
            text: '${widget.comment.username} ',
            style: bold,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                openProfile(context, widget.comment.userId, true);
              }),
      ];
      this.widget.comment.comment.split(' ').forEach((word) {
        if (word.startsWith('#') && word.length > 1) {
          if (currentTextData.isNotEmpty) {
            textSpans.add(TextSpan(text: currentTextData.toString()));
            currentTextData.clear();
          }
          textSpans.add(TextSpan(text: '$word ', style: link));
        } else {
          currentTextData.write('$word ');
        }
      });
      if (currentTextData.isNotEmpty) {
        if ((currentTextData.length + widget.comment.username.length) > 45) {
          widget.firstHalf = currentTextData
              .toString()
              .substring(0, 40 - widget.comment.username.length);
          widget.secondHalf = currentTextData.toString().substring(
              40 - widget.comment.username.length,
              currentTextData.toString().length);
          textSpans.add(TextSpan(
              text: (flag
                  ? widget.firstHalf + "..."
                  : widget.firstHalf + widget.secondHalf)));
        } else {
          widget.firstHalf = currentTextData.toString();
          widget.secondHalf = "";
          textSpans.add(TextSpan(text: widget.firstHalf));
        }

        currentTextData.clear();
      }
    } else {
      var currentTextData = StringBuffer();
      textSpans = <TextSpan>[
        TextSpan(
            text: '${widget.username} ',
            style: bold,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                openProfile(context, widget.userId, true);
              }),
      ];
      this.widget.description.split(' ').forEach((word) {
        if (word.startsWith('#') && word.length > 1) {
          if (currentTextData.isNotEmpty) {
            textSpans.add(TextSpan(text: currentTextData.toString()));
            currentTextData.clear();
          }
          textSpans.add(TextSpan(text: '$word ', style: link));
        } else {
          currentTextData.write('$word ');
        }
      });
      if (currentTextData.isNotEmpty) {
        if ((currentTextData.length + widget.username.length) > 45) {
          widget.firstHalf = currentTextData
              .toString()
              .substring(0, 40 - widget.username.length);
          widget.secondHalf = currentTextData.toString().substring(
              40 - widget.username.length, currentTextData.toString().length);
          textSpans.add(TextSpan(
              text: (flag
                  ? widget.firstHalf + "..."
                  : widget.firstHalf + widget.secondHalf)));
        } else {
          widget.firstHalf = currentTextData.toString();
          widget.secondHalf = "";
          textSpans.add(TextSpan(text: widget.firstHalf));
        }

        currentTextData.clear();
      }
    }

    return new Container(
      padding: new EdgeInsets.symmetric(horizontal: 0.0),
      child: widget.secondHalf != null
          ? new Text.rich(TextSpan(children: textSpans))
          : new Row(
              children: <Widget>[
                //new Text(widget.flag ? (widget.firstHalf + "...") : (widget.firstHalf + widget.secondHalf)),
                Container(
                  constraints: new BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 80),
                  child: Text.rich(TextSpan(children: textSpans)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: new InkWell(
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Text(
                          flag ? "more" : "",
                          style: new TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _toggleCommentIsExpanded();
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildRichText(),
        ],
      ),
    );
  }
}
