import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/providers/board_provider.dart';
import 'package:planka_app/widgets/board_list.dart';
import 'package:provider/provider.dart';

import '../models/planka_project.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  _BoardScreenState createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  @override
  Widget build(BuildContext context) {
    final PlankaProject project = ModalRoute.of(context)!.settings.arguments as PlankaProject;
    final backgroundImageUrl = project.backgroundImage?['url'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${'boards_for'.tr()} ${project.name}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<BoardProvider>(context, listen: false).fetchBoards(projectId: project.id, context: context).then((_) {
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
              .fetchBoards(projectId: project.id, context: context),
          builder: (ctx, snapshot) => snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : Consumer<BoardProvider>(
            builder: (ctx, boardProvider, _) {
              _fetchUsersForBoards(context);

              return BoardList(
                boardProvider.boards,
                currentProject: project,
                usersPerBoard: boardProvider.boardUsersMap, // Pass the users to the BoardList
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

    for (var board in boardProvider.boards) {
      boardProvider.fetchBoardUsers(boardId: board.id, context: context);
    }
  }
}