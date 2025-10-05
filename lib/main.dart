import 'package:flutter/foundation.dart';
// foundation.dart package provides basic Flutter framework functionalities
import 'package:flutter/material.dart';

// so basically the way to modularize code in Flutter is by creating widgets
// widgets are the building blocks of a Flutter app
// everything in Flutter is a widget
// widgets are basically reusable components that can be combined to create complex UIs
// so to modularize code we create custom widgets by extending StatelessWidget or StatefulWidget
// StatelessWidget is used when the widget does not need to manage any state
// StatefulWidget is used when the widget needs to manage state
// state like data that can change over time
// for example, a button that changes its color when pressed

void main() {
  // The main function is the entry point of the application
  runApp(MyApp());
  // runApp function takes a widget and makes it the root of the widget tree
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // MyApp is a stateless widget that represents the application

  // StatelessWidget is used when the widget does not need to manage any state
  // state like data that can change over time

  @override
  // @override means we are overriding the build method of StatelessWidget
  // it is basically used to customize the behavior of the parent class
  // in this case, we are customizing how the widget is built
  // like defining the UI of the widget
  Widget build(BuildContext context) {
    // widget build method is called whenever the widget needs to be rendered
    // context provides information about the location of this widget in the widget tree
    // here BuildContext is a handle to the location of a widget in the widget tree
    // handle means like reference or address

    return MaterialApp(
      // returning a MaterialApp widget
      // MaterialApp is a convenience widget that wraps a number of widgets that are commonly required for material design applications
      // like navigation, theming, etc.
      debugShowCheckedModeBanner: false,

      // debugShowCheckedModeBanner is used to hide the debug banner in the top right corner
      // it is useful when you want to show a clean UI without the debug banner
      title: 'Flutter Basic App', // title of the application

      theme: ThemeData(
        // theme of the application
        // ThemeData is used to configure the visual theme of the application
        // like colors, fonts, and other visual properties
        primarySwatch: Colors.blue,
        // primarySwatch defines the primary color of the application
      ),
      home: MyHomePage(), // home is the default route of the application
      // MyHomePage is a custom widget that represents the home screen of the application
      // like the main screen that users see when they open the app
      // similarly we can define other routes for navigation
      // such as login, settings, profile, etc.
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  // MyHomePage is a stateless widget that represents the home screen of the application
  // it is a custom widget that we defined to show the main content of the app

  // extends StatelessWidget means MyHomePage inherits properties and methods from StatelessWidget
  // so we can use those properties and methods in MyHomePage

  @override // overriding the build method of StatelessWidget
  // it will be called whenever the widget needs to be rendered, so almost every time we open the app
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold is a layout structure for the material design
      // it provides a framework for implementing the basic visual layout structure of the app
      // like app bar, body, floating action button, drawer, etc.
      // in this case we are using appBar and body, but note that all these comes under Scaffold widget only
      appBar: AppBar(
        // AppBar is a material design app bar
        // it is a horizontal bar typically shown at the top of an app using the app's primary color
        // it usually contains the title of the screen and actions like buttons, menus, etc.
        title: Text('Home'),

        // title is the main title of the app bar
        // here we are using a Text widget to display the title
        actions: [
          // actions is a list of widgets that are displayed in the app bar
          // typically used for actions like search, settings, etc.
          IconButton(
            // IconButton is a material design icon button
            // it is a button that displays an icon and reacts to touches
            // here we are using an IconButton to show a settings icon in the app bar
            // similarly we can add more IconButton widgets for other actions
            // like search, notifications, etc.
            // but they must be wrapped inside the actions list, as shown above.
            // note that
            // each IconButton can have its own icon, tooltip, and onPressed callback
            // we can add multiple IconButton widgets inside the actions list,
            // but the icon, tooltip, and onPressed must be defined for each IconButton
            // like they can't be inside the same IconButton widget
            // because each IconButton represents a single button with its own properties
            icon: Icon(
              Icons.settings,
            ), // icon is the icon to display in the button
            tooltip:
                'Settings', // tooltip is the text that is displayed when the user long-presses the button
            // it is useful for accessibility and providing additional information about the button
            onPressed: () {
              // onPressed is a callback function that is called when the button is pressed
              // here we can define what happens when the button is pressed
              // for example, navigate to settings page, show a dialog, etc.
              if (kDebugMode) {
                print('Settings button pressed');
              } // for now, we are just printing a message to the console
            },
          ),
        ],
      ),
      body: Center(
        // body is the main content of the screen
        // here we are using a Center widget to center the content in the body
        child: Text(
          // child is the widget that is displayed in the body
          // here we are using a Text widget to display some text
          'Hello India!',
          style: TextStyle(
            fontSize: 24,
          ), // style is used to define the text style
          // here we are setting the font size to 24
        ),
      ),
    );
  }
}
