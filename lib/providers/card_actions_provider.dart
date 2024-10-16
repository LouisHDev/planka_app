import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/planka_card_actions.dart';
import 'auth_provider.dart';

class CardActionsProvider with ChangeNotifier {
  List<PlankaCardAction> _cardActions = [];
  final AuthProvider authProvider;

  CardActionsProvider(this.authProvider);

  List<PlankaCardAction> get cardActions => _cardActions;

  Future<void> fetchCardComment(String cardId) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/actions');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final actionsJson = responseData['items'] as List<dynamic>;
        final includedData = responseData['included'];

        _cardActions = actionsJson
            .map((actionJson) => PlankaCardAction.fromJson(actionJson, includedData))
            .toList();

        notifyListeners();
      } else {
        debugPrint('Failed to load card actions: ${response.statusCode}');
        throw Exception('Failed to load card actions');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load card actions');
    }
  }

  Future<void> deleteComment(String commentId) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/comment-actions/$commentId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to load card actions: ${response.statusCode}');
        throw Exception('Failed to load card actions');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load card actions');
    }
  }

  Future<void> createComment(String cardId, String newCommentBody) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/comment-actions');

    try {
      final response = await http.post(
        url,
        body: json.encode({'text': newCommentBody}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        fetchCardComment(cardId);
        notifyListeners();
      } else {
        debugPrint('Failed to load card actions: ${response.statusCode}');
        throw Exception('Failed to load card actions');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load card actions');
    }
  }

  Future<void> updateComment(String commentId, String newCommentBody) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/comment-actions/$commentId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'text': newCommentBody}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to load card actions: ${response.statusCode}');
        throw Exception('Failed to load card actions');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load card actions');
    }
  }
}