import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color star_color;

  StarRating({required this.rating, required this.size,required this.star_color });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        if (index < rating) {
          return index==1 ?Column(
            children: [Icon(
              Icons.star,
              color: star_color,
              size: size,
            ),
            SizedBox(height: 12,)],) :Icon(
            Icons.star,
            color: star_color,
            size: size,
          );
        } else {
          return index==1?Column(children: [Icon(
            Icons.star_border,
            color: star_color,
            size: size,
          ),SizedBox(height: 1,)],):
          Icon(
            Icons.star_border,
            color: star_color,
            size: size,
          );
        }
      }),
    );
  }
}