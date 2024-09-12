import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/models/planka_project.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ProjectList extends StatefulWidget {
  final List<PlankaProject> projects;

  const ProjectList(this.projects, {super.key});

  @override
  ProjectListState createState() => ProjectListState();
}

class ProjectListState extends State<ProjectList> {

  late TextEditingController _newProjectController;
  final bool _isAddingNewProject = false;

  @override
  void initState() {
    super.initState();
    _newProjectController = TextEditingController();
  }

  @override
  void dispose() {
    _newProjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if projects are null or empty
    if (widget.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 0),
      child: ListView.builder(
        itemCount: widget.projects.length + 1,
        itemBuilder: (ctx, index) {
          if (index == widget.projects.length) {
            // Last item: Show text input to add new project
            if (_isAddingNewProject) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  title: TextField(
                    controller: _newProjectController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: 'project_name'.tr()),
                    onSubmitted: (value) {
                      showTopSnackBar(
                        Overlay.of(context),
                        CustomSnackBar.info(
                          message: 'not_available_function'.tr(),
                        ),
                      );
                    },
                  ),
                ),
              );
            } else {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                color: Colors.indigo,
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('create_project'.tr(), style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () {
                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.info(
                        message: 'not_available_function'.tr(),
                      ),
                    );
                  },
                ),
              );
            }
          } else {
            final project = widget.projects[index];
            final users = project.users;
            final backgroundImageUrl = project.backgroundImage?['url'];

            return Card(
              color: Colors.grey[700],
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  image: backgroundImageUrl != null
                      ? DecorationImage(
                    image: NetworkImage(backgroundImageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  title: Text(
                    project.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show user avatars, limit overflow
                      if (users.isNotEmpty)
                        ...users.take(3).map((user) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: CircleAvatar(
                              radius: 15,
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null ? Text(user.name[0]) : null,
                            ),
                          );
                        }).toList(),
                      if (users.length > 3)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.0),
                          child: Text(
                            '...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/boards',
                      arguments: project,
                    );
                  },
                  onLongPress: () {
                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.info(
                        message: 'not_available_function'.tr(),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

  // void _showDeleteProject(BuildContext context, PlankaProject project, int index) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Delete Project'),
  //         content: Text('Are you sure you want to delete ${project.name}?'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: const Text('Yes'),
  //             onPressed: () {
  //               // Delete logic here
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
