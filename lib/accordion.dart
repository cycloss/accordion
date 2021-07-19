/// Copyright 2021 Christian Gotschim.
///
/// Published under the new BSD license.
///
/// Simple to use accordion widget with lots of preset properties.
///
/// Use the `maxOpenSections` property to automatically close sections
/// when opening a new section. This is especially helpful if you
/// always want your list to look clean -- just set this parameter
/// to 1 and whenever you open a new section the previous one closes.
///
/// `scrollIntoView` paramter can be set to `fast`, `slow`, or `none`.
/// This parameter will only take affect if there are enough items in
/// the list so scrolling is feasible.
///
/// Many parameters can be set globally on `Accordion` as well as individually
/// on each `AccordionSection` (see list below).
///
/// The header consists of the left and right icons (right icon is preset
/// to arrow down). Both can be set globally and individually. The
/// headerText parameter is required and needs to be set for each
/// `AccordionSection`.
///
/// The content area basically provides the container in which you drop
/// whatever you want to display when `AccordionSection` opens. Background
/// and borders can be set globally or individually per section.
///
/// ```dart
///	Accordion(
///		maxOpenSections: 1,
///		headerTextStyle:
///			TextStyle(color: Colors.white, fontSize: 17),
///		leftIcon: Icon(Icons.audiotrack, color: Colors.white),
///		children: [
///			AccordionSection(
///				isOpen: true,
///				headerText: 'Introduction',
///				content: Icon(Icons.airplanemode_active, size: 200),
///			),
///			AccordionSection(
///				isOpen: true,
///				headerText: 'About Us',
///				content: Icon(Icons.airline_seat_flat, size: 120),
///			),
///			AccordionSection(
///				isOpen: true,
///				headerText: 'Company Info',
///				content: Icon(Icons.airplay, size: 70, color: Colors.green[200]),
///			),
///		],
///	)
/// ```
library accordion;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

enum ScrollIntoViewOfItems { none, slow, fast }

final springFast = SpringDescription(mass: 1, stiffness: 200, damping: 30);

mixin CommonParams {
  late final Color? _headerBackgroundColor;
  late final double? _headerBorderRadius;
  late final TextAlign? _headerTextAlign;
  late final TextStyle? _headerTextStyle;
  late final EdgeInsets? _headerPadding;
  late final Widget? _leftIcon, _rightIcon;
  late final bool? _flipRightIconIfOpen;
  late final Color? _contentBackgroundColor;
  late final Color? _contentBorderColor;
  late final double? _contentBorderWidth;
  late final double? _contentBorderRadius;
  late final double? _contentHorizontalPadding;
  late final double? _contentVerticalPadding;
  late final double? _paddingBetweenOpenSections;
  late final double? _paddingBetweenClosedSections;
  late final ScrollIntoViewOfItems? _scrollIntoViewOfItems;
}

class ListController extends GetxController {
  final controller = AutoScrollController(axis: Axis.vertical);
  final openSections = <UniqueKey>[].obs;

  /// Maximum number of open sections at any given time.
  /// Opening a new section will close the "oldest" open section
  int maxOpenSections = 1;

  /// The delay in milliseconds (when the entire accordion loads)
  /// before the individual sections open one after another.
  /// Helpful if you go to a new page in your app and then (after
  /// the delay) have a nice opening sequence.
  int initialOpeningSequenceDelay = 250;

