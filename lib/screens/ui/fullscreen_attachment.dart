import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_zoom/widget_zoom.dart';
import 'package:mime/mime.dart';  // For checking the file MIME type

import '../../providers/attachment_provider.dart';

class FAttachScreen extends StatefulWidget {
  final String attachmentUrl;
  final String attachmentName;

  const FAttachScreen({super.key, required this.attachmentUrl, required this.attachmentName});

  @override
  _FAttachScreenState createState() => _FAttachScreenState();
}

class _FAttachScreenState extends State<FAttachScreen> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attachmentName),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: WidgetZoom(
            heroAnimationTag: 'tag',
            zoomWidget: FutureBuilder<Image?>(
              future: _fetchAndValidateImage(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "not_valid_image".tr(),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return snapshot.data!;
                } else {
                  return Center(
                    child: Text(
                      'not_valid_image'.tr(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // Function to fetch and validate image data
  Future<Image?> _fetchAndValidateImage(BuildContext context) async {
    try {
      final image = await Provider.of<AttachmentProvider>(context, listen: false)
          .fetchAttachmentImage(
        myUrl: widget.attachmentUrl,
        context: context,
      );

      if (image != null) {
        // Validate if the file is a valid image by checking its MIME type
        final mimeType = lookupMimeType(widget.attachmentUrl);
        if (mimeType != null && mimeType.startsWith('image/')) {
          return image;
        } else {
          throw Exception('not_valid_image'.tr());
        }
      }
      return null;
    } catch (e) {
      throw Exception('${'error'.tr()}: $e');
    }
  }
}