import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planka_app/models/planka_board.dart';
import 'package:planka_app/models/planka_user.dart';
import 'dart:convert';
import 'auth_provider.dart';

class BoardProvider with ChangeNotifier {
  final List<PlankaBoard> _boards = [];
  final Map<String, List<PlankaUser>> _boardUsers = {};
  final AuthProvider authProvider;
  final Map<String, List<PlankaUser>> _boardUsersMap = {}; // Users per board

  BoardProvider(this.authProvider);

  List<PlankaBoard> get boards => _boards;
  // Access users for each board by board ID
  Map<String, List<PlankaUser>> get boardUsersMap => _boardUsersMap;
  // Access users per board using board ID
  List<PlankaUser> getBoardUsers(String boardId) => _boardUsers[boardId] ?? [];

  Future<void> fetchBoards({required String projectId, required BuildContext context}) async {
    try {
      final url = Uri.parse('https://${authProvider.domain}/api/projects/$projectId');

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

  Future<void> fetchBoardUsers({required String boardId, required BuildContext context}) async {
    try {
      final url = Uri.parse('https://${authProvider.domain}/api/boards/$boardId');

      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final includedData = responseData['included'];

        if (includedData != null && includedData.containsKey('users')) {
          final List<PlankaUser> users = (includedData['users'] as List)
              .map((userJson) => PlankaUser.fromJson(userJson))
              .toList();

          _boardUsersMap[boardId] = users; // Store users for the specific board
        } else {
          _boardUsersMap[boardId] = []; // If no users are found
        }

        notifyListeners();
      } else {
        throw Exception('Failed to load board users: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Failed to load board users');
    }
  }

  Future<void> createBoard({required String newBoardName, required String projectId, required BuildContext context, required String newPos}) async {
    try {
      final url = Uri.parse('https://${authProvider.domain}/api/projects/$projectId/boards/?position=$newPos');

      await http.post(
          url,
          body: json.encode({'name': newBoardName}),
          headers: {'Authorization': 'Bearer ${authProvider.token}'}
      );

      await fetchBoards(projectId: projectId, context: context);

      notifyListeners();
    } catch (error) {
      debugPrint('Error creating board: $error');
      throw Exception('Failed to create board');
    }
  }

  Future<void> deleteBoard(String boardIdToDelete, String projectId, BuildContext context) async {
    final url = Uri.parse('https://${authProvider.domain}/api/boards/$boardIdToDelete');

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
    final url = Uri.parse('https://${authProvider.domain}/api/boards/$boardIdToUpdate');

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

}
