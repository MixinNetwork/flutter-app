import 'package:flutter/material.dart';
import './ui/landing/landing.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mixin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LandingPage(title: 'Mixin Messenger'),
    );
  }
}