  void updateSections(UniqueKey key) {
    openSections.contains(key)
        ? openSections.remove(key)
        : openSections.add(key);

    if (openSections.length > maxOpenSections)
      openSections.removeRange(0, openSections.length - maxOpenSections);
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}

/// The container list for all accordion sections. Usage:
/// ```dart
///	Accordion(
///		maxOpenSections: 1,
///		headerTextStyle:
///			TextStyle(color: Colors.white, fontSize: 17),
///		leftIcon: Icon(Icons.audiotrack, color: Colors.white),
///		children: [
///			AccordionSection(
///				isOpen: true,
///				headerText: 'Introduction',
///				content: Icon(Icons.airplanemode_active, size: 200),
///			),
///			AccordionSection(
///				isOpen: true,
///				headerText: 'About Us',
///				content: Icon(Icons.airline_seat_flat, size: 120),
///			),
///			AccordionSection(
///				isOpen: true,
///				headerText: 'Company Info',
///				content: Icon(Icons.airplay, size: 70, color: Colors.green[200]),
///			),
///		],
///	)
/// ```
class Accordion extends StatelessWidget with CommonParams {
  final List<AccordionSection> children;
  final double paddingListHorizontal;
  final double paddingListTop;
  final double paddingListBottom;
  final ListController listCtrl = ListController();
  Accordion({
    required this.children,
    int? maxOpenSections,
    int? initialOpeningSequenceDelay,
    Color? headerBackgroundColor,
    double? headerBorderRadius,
    TextAlign? headerTextAlign,
    TextStyle? headerTextStyle,
    Widget? leftIcon,
    Widget? rightIcon,
    bool? flipRightIconIfOpen,
    Color? contentBackgroundColor,
    Color? contentBorderColor,
    double? contentBorderWidth,
    double? contentBorderRadius,
    double? contentHorizontalPadding,
    double? contentVerticalPadding,
    this.paddingListTop = 20.0,
    this.paddingListBottom = 40.0,
    this.paddingListHorizontal = 10.0,
    EdgeInsets? headerPadding,
    double? paddingBetweenOpenSections,
    double? paddingBetweenClosedSections,
    ScrollIntoViewOfItems? scrollIntoViewOfItems,
  }) {
    listCtrl.initialOpeningSequenceDelay = initialOpeningSequenceDelay ?? 0;
    this._headerBackgroundColor = headerBackgroundColor;
    this._headerBorderRadius = headerBorderRadius ?? 30;
    this._headerTextAlign = headerTextAlign ?? TextAlign.left;
    this._headerTextStyle = headerTextStyle;
    this._leftIcon = leftIcon;
    this._rightIcon = rightIcon;
    this._flipRightIconIfOpen = flipRightIconIfOpen;
    this._contentBackgroundColor = contentBackgroundColor;
    this._contentBorderColor = contentBorderColor;
    this._contentBorderWidth = contentBorderWidth;
    this._contentBorderRadius = contentBorderRadius ?? 20;
    this._contentHorizontalPadding = contentHorizontalPadding;
    this._contentVerticalPadding = contentVerticalPadding;
    this._headerPadding =
        headerPadding ?? EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    this._paddingBetweenOpenSections = paddingBetweenOpenSections ?? 10;
    this._paddingBetweenClosedSections = paddingBetweenClosedSections ?? 3;
    this._scrollIntoViewOfItems = scrollIntoViewOfItems;

    int count = 0;
    listCtrl.maxOpenSections = maxOpenSections ?? 1;
    children.forEach((child) {
      if (child._sectionCtrl.isSectionOpen.value == true) {
        count++;

        if (count > listCtrl.maxOpenSections)
          child._sectionCtrl.isSectionOpen.value = false;
      }
    });
  }

