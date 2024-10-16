import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planka_app/providers/list_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/planka_fCard.dart';
import 'auth_provider.dart';

class CardProvider with ChangeNotifier {
  PlankaFullCard? _card;
  final AuthProvider authProvider;

  CardProvider(this.authProvider);

  PlankaFullCard? get card => _card;

  Future<PlankaFullCard> fetchCard({required String cardId, required BuildContext context}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final PlankaFullCard plankaFullCardCard = PlankaFullCard.fromJson(responseData);

        _card = plankaFullCardCard;

        notifyListeners();

        return plankaFullCardCard;
      } else {
        debugPrint('Failed to load fullCard: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to load fullCard: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error fetching fullCard: $error');
      throw Exception('Failed to load fullCard');
    }
  }

  Future<void> updateCardTitle({required BuildContext context, required String cardId, required String newCardTitle}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'name': newCardTitle}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to update card name: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to update card name: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update card name');
    }
  }

  Future<void> updateStopwatch({required BuildContext context, required String cardId, required int stopwatchTotal, String? stopwatchStartedAt,}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      // Construct the request body
      final body = {
        'stopwatch': {
          'total': stopwatchTotal,
          'startedAt': stopwatchStartedAt,
        },
      };

      // Make the PATCH request
      final response = await http.patch(
        url,
        body: json.encode(body),
        headers: {'Authorization': 'Bearer ${authProvider.token}', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to update card: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to update card: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update card');
    }
  }

  Future<void> deleteStopwatch({required BuildContext context, required String cardId,}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      // Construct the request body
      final body = {
        'stopwatch': null
      };

      // Make the PATCH request
      final response = await http.patch(
        url,
        body: json.encode(body),
        headers: {'Authorization': 'Bearer ${authProvider.token}', 'Content-Type': 'application/json'},
      );

      debugPrint(response.toString());

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to update card: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to update card: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update card');
    }
  }

  Future<void> updateCardDueDate({required String cardId, required String newDueDate}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'dueDate': newDueDate}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to update card name: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to update card name: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update card name');
    }
  }

  Future<void> addCardLabel({required BuildContext context, required String cardId, required String labelId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/labels');

    try {
      // Fetch the current card data
      final response = await http.post(
        url,
        body: json.encode({
          'labelId': labelId,
          'cardId': cardId
        }),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to fetch card data: ${response.statusCode}');
        throw Exception('Failed to fetch card data: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update labels');
    }
  }

  Future<void> addCardMember({required BuildContext context, required String cardId, required String userId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/memberships');

    try {
      // Fetch the current card data
      final response = await http.post(
        url,
        body: json.encode({
          'userId': userId,
          'cardId': cardId
        }),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to add card user: ${response.statusCode}');
        throw Exception('Failed to add card user: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to add card user');
    }
  }

  Future<void> removeCardMember({required BuildContext context, required String cardId, required String userId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/memberships');

    try {
      // Fetch the current card data
      final response = await http.delete(
        url,
        body: json.encode({
          'userId': userId,
          'cardId': cardId
        }),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to delete card user: ${response.statusCode}');
        throw Exception('Failed to delete card user: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to delete card user');
    }
  }

  Future<void> removeCardLabel({required BuildContext context, required String cardId, required String labelId,}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/labels/$labelId');

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
        debugPrint('Failed to fetch card data: ${response.statusCode}');
        throw Exception('Failed to fetch card data: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update labels');
    }
  }

  Future<void> deleteCard({required BuildContext context, required String cardId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      await Provider.of<ListProvider>(context, listen: false).fetchLists(boardId: card!.boardId.toString(), context: context);

      notifyListeners();
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to delete card');
    }
  }

  Future<void> updateCardDescription({required BuildContext context, required String cardId, required String newCardDesc}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'description': newCardDesc}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to update card name: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to card name: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to card name');
    }
  }

  Future<void> updateCardCoverAttachId({required BuildContext context, required String cardId, required String? newCardCoverAttachId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'coverAttachmentId': newCardCoverAttachId}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      debugPrint("ID::" + newCardCoverAttachId.toString());

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to update card name: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to card name: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to card name');
    }
  }

  Future<void> addTask({required BuildContext context, required String cardId, required String taskText, required String newPos}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId/tasks/?position=$newPos');

    try {
      final response = await http.post(
        url,
        body: json.encode({'name': taskText}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to add task: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to add task: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to add task');
    }
  }

  Future<void> removeTask({required BuildContext context, required String taskId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/tasks/$taskId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to remove task: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to remove task: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to remove task');
    }
  }

  Future<void> toggleTaskCompletion({required BuildContext context, required String taskId, required bool isCompleted}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/tasks/$taskId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'isCompleted': isCompleted}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to toggle task completion: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to toggle task completion: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to toggle task completion');
    }
  }

  Future<void> reorderTask({required BuildContext context, required String taskId, required int newPosition,}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/tasks/$taskId');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'position': newPosition}),
      );

      if (response.statusCode == 200) {
        // Task reordered successfully
        print('Task reordered successfully.');
      } else {
        // Handle error
        print('Failed to reorder task: ${response.statusCode}');
        throw Exception('Failed to reorder task: ${response.reasonPhrase}');
      }
    } catch (error) {
      // Handle error
      print('Error reordering task: $error');
      throw Exception('Failed to reorder task.');
    }
  }

  Future<void> renameTask({required BuildContext context, required String taskId, required String newTaskName,}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/tasks/$taskId');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'name': newTaskName}),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Task renamed successfully
        notifyListeners();
      } else {
        // Handle error
        print('Failed to rename task: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to rename task: ${response.reasonPhrase}');
      }
    } catch (error) {
      // Handle error
      print('Error renaming task: $error');
      throw Exception('Failed to rename task');
    }
  }
}
