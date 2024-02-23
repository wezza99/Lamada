import 'package:flutter/material.dart';
import 'package:flutter_restaurant/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class ColorResources {
  static Color getSearchBg(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? Colors.black
        : Colors.white;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? Colors.black
        : Colors.white;
  }

  static Color getHintColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? Colors.black54
        : Colors.grey;
  }

  static Color getGreyBunkerColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? Colors.black87
        : Colors.grey.shade700;
  }

  static Color getCartTitleColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xFF61699b) // Adjust to your preference
        : const Color.fromARGB(255, 126, 3, 3); // Deep Red color for light theme
  }

  static Color getProfileMenuHeaderColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? footerCol0r.withOpacity(0.5)
        : footerCol0r.withOpacity(0.8); // Adjust to your preference
  }

  static Color getFooterColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xFF494949) // Adjust to your preference
        :const Color.fromARGB(255, 130, 4, 4); // Deep Red color for light theme
  }

  static const Color colorNero = Color(0xFF1F1F1F);
  static const Color searchBg = Colors.white;
  static const Color borderColor = Colors.grey;
  static const Color footerCol0r = Color.fromARGB(255, 126, 2, 2); // Deep Red color
  static const Color cardShadowColor = Colors.grey;
}
