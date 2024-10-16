
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planka_app/models/card_models/planka_attachment.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'dart:typed_data';

import 'auth_provider.dart';

class AttachmentProvider with ChangeNotifier {
  PlankaAttachment? _attachment;
  Uint8List? _imageData;  // Store the image data here

  final AuthProvider authProvider;

  AttachmentProvider(this.authProvider);

  PlankaAttachment? get attachment => _attachment;
  Uint8List? get imageData => _imageData;  // Getter for image data

  Future<void> downloadFile(String url, String fileName, BuildContext context) async {
    try {
      final myUrl = Uri.parse(url);

      final response = await http.get(
        myUrl,
        headers: {
          'Cookie': 'accessToken=${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        // Get temporary directory
        final dir = await getTemporaryDirectory();

        // Create an image name
        var filename = '${dir.path}/$fileName';

        // Save to filesystem
        final file = File(filename);
        await file.writeAsBytes(response.bodyBytes);

        // Ask the user to save it
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);


        if(finalPath != null){
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(
              message: "downloaded_file".tr()
            ),
          );
        }
      } else {
        debugPrint('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
  }

  Future<Image?> fetchAttachmentImage({
    required String myUrl,
    required BuildContext context,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final url = Uri.parse(myUrl);
      final response = await http.get(
        url,
        headers: {
          'Cookie': 'accessToken=${authProvider.token}',
      },
      );

      if (response.statusCode == 200) {
        // Assuming the response body contains the image bytes
        final imageBytes = response.bodyBytes;

        // Create an Image widget from the bytes
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
        );
      } else {
        debugPrint('Failed to load attachment: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to load attachment: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error fetching attachment: $error');
      throw Exception('Failed to load attachment');
    }
  }

  Future<void> deleteAttachment({required BuildContext context, required String attachmentId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/attachments/$attachmentId');

    try {
      // Fetch the current card data
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to delete attachment: ${response.statusCode}');
        throw Exception('Failed to delete attachment: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to delete attachment');
    }
  }

  Future<void> createAttachment({
    required BuildContext context,
    required String cardId,
    required File file,
  }) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/attachments');

    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(
        message: "added_attachment".tr(),
      ),
    );

    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer ${authProvider.token}',
        'Cookie': 'accessToken=${authProvider.token}',
      });

      // Attach the file as a multipart file
      var mimeType = lookupMimeType(file.path); // Optional: infer mime type based on file extension
      var multipartFile = await http.MultipartFile.fromPath(
        'file', // This should be the field name expected by your API
        file.path,
        contentType: MediaType.parse(mimeType ?? 'application/octet-stream'), // Optional: provide a content type
      );

      // Add the multipart file to the request
      request.files.add(multipartFile);

      // Send the request
      var response = await request.send();

      // Handle the response
      if (response.statusCode == 200) {
        var responseBody = await http.Response.fromStream(response);
        debugPrint('Attachment created successfully: ${responseBody.body}');

        notifyListeners();
      } else {
        debugPrint('Failed to create attachment: ${response.statusCode}');
        throw Exception('Failed to create attachment: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error creating attachment: $error');
      throw Exception('Failed to create attachment');
    }
  }

  Future<void> renameAttachment({required BuildContext context, required String cardId, required String newAttachName, required String attachId,}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/attachments/$attachId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'name': newAttachName}),
        headers: {'Authorization': 'Bearer ${authProvider.token}',},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to update attachment name: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to update attachment name: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update attachment name');
    }
  }

  Image? getAttachmentImage() {
    if (_imageData != null) {
      return Image.memory(_imageData!);  // Return the Image widget from Uint8List
    }
    return null;  // Return null if no image data is available
  }
}
