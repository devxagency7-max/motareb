import 'dart:convert';
import 'package:flutter/material.dart';

class ImageHelper {
  static ImageProvider buildImage(String imageSource) {
    try {
      if (imageSource.startsWith('http') || imageSource.startsWith('assets')) {
        return NetworkImage(imageSource);
      } else {
        // Assume Base64
        return MemoryImage(base64Decode(imageSource));
      }
    } catch (e) {
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  static Widget buildImageWidget(
    String imageSource, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageSource.startsWith('assets')) {
      return Image.asset(
        imageSource,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(Icons.error),
      );
    }
    if (imageSource.startsWith('http')) {
      return Image.network(
        imageSource,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(Icons.error),
      );
    }
    try {
      return Image.memory(
        base64Decode(imageSource),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(Icons.error),
      );
    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }
}
