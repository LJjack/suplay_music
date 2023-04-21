/// FileName drop_down_menu
///
/// @Author liujunjie
/// @Date 2022/5/6 15:24
///
/// @Description TODO
import 'package:flutter/material.dart';

class DropDownMenuRouter extends PopupRoute {
  DropDownMenuRouter({
    required this.position,
    required this.menuHeight,
    required this.menuWidth,
    required this.itemView,
  });

  final Rect position;
  final double menuHeight;
  final double menuWidth;
  final Widget itemView;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return CustomSingleChildLayout(
      delegate: DropDownMenuRouteLayout(
        position: position,
        menuHeight: menuHeight,
        menuWidth: menuWidth,
      ),
      child: itemView,
    );
  }
}

class DropDownMenuRouteLayout extends SingleChildLayoutDelegate {
  DropDownMenuRouteLayout({
    required this.position,
    required this.menuHeight,
    required this.menuWidth,
  });

  final Rect position;
  final double menuHeight;
  final double menuWidth;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(Size(menuWidth, menuHeight));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(position.left, position.top - menuHeight);
  }

  @override
  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate) {
    return true;
  }
}
