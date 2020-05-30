import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instashop/utils/heart_icon_animator.dart';
import 'package:instashop/models/models.dart';
import 'package:instashop/utils/ui_utils.dart';

import '../main.dart';

class CommentWidget extends StatefulWidget {
  final Comment comment;
  String firstHalf;
  String secondHalf;


  CommentWidget(this.comment);


  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool flag;

  @override
  void initState() {
    super.initState();
    flag = widget.comment.flag;
  }

  @override
  dispose() {
    super.dispose();
  }


  void _toggleCommentIsExpanded() {
    if (flag) flag = false;
    setState(() => widget.comment.isExpanded(flag));
  }

  Container _buildRichText() {
    var currentTextData = StringBuffer();
    var textSpans = <TextSpan>[
      TextSpan(
          text: '${widget.comment.user.name} ',
          style: bold,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              print('Clicked Profile name"');
            }),
    ];
    this.widget.comment.text.split(' ').forEach((word) {
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
      if ((currentTextData.length + widget.comment.user.name.length) > 45) {
        widget.firstHalf = currentTextData.toString().substring(0, 40-widget.comment.user.name.length);
        widget.secondHalf = currentTextData.toString().substring(40-widget.comment.user.name.length, currentTextData.toString().length);
        textSpans.add(TextSpan(text: (flag ? widget.firstHalf + "..." : widget.firstHalf + widget.secondHalf)));
      } else {
        widget.firstHalf = currentTextData.toString();
        widget.secondHalf = "";
        textSpans.add(TextSpan(text: widget.firstHalf));
      }

      currentTextData.clear();
    }
    //return Text.rich(TextSpan(children: textSpans));
    return new Container(
      padding: new EdgeInsets.symmetric(horizontal: 0.0),
      child: widget.secondHalf.isEmpty
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
    print("CURRENTUSER " + currentUser.toJSON().toString());
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