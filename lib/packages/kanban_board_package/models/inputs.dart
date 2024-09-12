import 'package:flutter/material.dart';

class BoardListsData {
  final String? title;
  Widget? header;
  Color? headerBackgroundColor;
  Color? footerBackgroundColor;
  Widget? footer;
  final List<Widget> items;
  Color? backgroundColor;
  double width;
  BoardListsData({
    this.title,
    this.header,
    this.footer,
    required this.items,
    this.footerBackgroundColor = const Color.fromRGBO(247, 248, 252, 1),
    this.headerBackgroundColor = const Color.fromARGB(255, 247, 248, 252),
    this.backgroundColor = const Color.fromARGB(
      255,
      247,
      248,
      252,
    ),
    this.width = 300,
  }) {
    footer = footer ?? const SizedBox.shrink();
    header = header ?? const SizedBox.shrink();
  }
}

class ScrollConfig {
  double offset;
  Duration duration;
  Curve curve;

  ScrollConfig({
    required this.offset,
    required this.duration,
    required this.curve,
  });
}