  build(context) {
    int index = 0;

    return Scrollbar(
      child: ListenableProvider<ListController>.value(
          value: listCtrl,
          builder: (context, _) {
            return ListView(
              shrinkWrap: true,
              controller: listCtrl.controller,
              padding: EdgeInsets.only(
                top: paddingListTop,
                bottom: paddingListBottom,
                right: paddingListHorizontal,
                left: paddingListHorizontal,
              ),
              cacheExtent: 100000,
              children: children.map(
                (child) {
                  final key = UniqueKey();

                  if (child._sectionCtrl.isSectionOpen.value)
                    listCtrl.openSections.add(key);

                  return AutoScrollTag(
                    key: ValueKey(key),
                    controller: listCtrl.controller,
                    index: index,
                    child: AccordionSection(
                      key: key,
                      index: index++,
                      isOpen: child._sectionCtrl.isSectionOpen.value,
                      scrollIntoViewOfItems: _scrollIntoViewOfItems,
                      headerBackgroundColor: child._headerBackgroundColor ??
                          _headerBackgroundColor,
                      headerBorderRadius:
                          child._headerBorderRadius ?? _headerBorderRadius,
                      headerText: child.headerText,
                      headerTextStyle:
                          child._headerTextStyle ?? _headerTextStyle,
                      headerTextAlign:
                          child._headerTextAlign ?? _headerTextAlign,
                      headerPadding: child._headerPadding ?? _headerPadding,
                      leftIcon: child._leftIcon ?? _leftIcon,
                      rightIcon: child._rightIcon ??
                          _rightIcon ??
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white60,
                            size: 20,
                          ),
                      flipRightIconIfOpen:
                          child._flipRightIconIfOpen ?? _flipRightIconIfOpen,
                      paddingBetweenClosedSections:
                          child._paddingBetweenClosedSections ??
                              _paddingBetweenClosedSections,
                      paddingBetweenOpenSections:
                          child._paddingBetweenOpenSections ??
                              _paddingBetweenOpenSections,
                      content: child.content,
                      contentBackgroundColor: child._contentBackgroundColor ??
                          _contentBackgroundColor,
                      contentBorderColor:
                          child._contentBorderColor ?? _contentBorderColor,
                      contentBorderWidth:
                          child._contentBorderWidth ?? _contentBorderWidth,
                      contentBorderRadius:
                          child._contentBorderRadius ?? _contentBorderRadius,
                      contentHorizontalPadding:
                          child._contentHorizontalPadding ??
                              _contentHorizontalPadding,
                      contentVerticalPadding: child._contentVerticalPadding ??
                          _contentVerticalPadding,
                    ),
                  );
                },
              ).toList(),
            );
          }),
    );
  }
}

class SectionController extends GetxController
    with SingleGetTickerProviderMixin {
  late final controller = AnimationController(vsync: this);
  final isSectionOpen = false.obs;
  bool _firstRun = true;

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}

/// `AccordionSection` is one section within the `Accordion` widget.
/// Usage:
/// ```dart
///	Accordion(
///		maxOpenSections: 1,
///		headerTextStyle:
///			TextStyle(color: Colors.white, fontSize: 17),
///		leftIcon: Icon(Icons.audiotrack, color: Colors.white),
///		children: [
///			AccordionSection(
///				isOpen: true,
///				headerText: 'Introduction',
///				content: Icon(Icons.airplanemode_active, size: 200),
///			),
///			AccordionSection(
///				isOpen: true,
///				headerText: 'About Us',
///				content: Icon(Icons.airline_seat_flat, size: 120),
///			),
///			AccordionSection(
///				isOpen: true,
///				headerText: 'Company Info',
///				content: Icon(Icons.airplay, size: 70, color: Colors.green[200]),
///			),
///		],
///	)
/// ```
class AccordionSection extends StatelessWidget with CommonParams {
  late final SectionController _sectionCtrl;
  late final UniqueKey? key;
  late final int index;

  /// The text to be displayed in the header
  final String headerText;

  /// The widget to be displayed as the content of the section when open
  final Widget content;

