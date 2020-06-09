import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instashop/pages/root_page.dart';


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
      // Goes to RootPage to check for user authentication
      home: RootPage()//
      // MainScaffold(),
    );
  }
}
