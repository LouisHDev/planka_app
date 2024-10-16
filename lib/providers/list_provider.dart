import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/card_models/planka_attachment.dart';
import '../models/card_models/planka_card_membership.dart';
import '../models/card_models/planka_label.dart';
import '../models/card_models/planka_task.dart';
import '../models/planka_list.dart';
import '../models/planka_card.dart';
import '../models/planka_user.dart';
import 'auth_provider.dart';

class ListProvider with ChangeNotifier {
  List<PlankaList> _lists = [];
  final AuthProvider authProvider;

  ListProvider(this.authProvider);

  List<PlankaList> get lists => _lists;

  Future<void> fetchLists({required String boardId, required BuildContext context}) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/boards/$boardId');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Step 0: Extract tasks and create a map
        final List<PlankaTask> allTasks = (responseData['included']['tasks'] as List)
            .map((json) => PlankaTask.fromJson(json))
            .toList();

        final Map<String, List<PlankaTask>> taskMap = {};
        for (var task in allTasks) {
          if (!taskMap.containsKey(task.cardId)) {
            taskMap[task.cardId] = [];
          }
          taskMap[task.cardId]!.add(task);
        }

        // Step 1: Extract labels and create a map
        final List<PlankaLabel> allLabels = (responseData['included']['labels'] as List)
            .map((json) => PlankaLabel.fromJson(json))
            .toList();

        final Map<String, List<PlankaLabel>> labelMap = {};
        for (var label in allLabels) {
          if (!labelMap.containsKey(label.boardId)) {
            labelMap[label.boardId] = [];
          }
          labelMap[label.boardId]!.add(label);
        }

        // Step 2: Extract card memberships and create a map
        final List<PlankaCardMembership> allCardMemberships = (responseData['included']['cardMemberships'] as List)
            .map((json) => PlankaCardMembership.fromJson(json))
            .toList();

        final Map<String, List<PlankaCardMembership>> cardMembershipMap = {};
        for (var membership in allCardMemberships) {
          if (!cardMembershipMap.containsKey(membership.cardId)) {
            cardMembershipMap[membership.cardId] = [];
          }
          cardMembershipMap[membership.cardId]!.add(membership);
        }

        // Step 3: Extract card attachments and create a map
        final List<PlankaAttachment> allCardAttachments = (responseData['included']['attachments'] as List)
            .map((json) => PlankaAttachment.fromJson(json))
            .toList();

        final Map<String, List<PlankaAttachment>> cardAttachmentMap = {};
        for (var attachment in allCardAttachments) {
          if (!cardAttachmentMap.containsKey(attachment.cardId)) {
            cardAttachmentMap[attachment.cardId] = [];
          }
          cardAttachmentMap[attachment.cardId]!.add(attachment);
        }

        // Step 4: Extract card users and create a map
        final List<PlankaUser> allCardUsers = (responseData['included']['users'] as List)
            .map((json) => PlankaUser.fromJson(json))
            .toList();

        final Map<String, PlankaUser> cardUsersMap = {};
        for (var user in allCardUsers) {
          cardUsersMap[user.id] = user;
        }

        // Correctly map card users
        final List<PlankaCard> cards = (responseData['included']['cards'] as List).map((json) {
          final String cardBoardId = json['boardId'];
          final List<PlankaTask> cardTasks = taskMap[json['id']] ?? [];
          final List<PlankaLabel> cardLabels = labelMap[cardBoardId] ?? [];
          final List<PlankaCardMembership> cardMemberships = cardMembershipMap[json['id']] ?? [];
          final List<PlankaAttachment> cardAttachments = cardAttachmentMap[json['id']] ?? [];
          final List<PlankaUser> cardUsers = cardMemberships.map((membership) => cardUsersMap[membership.userId]).whereType<PlankaUser>().toList();

          // Extract stopwatch information
          final stopwatchTotal = json['stopwatch']?['total'];
          final stopwatchStartedAt = json['stopwatch']?['startedAt'] != null ? DateTime.parse(json['stopwatch']['startedAt']) : null;

          // Create and return the PlankaCard object with associated (labels), memberships, attachments, and stopwatch
          return PlankaCard(
            id: json['id'],
            boardId: json['boardId'],
            name: json['name'],
            listId: json['listId'],
            position: json['position'],
            description: json['description'],
            dueDate: json['dueDate'],
            isSubscribed: json['isSubscribed'],
            coverAttachmentId: json['coverAttachmentId'],
            creatorUserId: json['creatorUserId'],
            tasks: cardTasks,
            labels: cardLabels,
            cardMemberships: cardMemberships,
            cardAttachment: cardAttachments,
            cardUsers: cardUsers,
            stopwatchTotal: stopwatchTotal,
            stopwatchStartedAt: stopwatchStartedAt,
          );
        }).toList();

