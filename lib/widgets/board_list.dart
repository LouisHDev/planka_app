import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/models/planka_board.dart';
import 'package:planka_app/models/planka_project.dart';
import 'package:planka_app/models/planka_user.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../providers/board_provider.dart';
import '../screens/list_screen.dart';

class BoardList extends StatefulWidget {
  final List<PlankaBoard> boards;
  final Map<String, List<PlankaUser>> usersPerBoard; // Users per board map
  final PlankaProject currentProject;
  final VoidCallback? onRefresh;

  const BoardList(this.boards, {super.key, required this.currentProject, required this.usersPerBoard, this.onRefresh});

  @override
  BoardListState createState() => BoardListState();
}

class BoardListState extends State<BoardList> {

  @override
  Widget build(BuildContext context) {
    if (widget.boards.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 2,
          ),
          itemCount: widget.boards.length + 1,
          itemBuilder: (ctx, index) {
            if (index == widget.boards.length) {
              return GestureDetector(
                onTap: () {
                  showTopSnackBar(
                    Overlay.of(context),
                    CustomSnackBar.info(
                      message: 'not_available_function'.tr(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 50,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            } else {
              final board = widget.boards[index];
              final users = widget.usersPerBoard[board.id] ?? []; // Get users for this specific board

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListScreen(
                        currentProject: widget.currentProject,
                        currentBoard: board,
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  _showEditBoardDialog(context, board);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          board.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        // Users section with overflow handling
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: users.take(3).map((user) {
                                  return CircleAvatar(
                                    backgroundImage: user.avatarUrl != null
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    radius: 15,
                                    child: user.avatarUrl == null
                                        ? Text(user.name[0])
                                        : null,
                                  );
                                }).toList(),
                              ),
                              if (users.length > 3)
                                const Text(
                                  '...',
                                  style: TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      );
    }

    return Center(child: Text('no_boards'.tr()));
  }

  void _showEditBoardDialog(BuildContext context, PlankaBoard board) {
    final editBoardController = TextEditingController(text: board.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('edit_board'.tr()),
        content: TextField(
          autofocus: true,
          controller: editBoardController,
          decoration: InputDecoration(labelText: 'board_name'.tr()),
          onSubmitted: (value) {
            // setState(() {
              if(editBoardController.text.isNotEmpty && editBoardController.text != ""){
                Provider.of<BoardProvider>(ctx, listen: false).updateBoardName(board.id, value).then((_) {
                  // Call the onRefresh callback if it exists
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                });
              } else {
                showTopSnackBar(
                  Overlay.of(ctx),
                  CustomSnackBar.error(
                    message:
                    'not_empty_name'.tr(),
                  ),
                );
              }

              Navigator.of(ctx).pop();
            // });
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _showDeleteConfirmationDialog(ctx, board.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              if(editBoardController.text.isNotEmpty && editBoardController.text != ""){
                Provider.of<BoardProvider>(ctx, listen: false).updateBoardName(board.id, editBoardController.text).then((_) {
                  // Call the onRefresh callback if it exists
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                });
              } else {
                showTopSnackBar(
                  Overlay.of(ctx),
                  CustomSnackBar.error(
                    message:
                    'not_empty_name'.tr(),
                  ),
                );
              }

              Navigator.of(ctx).pop();
            },
            child: Text('change'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String boardId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_board_confirmation.0'.tr()),
        content: Text('delete_board_confirmation.1'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BoardProvider>(ctx, listen: false).deleteBoard(boardId, widget.currentProject.id, ctx);
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}