  AccordionSection({
    this.key,
    this.index = 0,
    bool isOpen = false,
    required this.headerText,
    required this.content,
    Color? headerBackgroundColor,
    double? headerBorderRadius,
    TextAlign? headerTextAlign,
    TextStyle? headerTextStyle,
    EdgeInsets? headerPadding,
    Widget? leftIcon,
    Widget? rightIcon,
    bool? flipRightIconIfOpen = true,
    Color? contentBackgroundColor,
    Color? contentBorderColor,
    double? contentBorderWidth,
    double? contentBorderRadius,
    double? contentHorizontalPadding,
    double? contentVerticalPadding,
    double? paddingBetweenOpenSections,
    double? paddingBetweenClosedSections,
    ScrollIntoViewOfItems? scrollIntoViewOfItems,
  }) {
    _sectionCtrl = SectionController();
    _sectionCtrl.isSectionOpen.value = isOpen;

    this._headerBackgroundColor = headerBackgroundColor;
    this._headerBorderRadius = headerBorderRadius;
    this._headerTextAlign = headerTextAlign;
    this._headerTextStyle = headerTextStyle;
    this._headerPadding = headerPadding;
    this._leftIcon = leftIcon;
    this._rightIcon = rightIcon;
    this._flipRightIconIfOpen = flipRightIconIfOpen ?? true;
    this._contentBackgroundColor = contentBackgroundColor;
    this._contentBorderColor = contentBorderColor;
    this._contentBorderWidth = contentBorderWidth;
    this._contentBorderRadius = contentBorderRadius;
    this._contentHorizontalPadding = contentHorizontalPadding ?? 10;
    this._contentVerticalPadding = contentVerticalPadding ?? 10;
    this._paddingBetweenOpenSections = paddingBetweenOpenSections;
    this._paddingBetweenClosedSections = paddingBetweenClosedSections;
    this._scrollIntoViewOfItems =
        scrollIntoViewOfItems ?? ScrollIntoViewOfItems.fast;
  }

  int _flipQuarterTurns(bool isOpen) =>
      _flipRightIconIfOpen == true ? (isOpen ? 2 : 0) : 0;

  bool _isOpen(ListController listCtrl) {
    final open = listCtrl.openSections.contains(key);
    Timer(
      _sectionCtrl._firstRun
          ? (listCtrl.initialOpeningSequenceDelay + min(index * 200, 1000))
              .milliseconds
          : 0.seconds,
      () {
        _sectionCtrl.controller
            .fling(velocity: open ? 1 : -1, springDescription: springFast);
        _sectionCtrl._firstRun = false;
      },
    );
    return open;
  }

  build(context) {
    return Obx(() {
      var listCtrl = Provider.of<ListController>(context);
      var isOpen = _isOpen(listCtrl);
      return Column(
        key: key,
        children: [
          InkWell(
            onTap: () {
              listCtrl.updateSections(key!);

              if (isOpen &&
                  _scrollIntoViewOfItems != ScrollIntoViewOfItems.none)
                Timer(
                  0.25.seconds,
                  () {
                    listCtrl.controller.cancelAllHighlights();
                    listCtrl.controller.scrollToIndex(index,
                        preferPosition: AutoScrollPosition.middle,
                        duration: (_scrollIntoViewOfItems ==
                                    ScrollIntoViewOfItems.fast
                                ? .5
                                : 1)
                            .seconds);
                  },
                );
            },
            child: AnimatedContainer(
              duration: 0.75.seconds,
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: _headerPadding,
              decoration: BoxDecoration(
                color: _headerBackgroundColor ?? Theme.of(context).primaryColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_headerBorderRadius!),
                  bottom: Radius.circular(isOpen ? 0 : _headerBorderRadius!),
                ),
              ),
              child: Row(
                children: [
                  if (_leftIcon != null) _leftIcon!,
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        headerText,
                        textAlign: _headerTextAlign,
                        style: _headerTextStyle ??
                            TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_rightIcon != null)
                    RotatedBox(
                        quarterTurns: _flipQuarterTurns(isOpen),
                        child: _rightIcon!),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                bottom: isOpen
                    ? _paddingBetweenOpenSections!
                    : _paddingBetweenClosedSections!),
            child: SizeTransition(
              sizeFactor: _sectionCtrl.controller,
              child: ScaleTransition(
                scale: _sectionCtrl.controller,
                child: Center(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _contentBorderColor ?? Colors.white,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(_contentBorderRadius!)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        _contentBorderWidth ?? 0,
                        0,
                        _contentBorderWidth ?? 0,
                        _contentBorderWidth ?? 0,
                      ),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(
                                    _contentBorderRadius! / 1.02))),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              color: _contentBackgroundColor,
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(
                                      _contentBorderRadius! / 1.02))),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _contentHorizontalPadding!,
                              vertical: _contentVerticalPadding!,
                            ),
                            child: Center(
                              child: content,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