        // Step 6: Map lists and associate them with their cards
        _lists = (responseData['included']['lists'] as List)
            .map((json) {
          final listCards = cards.where((card) => card.listId == json['id']).toList();
          return PlankaList.fromJson(json, listCards);
        }).toList();

        notifyListeners();
      } else {
        debugPrint('Failed to load lists: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to load lists: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error fetching lists: $error');
      throw Exception('Failed to load lists');
    }
  }

  Future<void> reorderCard({required BuildContext context, required String cardId, required int newPosition, required String newListId,}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/cards/$cardId');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'position': newPosition, 'listId': newListId}),
      );

      if (response.statusCode == 200) {
        print('Card reordered successfully.');
      } else {
        // Handle error
        print('Failed to reorder Card: ${response.statusCode}');
        throw Exception('Failed to reorder Card: ${response.reasonPhrase}');
      }
    } catch (error) {
      // Handle error
      print('Error reordering Card: $error');
      throw Exception('Failed to reorder Card.');
    }
  }

  Future<void> createLabelOnBoard({required String labelName, required String boardId, required BuildContext context}) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/boards/$boardId/labels?position=0');

      await http.post(
          url,
          body: json.encode({
            'name': labelName,
            'color': "berry-red"
          }),
          headers: {'Authorization': 'Bearer ${authProvider.token}'}
      );

      await fetchLists(boardId: boardId, context: context);

      notifyListeners();
    } catch (error) {
      debugPrint('Error creating label on board: $error');
      throw Exception('Failed to create label on board');
    }
  }

  Future<void> reorderList({
    required BuildContext context,
    required String listId,
    required String boardId,
    required int newPosition,
  }) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/lists/$listId');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'position': newPosition}),
      );

      ///Refresh / Load New Positions
      if(response.statusCode == 200){
        Provider.of<ListProvider>(context, listen: false).fetchLists(boardId: boardId, context: context);
      }
    } catch (error) {
      print('Error reordering list: $error');
      throw Exception('Failed to reorder list.');
    }
  }

  Future<void> createList({required String newListName, required String boardId, required BuildContext context, required String newPos}) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/boards/$boardId/lists/?position=$newPos');

      await http.post(
          url,
          body: json.encode({'name': newListName}),
          headers: {'Authorization': 'Bearer ${authProvider.token}'}
      );

      await fetchLists(boardId: boardId, context: context);

      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching boards: $error');
      throw Exception('Failed to load boards');
    }
  }

  Future<bool> deleteList(String listIdToDelete) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/lists/$listIdToDelete');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        List<PlankaList> listsToRemove = [];

        for (PlankaList list in _lists) {
          if (list.id == listIdToDelete) {
            listsToRemove.add(list);
          }
        }

        for (PlankaList list in listsToRemove) {
          _lists.remove(list);
        }

        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to delete list: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to delete list: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to delete list');
    }
  }

  Future<bool> updateListName(PlankaList list, String newListName) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/lists/${list.id}');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'name': newListName}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        int index = _lists.indexWhere((element) => element.id == list.id);

        if (index != -1) {
          PlankaList updatedList = PlankaList(
              id: list.id,
              name: newListName,
              cards: list.cards,
              position: list.position
          );

          _lists[index] = updatedList;

          notifyListeners();
          return true;
        } else {
          debugPrint('List with ID ${list.id} not found in _lists.');
          throw Exception('List not found in _lists.');
        }
      } else {
        debugPrint('Failed to update list: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to update list: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update list');
    }
  }

  Future<bool> createCard({required String newCardName, required String listId, required BuildContext context, required String boardId, required String newPos}) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/lists/$listId/cards/?position=$newPos');

      final response = await http.post(
          url,
          body: json.encode({'name': newCardName}),
          headers: {'Authorization': 'Bearer ${authProvider.token}'}
      );

      notifyListeners();

      if (response.statusCode == 200){
        return true;
      } else{
        return false;
      }
    } catch (error) {
      debugPrint('Error creating card: $error');
      throw Exception('Failed to create card');
    }
  }

  Future<Map<dynamic, dynamic>?> createCardForNewAttachment({
    required String newCardName,
    required String listId,
    required BuildContext context,
    required String boardId,
    required String newPos,
  }) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/lists/$listId/cards/?position=$newPos');

      final response = await http.post(
        url,
        body: json.encode({'name': newCardName}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      notifyListeners();

      if (response.statusCode == 200) {
        // Parse the response body to get the card data (e.g., id)
        final Map<dynamic, dynamic> cardData = json.decode(response.body);
        return cardData;  // This should return the card ID and other data
      } else {
        return null;
      }
    } catch (error) {
      debugPrint('Error creating card: $error');
      throw Exception('Failed to create card');
    }
  }
}