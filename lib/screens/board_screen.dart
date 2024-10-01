import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/providers/board_provider.dart';
import 'package:planka_app/widgets/board_list.dart';
import 'package:provider/provider.dart';

import '../models/planka_project.dart';

class BoardScreen extends StatefulWidget {
  PlankaProject? project;

  BoardScreen({super.key, this.project});

  @override
  _BoardScreenState createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _usersFetched = false; // Track if users have been fetched

  // Callback method to refresh the lists
  void _refreshBoards() {
    setState(() {
      Provider.of<BoardProvider>(context, listen: false).fetchBoards(projectId: widget.project!.id, context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImageUrl = widget.project?.backgroundImage?['url'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${'boards_for'.tr()} ${widget.project!.name}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<BoardProvider>(context, listen: false).fetchBoards(projectId: widget.project!.id, context: context).then((_) {
            _fetchUsersForBoards(context);
          });
        },
        foregroundColor: Colors.indigo,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.refresh_rounded, size: 35, color: Colors.white),
      ),
      body: Container(
        decoration: backgroundImageUrl != null
            ? BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(backgroundImageUrl),
            fit: BoxFit.cover,
          ),
        )
            : null,
        child: FutureBuilder(
          future: Provider.of<BoardProvider>(context, listen: false)
              .fetchBoards(projectId: widget.project!.id, context: context),
          builder: (ctx, snapshot) => snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : Consumer<BoardProvider>(
            builder: (ctx, boardProvider, _) {
              // Fetch users once after the boards are fetched
              if (!_usersFetched) {
                _fetchUsersForBoards(context);
              }

              return BoardList(
                boardProvider.boards,
                currentProject: widget.project!,
                usersPerBoard: boardProvider.boardUsersMap,
                onRefresh: _refreshBoards,
              );
            },
          ),
        ),
      ),
    );
  }

  // Fetch users for each board only once
  void _fetchUsersForBoards(BuildContext context) {
    final boardProvider = Provider.of<BoardProvider>(context, listen: false);

    // Fetch users only if they haven't been fetched yet
    if (!_usersFetched) {
      for (var board in boardProvider.boards) {
        boardProvider.fetchBoardUsers(boardId: board.id, context: context);
      }
      // setState(() {
        _usersFetched = true; // Ensure users are fetched only once
      // });
    }
  }
}