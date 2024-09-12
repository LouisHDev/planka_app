import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/models/planka_project.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../widgets/list_list.dart';
import '../models/planka_board.dart';

class ListScreen extends StatefulWidget {
  PlankaProject? currentProject;
  PlankaBoard? currentBoard;

  ListScreen({super.key, this.currentProject, this.currentBoard});

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImageUrl = widget.currentProject?.backgroundImage?['url'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${'lists_for'.tr()} ${widget.currentBoard?.name}'),
            IconButton(
                onPressed: () {
                  Provider.of<ListProvider>(context, listen: false).fetchLists(boardId: widget.currentBoard!.id, context: context);
                },
                icon: const Icon(Icons.refresh, color: Colors.indigo,)
            )
          ],
        )
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Provider.of<ListProvider>(context, listen: false).fetchLists(boardId: widget.currentBoard!.id, context: context);
      //   },
      //   foregroundColor: Colors.indigo,
      //   backgroundColor: Colors.indigo,
      //   child: const Icon(Icons.refresh, size: 35, color: Colors.white,),
      // ),

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
          future: Provider.of<ListProvider>(context, listen: false).fetchLists(boardId: widget.currentBoard!.id, context: context),
          builder: (ctx, snapshot) => snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : Consumer<ListProvider>(
            builder: (ctx, listProvider, _) => ListList(listProvider.lists, widget.currentBoard!),
          ),
        ),
      ),
    );
  }
}
