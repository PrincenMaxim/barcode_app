// ignore_for_file: library_private_types_in_public_api

import 'package:barcode_app/orderpage.dart';
import 'package:flutter/material.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _currentPage = 'order-page';
 
  void nextPage() {
    var pageToSet = _currentPage;
    if (_currentPage == 'order-page') {
      pageToSet = 'inventorycheck-page';
    }

    setState(() {
      _currentPage = pageToSet;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget returnWidget = OrderPage(nextPageFunc: nextPage,);
    if(_currentPage == 'order-page') returnWidget = OrderPage(nextPageFunc: nextPage);

    return returnWidget;
  }
}
