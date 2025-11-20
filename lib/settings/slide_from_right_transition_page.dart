import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A page with a slide-from-right transition.
class SlideFromRightTransitionPage extends CustomTransitionPage<void> {
  SlideFromRightTransitionPage({
    super.key,
    required super.child,
  }) : super(
         transitionDuration: const Duration(milliseconds: 200),
         reverseTransitionDuration: const Duration(milliseconds: 200),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return SlideTransition(
             position: animation.drive(
               Tween<Offset>(
                 begin: const Offset(1, 0),
                 end: Offset.zero,
               ).chain(CurveTween(curve: Curves.easeIn)),
             ),
             child: child,
           );
         },
       );
}
