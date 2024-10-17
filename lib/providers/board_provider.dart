import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planka_app/models/card_models/planka_membership.dart';
import 'package:planka_app/models/planka_board.dart';
import 'package:planka_app/models/planka_user.dart';
import 'dart:convert';
import 'auth_provider.dart';

class BoardProvider with ChangeNotifier {
  final List<PlankaBoard> _boards = [];
  final AuthProvider authProvider;
  final Map<String, List<PlankaUser>> _boardUsersMap = {}; // Users per board
  final Map<String, List<BoardMembership>> _boardMembershipsMap = {}; // Users per board

  BoardProvider(this.authProvider);

  List<PlankaBoard> get boards => _boards;
  // Access users for each board by board ID
  Map<String, List<PlankaUser>> get boardUsersMap => _boardUsersMap;
  Map<String, List<BoardMembership>> get boardMembershipsMap => _boardMembershipsMap;

  // Access users per board using board ID
  List<PlankaUser> getBoardUsers(String boardId) => _boardUsersMap[boardId] ?? [];

  Future<void> fetchBoards({required String projectId, required BuildContext context}) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/projects/$projectId');

      final response = await http.get(
          url,
          headers: {'Authorization': 'Bearer ${authProvider.token}'}
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final includedData = responseData['included'];

        _boards.clear();

        if (includedData != null && includedData.containsKey('boards')) {
          for (var boardJson in includedData['boards']) {
            final PlankaBoard board = PlankaBoard.fromJson(boardJson, includedData);
            _boards.add(board);
          }
        }

        notifyListeners();
      } else {
        debugPrint('Failed to load boards: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to load boards: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error fetching boards: $error');
      throw Exception('Failed to load boards');
    }
  }

  Future<void> fetchBoardUsersAndMemberships({required String boardId, required BuildContext context}) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/boards/$boardId');

      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final includedData = responseData['included'];

        // Initialize empty lists for users and memberships
        List<PlankaUser> users = [];
        List<BoardMembership> memberships = [];

        if (includedData != null) {
          // Extract users
          if (includedData.containsKey('users')) {
            users = (includedData['users'] as List).map((userJson) => PlankaUser.fromJson(userJson)).toList();
          }

          // Extract memberships
          if (includedData.containsKey('boardMemberships')) {
            memberships = (includedData['boardMemberships'] as List)
                .map((membershipJson) => BoardMembership.fromJson(membershipJson))
                .toList();
          }

          // Store users and memberships in separate maps
          _boardUsersMap[boardId] = users;           // Store users for the board
          _boardMembershipsMap[boardId] = memberships; // Store memberships for the board
        } else {
          // If no users or memberships are found, set empty lists
          _boardUsersMap[boardId] = [];
          _boardMembershipsMap[boardId] = [];
        }

        notifyListeners(); // Update listeners with new data
      } else {
        throw Exception('Failed to load board users and memberships: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Failed to load board users and memberships');
    }
  }

  Future<String> createBoard({required String newBoardName, required String projectId, required BuildContext context, required String newPos,}) async {
    try {
      final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/projects/$projectId/boards/?position=$newPos');

      final response = await http.post(
        url,
        body: json.encode({'name': newBoardName}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final boardId = responseData['item']['id']; // Die Board-ID aus der Antwort extrahieren

        await fetchBoards(projectId: projectId, context: context);

        notifyListeners();
        return boardId; // Die ID des erstellten Boards zurückgeben
      } else {
        throw Exception('Failed to create board');
      }
    } catch (error) {
      debugPrint('Error creating board: $error');
      throw Exception('Failed to create board');
    }
  }

  Future<void> deleteBoard(String boardIdToDelete, String projectId, BuildContext context) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/boards/$boardIdToDelete');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {

        boards.removeWhere((board) => board.id == boardIdToDelete);

        await fetchBoards(projectId: projectId, context: context);

        notifyListeners();
      } else {
        debugPrint('Failed to delete board: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to delete board: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error deleting board: $error');
      throw Exception('Failed to delete board');
    }
  }

  Future<bool> updateBoardName(String boardIdToUpdate, String newBoardName) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/boards/$boardIdToUpdate');

    try {
      final response = await http.patch(
        url,
        body: json.encode({'name': newBoardName}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {

        bool boardUpdated = false;

        int boardIndex = boards.indexWhere((board) => board.id == boardIdToUpdate);
        if (boardIndex != -1) {
          boards[boardIndex].name = newBoardName;
          boardUpdated = true;
        }

        if (boardUpdated) {
          notifyListeners();
          return true;
        } else {
          debugPrint('Board with ID $boardIdToUpdate not found in _boards.');
          throw Exception('Board not found in _boards.');
        }
      } else {
        debugPrint('Failed to update board: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to update board: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update board');
    }
  }

  Future<void> addBoardMember({required BuildContext context, required String boardId, required String userId}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/boards/$boardId/memberships');

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'boardId': boardId,
          'userId': userId,
          'role': "editor",
          'canComment': true
        }),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to add Board user: ${response.statusCode}');
        throw Exception('Failed to add Board user: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to add Board user');
    }
  }

  Future<void> removeBoardMember({required BuildContext context, required String id}) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/board-memberships/$id');

    try {
      final response = await http.delete(
        url,
        body: json.encode({
          'id': id,
        }),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Failed to delete Board user: ${response.statusCode}');
        throw Exception('Failed to delete Board user: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to delete Board user');
    }
  }

  Future<void> updateLabel(String labelIdToUpdate, String newLabelName, String labelColor) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/labels/$labelIdToUpdate');

    try {
      await http.patch(
        url,
        body: json.encode({'name': newLabelName, 'color': labelColor}),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      notifyListeners();

    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to update board');
    }
  }
}
