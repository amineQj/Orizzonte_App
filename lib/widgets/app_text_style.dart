import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide Poppins text style.
///
/// Production always uses Poppins. When runtime font fetching is disabled
/// (offline widget/golden tests), it degrades to the framework default font so
/// screens remain renderable without network access.
TextStyle appPop({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  if (!GoogleFonts.config.allowRuntimeFetching) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
