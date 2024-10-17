
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_editor_plus/widgets/markdown_auto_preview.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:planka_app/models/planka_board.dart';
import 'package:planka_app/models/planka_card.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:planka_app/models/planka_card_actions.dart';
import 'package:planka_app/models/planka_fCard.dart';
import 'package:planka_app/providers/board_provider.dart';
import 'package:planka_app/providers/card_actions_provider.dart';
import 'package:planka_app/screens/ui/fullscreen_attachment.dart';
import 'package:planka_app/widgets/parts/stopwatch_display.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/card_models/planka_card_membership.dart';
import '../models/card_models/planka_label.dart';
import '../models/planka_user.dart';
import '../providers/attachment_provider.dart';
import '../providers/card_provider.dart';
import '../providers/list_provider.dart';

class CardList extends StatefulWidget {
  final PlankaFullCard card;
  final PlankaCard previewCard;
  final PlankaBoard currentBoard;
  final List<PlankaCardAction> cardActions;
  final VoidCallback? onRefresh;

  const CardList(this.card,{super.key, required this.previewCard, required this.cardActions, this.onRefresh, required this.currentBoard, });

  @override
  _CardListState createState() => _CardListState();
}

class _CardListState extends State<CardList> with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final ImagePicker _picker = ImagePicker();

  late Animation<double> _animation;
  late AnimationController _animationController;

  String? _editingTaskId;
  String _newTaskName = '';

  // A simple in-memory cache to store data
  Map<String, Image?> imageCache = {};
  Map<String, String> dueDateCache = {};

  Map<String, Color> labelColors = {};
  late Color selectedColor; ///for color picker when updating label color
  late String selectedColorName; ///for color picker when updating label color
  final TextEditingController _labelTitleController = TextEditingController();
  
  @override
  void initState() {
    super.initState();

    loadLabelColors();

    _descriptionController.text = widget.card.description ?? 'click_me_to_add_description'.tr();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _animation = CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _animationController,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _taskController.dispose();
    _focusNode.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _addTask(String taskText) async {
    await Provider.of<CardProvider>(context, listen: false).addTask(
        context: context,
        cardId: widget.card.id,
        taskText: taskText,
        newPos: widget.card.tasks != null && widget.card.tasks!.isNotEmpty ? (widget.card.tasks!.last.position + 1000).toString() : "1000"
    );

    await Provider.of<CardProvider>(context, listen: false).fetchCard(
      cardId: widget.card.id,
      context: context,
    );

    _taskController.clear();
    _focusNode.requestFocus();
  }

  void _updateTaskName(int index) async {
    String taskId = widget.card.tasks![index].id;

    // Send the HTTP request to update the task name
    await Provider.of<CardProvider>(context, listen: false).renameTask(
      context: context,
      taskId: taskId,
      newTaskName: _newTaskName,
    );

    // Update the local tasks list
    setState(() {
      widget.card.tasks![index].name = _newTaskName;
      _editingTaskId = null;
    });
  }

  void _removeTask(BuildContext ctx, int index) async {
    String taskId = widget.card.tasks![index].id;

    // Send the HTTP request to remove a task
    await Provider.of<CardProvider>(ctx, listen: false).removeTask(
      context: ctx,
      taskId: taskId,
    );

    // Update the local tasks list
    setState(() {
      widget.card.tasks!.removeAt(index);
    });
  }

  void _toggleTaskCompletion(int index) async {
    String taskId = widget.card.tasks![index].id;
    bool isCompleted = !widget.card.tasks![index].isCompleted;

    // Send the HTTP request to toggle task completion
    await Provider.of<CardProvider>(context, listen: false).toggleTaskCompletion(
      context: context,
      taskId: taskId,
      isCompleted: isCompleted,
    );

    // Update the local tasks list
    setState(() {
      widget.card.tasks![index].isCompleted = isCompleted;
    });
  }

  void _onReorderTask(int oldIndex, int newIndex) async {

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    String taskId = widget.card.tasks![oldIndex].id;

    ///Determine Positions from Cards Above and Below the new index
    num posAbove = newIndex > 0 ? widget.card.tasks![newIndex - 1].position : 0;
    num posBelow = newIndex < widget.card.tasks!.length - 1 ? widget.card.tasks![newIndex + 1].position : widget.card.tasks!.last.position + 1000;

    double newPosDouble = (posAbove + posBelow) / 2;
    int newPosFinal = newPosDouble.ceil();

    /// Send HTTP request to reorder task
    await Provider.of<CardProvider>(context, listen: false).reorderTask(
      context: context,
      taskId: taskId,
      newPosition: newPosFinal
    );

    /// Update local state to reflect the reordering
    setState(() {
      final task = widget.card.tasks!.removeAt(oldIndex);
      widget.card.tasks!.insert(newIndex, task);
    });
  }

  void _saveDescription(PlankaFullCard card, BuildContext ctx) {
    String newDesc = _descriptionController.text.isEmpty ? 'click_me_to_add_description'.tr() : _descriptionController.text;

    Provider.of<CardProvider>(ctx, listen: false).updateCardDescription(
      newCardDesc: newDesc,
      context: ctx,
      cardId: card.id,
    );
  }

  void _showDeleteTaskConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_task_confirmation.0'.tr()),
        content: Text('delete_task_confirmation.1'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              _removeTask(ctx, index);
              Navigator.of(ctx).pop();
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentConfirmationDialog(BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_comment_confirmation.0'.tr()),
        content: Text('delete_comment_confirmation.1'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<CardActionsProvider>(ctx, listen: false).deleteComment(commentId).then((_) {
                // Call the onRefresh callback if it exists
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              });
              Navigator.of(ctx).pop();
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _handleLabelUpdate(String labelId){
    if(_labelTitleController.text != ""){
      Provider.of<BoardProvider>(context, listen: false)
          .updateLabel(labelId, _labelTitleController.text, selectedColorName)
          .then((_) {
        // Call the onRefresh callback if it exists
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      });

      Navigator.of(context).pop();
      Navigator.of(context).pop();

      ///Still Have To Update Locally (Name and Color)
      //here

    } else {
      //Show Error, Label Name Cannot be empty
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.info(
          message: 'not_empty_name'.tr(),
        ),
      );
    }
  }

  void _openLabelUpdateDialog(BuildContext context, String labelId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'labels.3'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: _labelTitleController,
                  autofocus: true,
                  onSubmitted: (_) {
                    _handleLabelUpdate(labelId);
                  }
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: labelColors.length,
                  itemBuilder: (BuildContext context, int index) {
                    String colorName = labelColors.keys.elementAt(index);
                    Color color = labelColors[colorName]!;
                    bool isSelected = color == selectedColor;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color; // Update the selected color
                          selectedColorName = colorName; // Update the selected color Name
                        });

                        _handleLabelUpdate(labelId);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null, // Show icon if selected
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLabelBottomSheet(BuildContext context, List<PlankaLabel>? allLabels, List<CardLabel> cardLabels, String cardId) {
    final Set<String?> cardLabelIds = cardLabels.map((label) => label.labelId).toSet();
    final TextEditingController labelController = TextEditingController();
    bool isAddingLabel = false;  // This controls whether to show the label creation text field

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // This allows the bottom sheet to move up with the keyboard
      builder: (BuildContext context) {
        return StatefulBuilder(  // Use StatefulBuilder to update the UI inside the bottom sheet
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,  // Adjust the bottom padding based on the keyboard height
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // Minimize the size to fit content and keyboard
                    children: [
                      ...allLabels?.map((label) {
                        final bool isSelected = cardLabelIds.contains(label.id);

                        final Map<String?, PlankaLabel?> labelIdToLabel = {
                          for (var label in allLabels ?? []) label.id: label,
                        };

                        final matchingLabel = labelIdToLabel[label.id];
                        final colorName = matchingLabel?.color ?? 'indigo';
                        final color = labelColors[colorName] ?? Colors.indigo; // Fallback to indigo if not found

                        return GestureDetector(
                          onLongPress: () {
                            selectedColor = color;
                            selectedColorName = colorName;
                            _labelTitleController.text = label.name;
                            _openLabelUpdateDialog(context, label.id);
                          },
                          onTap: () {
                            if (isSelected) {
                              /// Remove Label
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Provider.of<CardProvider>(context, listen: false).removeCardLabel(
                                  context: context,
                                  cardId: cardId,
                                  labelId: label.id,
                                ).then((_) {
                                  // Call the onRefresh callback if it exists
                                  if (widget.onRefresh != null) {
                                    widget.onRefresh!();
                                  }
                                });

                                cardLabelIds.remove(label.id);
                              });
                            } else {
                              /// Add Label
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Provider.of<CardProvider>(context, listen: false).addCardLabel(
                                  context: context,
                                  cardId: cardId,
                                  labelId: label.id,
                                ).then((_) {
                                  // Call the onRefresh callback if it exists
                                  if (widget.onRefresh != null) {
                                    widget.onRefresh!();
                                  }
                                });

                                cardLabelIds.add(label.id);
                              });
                            }

                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 35,
                            margin: const EdgeInsets.only(left: 10, right: 10, bottom: 0, top: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                isSelected
                                    ? const Icon(Icons.check_box_rounded, color: Colors.white)
                                    : const Icon(Icons.check_box_outline_blank_rounded, color: Colors.white),
                                Text(
                                  label.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList() ?? [],

                      /// This is the "add label" section, which toggles between a plus icon and a text field
                      isAddingLabel
                          ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: labelController,
                                decoration: InputDecoration(
                                  hintText: 'labels.0'.tr(),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                String newLabelName = labelController.text.trim();
                                // Check if label already exists
                                bool exists = allLabels?.any((label) => label.name.toLowerCase() == newLabelName.toLowerCase()) ?? false;

                                if (newLabelName.isEmpty) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.error(message: 'not_empty_name'.tr(),),
                                  );
                                } else if (exists) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.error(message: 'labels.2'.tr(),),
                                  );
                                } else {
                                  // Call your custom createLabel function and pass the onLabelCreated callback
                                  _createLabel(cardId, newLabelName, context, widget.card.boardId!, (newLabel) {
                                    // Add the new label to the list and update the UI
                                    setState(() {
                                      allLabels?.add(newLabel);
                                      isAddingLabel = false;
                                    });
                                  });

                                  labelController.clear();
                                }
                              },
                            ),
                          ],
                        ),
                      )
                          : GestureDetector(
                        onTap: () {
                          // Show the text field for adding a new label
                          setState(() {
                            isAddingLabel = true;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          height: 35,
                          margin: const EdgeInsets.only(left: 10, right: 10, bottom: 0, top: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCardMembersBottomSheet(BuildContext context, List<PlankaUser> allMembers, List<PlankaCardMembership>? cardMembers, String cardId,) {
    // Create cardMemberIds from cardMembers, or use an empty set if cardMembers is null
    final Set<String> cardMemberIds = cardMembers != null
        ? cardMembers.map((member) => member.userId).toSet()
        : <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // This allows the bottom sheet to move up with the keyboard
      builder: (BuildContext context) {
        return StatefulBuilder(  // Use StatefulBuilder to update the UI inside the bottom sheet
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,  // Adjust the bottom padding based on the keyboard height
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // Minimize the size to fit content and keyboard
                    children: [
                      ...allMembers.map((member) {
                        // Check if the member is assigned (if cardMembers is null, no one is assigned)
                        final bool isAssigned = cardMemberIds.contains(member.id);

                        return GestureDetector(
                          onTap: () {
                            if (isAssigned) {
                              // Remove member from the card
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  cardMemberIds.remove(member.id);

                                  Provider.of<CardProvider>(context, listen: false).removeCardMember(context: context, cardId: cardId, userId: member.id).then((_) {
                                    // Call the onRefresh callback if it exists
                                    if (widget.onRefresh != null) {
                                      widget.onRefresh!();
                                    }
                                  });
                                });
                              });

                              Navigator.pop(context);
                            } else {
                              // Add member to the card
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  cardMemberIds.add(member.id);

                                  Provider.of<CardProvider>(context, listen: false).addCardMember(context: context, cardId: cardId, userId: member.id).then((_) {
                                    // Call the onRefresh callback if it exists
                                    if (widget.onRefresh != null) {
                                      widget.onRefresh!();
                                    }
                                  });
                                });
                              });

                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 35,
                            margin: const EdgeInsets.only(left: 10, right: 10, bottom: 0, top: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                isAssigned
                                    ? const Icon(Icons.check_box_rounded, color: Colors.white)
                                    : const Icon(Icons.check_box_outline_blank_rounded, color: Colors.white),
                                Text(
                                  member.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                                ),
                              ],
                            ),
                          ),
                        );
                      })

                      // Optionally, you can add an "Add Member" section if you want to allow adding new members.
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _createLabel(String cardId, String labelName, BuildContext context, String boardId, Function(PlankaLabel) onLabelCreated) {
    // Simulate label creation (replace this with your actual API call or logic)
    final newLabel = PlankaLabel(id: DateTime.now().toString(), name: labelName, position: 1, color: '', boardId: '');

    // Add the new label to the system (this is just a placeholder for where you would call your actual logic)
    Provider.of<ListProvider>(context, listen: false).createLabelOnBoard(labelName: labelName, boardId: boardId, context: context).then((_) {
      // Call the callback to update the allLabels list in the UI
      onLabelCreated(newLabel);
    }).catchError((error) {
      debugPrint('${'error'.tr()}: $error');
    });

    setState(() {
      Provider.of<ListProvider>(context, listen: false).fetchLists(boardId: boardId, context: context);
      Provider.of<CardProvider>(context, listen: false).fetchCard(cardId: cardId, context: context);
    });
  }

  // Load colors from JSON and store as Color objects
  Future<void> loadLabelColors() async {
    try {
      String jsonString = await rootBundle.loadString('assets/labelColors.json');
      // debugPrint(jsonString); // Log JSON content for debugging

      // Parse JSON and convert each color to a Color object
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      setState(() {
        labelColors = jsonMap.map((key, value) => MapEntry(key, _parseColor(value)));
      });
    } catch (e) {
      print("Error loading or parsing colors: $e");
    }
  }

  // Convert hex color string to Color object
  Color _parseColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor; // Add opacity if missing
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  List<Widget> _buildLabelWidgets(List<CardLabel>? cardLabels, List<PlankaLabel>? allLabels, BuildContext context, String cardId, Map<String, Color> labelColors) {

    final Map<String?, String?> labelIdToName = {
      for (var label in allLabels ?? []) label.id: label.name,
    };

    final Map<String?, PlankaLabel?> labelIdToLabel = {
      for (var label in allLabels ?? []) label.id: label,
    };

    // Build the list of label widgets
    List<Widget> labelWidgets = cardLabels?.map((label) {
      final labelName = labelIdToName[label.labelId] ?? 'unknown_label'.tr();

      final matchingLabel = labelIdToLabel[label.labelId];
      final colorName = matchingLabel?.color;
      final color = labelColors[colorName] ?? Colors.indigo; // Fallback to indigo if not found

      return Container(
        margin: const EdgeInsets.only(right: 4.0, bottom: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          labelName,
          style: const TextStyle(color: Colors.white, fontSize: 14.0),
        ),
      );
    }).toList() ?? [];

    // Add the "+" icon as the last item
    labelWidgets.add(
      Container(
        margin: const EdgeInsets.only(right: 4.0, bottom: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: GestureDetector(
          onTap: () {
            _showLabelBottomSheet(
              context,
              allLabels!,
              cardLabels ?? [],
              cardId,
            );
          },
          child: const Icon(Icons.add, size: 20, color: Colors.white),
        ),
      ),
    );

    return labelWidgets;
  }

  Widget buildAttachmentImage(String? attachmentUrl) {
    if (attachmentUrl != null) {
      // Check if the image is already in the cache
      if (imageCache.containsKey(attachmentUrl)) {
        // Return the cached image
        return imageCache[attachmentUrl] ?? const SizedBox.shrink();
      }

      // Fetch and cache the image if it's not already cached
      return FutureBuilder<Image?>(
        future: Provider.of<AttachmentProvider>(context, listen: false)
            .fetchAttachmentImage(
          myUrl: attachmentUrl,
          context: context,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          } else if (snapshot.hasError) {
            return const SizedBox.shrink();
          } else if (snapshot.hasData) {
            // Cache the fetched image
            imageCache[attachmentUrl] = snapshot.data!;
            return snapshot.data!;
          } else {
            return const SizedBox.shrink();
          }
        },
      );
    } else {
      return const Icon(Icons.image_not_supported, size: 48);
    }
  }

  Widget buildDueDateWidget(String newDueDate, String cardId){
    DateTime dueDate = DateTime.parse(newDueDate);
    DateTime now = DateTime.now();
    bool isOverdue = dueDate.isBefore(now);

    Duration difference = dueDate.difference(now);
    String formattedDate = "${dueDate.day.toString().padLeft(2, '0')}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.year}";

    String result;
    if (difference.isNegative) {
      result = formattedDate;
    } else {
      result = formattedDate;
    }

    // Check if the due date result is already in the cache
    if (dueDateCache.containsKey(dueDate)) {
      // Cache the calculated due date result
      dueDateCache[dueDate.toString()] = result;
    }

    return GestureDetector(
      onTap: () async {
        final DateTime? dateTime = await showOmniDateTimePicker(
            context: context,
            initialDate: dueDate
        );

        ///Update Card Due Date
        if(dateTime != null) {
          await Provider.of<CardProvider>(context, listen: false).updateCardDueDate(cardId: cardId, newDueDate: dateTime.toString()).then((_) {
            // Call the onRefresh callback if it exists
            if (widget.onRefresh != null) {
              widget.onRefresh!();
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 4.0, bottom: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isOverdue ? Colors.red[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.calendar_month_rounded),
            const SizedBox(width: 5,),
            Text(
              result,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardProvider = Provider.of<BoardProvider>(context, listen: false);

    return Scaffold(
      floatingActionButton: FloatingActionBubble(
        items: <Bubble>[
          // Bubble(
          //   title: "De-Abonnieren",
          //   iconColor: Colors.white,
          //   bubbleColor: Colors.indigo,
          //   icon: Icons.favorite_border,
          //   titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
          //   onPress: () {
          //     _animationController.reverse();
          //
          //     showTopSnackBar(
          //       Overlay.of(context),
          //       CustomSnackBar.info(
          //         message:
          //         'not_available_function'.tr(),
          //       ),
          //     );
          //   },
          // ),
          Bubble(
            title: 'members'.tr(),
            iconColor: Colors.white,
            bubbleColor: Colors.indigo,
            icon: Icons.group_rounded,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () async {
              _animationController.reverse();

              // Call fetchUsers to ensure users are fetched before accessing the list
              await boardProvider.fetchBoardUsersAndMemberships(boardId: widget.currentBoard.id, context: context);  // Ensure this completes before proceeding

              // Now access the users list directly from the provider
              List<PlankaUser> users = boardProvider.getBoardUsers(widget.currentBoard.id);  // Use the global users list

              // Assuming `cardMembers` and `cardId` are available in this context.
              List<PlankaCardMembership>? cardMembers = widget.card.cardMemberships; // Get the card members from the card object
              String cardId = widget.card.id; // Get the current card's ID

              // Now call the bottom sheet with the required arguments
              _showCardMembersBottomSheet(context, users, cardMembers, cardId);
            },
          ),
          Bubble(
            title: 'stopwatch_controls.timer_create'.tr(),
            iconColor: Colors.white,
            bubbleColor: Colors.indigo,
            icon: Icons.timer, // Changed the icon to represent starting the timer
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () async {
              // Check if the stopwatch is null
              if (widget.card.stopwatchTotal == null && widget.card.stopwatchStartedAt == null) {
                // Start the timer by setting the properties and updating the server
                widget.card.stopwatchTotal = 0;
                widget.card.stopwatchStartedAt = DateTime.now();

                // Update on the server
                await Provider.of<CardProvider>(context, listen: false).updateStopwatch(
                  context: context,
                  cardId: widget.card.id,
                  stopwatchTotal: widget.card.stopwatchTotal!,
                  stopwatchStartedAt: widget.card.stopwatchStartedAt != null ? widget.card.stopwatchStartedAt.toString() : null, // Set only if _startedAt is not null
                );

                // Optionally, refresh the UI
                setState(() {});

                _animationController.reverse();
              } else {
                showTopSnackBar(
                  Overlay.of(context),
                  CustomSnackBar.info(
                    message: "stopwatch_controls.timer_already_present".tr(),
                  ),
                );

                _animationController.reverse();
              }
            },
          ),
          Bubble(
            title: 'delete'.tr(),
            iconColor: Colors.white,
            bubbleColor: Colors.indigo,
            icon: Icons.delete,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _showDeleteCardConfirmationDialog(context);
              _animationController.reverse();
            },
          ),
        ],
        animation: _animation,
        onPress: () => _animationController.isCompleted
            ? _animationController.reverse()
            : _animationController.forward(),
        iconColor: Colors.white,
        iconData: Icons.menu_rounded,
        backGroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Wrap(
                children: _buildLabelWidgets(widget.card.cardLabels, widget.previewCard.labels, context, widget.card.id, labelColors),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if(widget.card.dueDate != null && widget.card.dueDate!.isNotEmpty)
                        buildDueDateWidget(widget.card.dueDate!, widget.card.id),
                      if(widget.card.stopwatchTotal != null || widget.card.stopwatchStartedAt != null)
                        StopwatchDisplay(
                          cardId: widget.card.id,
                          initialTotalSeconds: widget.card.stopwatchTotal!,
                          startedAt: widget.card.stopwatchStartedAt,
                        ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ///Card Members
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 3),
                    child: Row(
                      children: widget.previewCard.cardMemberships.map((membership) {
                        var user = widget.previewCard.cardUsers.firstWhere(
                              (user) => user.id == membership.userId,
                          orElse: () => PlankaUser(id: "", email: "", name: "", username: ""),
                        );

                        String initials = user.name.length >= 2 ? user.name.substring(0, 2) : user.name;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null ? Text(initials) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  const Icon(Icons.menu_rounded),
                  const SizedBox(width: 10,),
                  Text('description'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),

              ///Description
              MarkdownAutoPreview(
                controller: _descriptionController,
                emojiConvert: true,
                onChanged: (text) => _saveDescription(widget.card, context),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.check_box_outlined),
                  const SizedBox(width: 10,),
                  Text('tasks'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              (widget.card.tasks == null || widget.card.tasks!.isEmpty)
                  ? const SizedBox()
                  : ReorderableListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                onReorder: _onReorderTask,
                children: List.generate(
                  widget.card.tasks!.length,
                      (index) {
                        return ListTile(
                          key: Key(widget.card.tasks![index].id),
                          leading: Transform.scale(
                            scale: 0.9, // Adjust the scale to reduce the size of the checkbox if desired
                            child: Checkbox(
                              value: widget.card.tasks![index].isCompleted,
                              onChanged: (value) {
                                _toggleTaskCompletion(index);
                              },
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0.0), // Remove default padding
                          title: _editingTaskId == widget.card.tasks![index].id
                              ? TextField(
                            autofocus: true,
                            controller: TextEditingController(text: widget.card.tasks![index].name),
                            onChanged: (value) {
                              _newTaskName = value;
                            },
                            onSubmitted: (_) {
                              _updateTaskName(index);
                            },
                            onTapOutside: (newVal) {
                              FocusScope.of(context).unfocus(); // This will defocus the TextField when tapping outside
                              setState(() {
                                // widget.card.tasks![index].name = _newTaskName;
                                _editingTaskId = null;
                              });
                            },
                          )
                              : GestureDetector(
                            onTap: () {
                              setState(() {
                                _editingTaskId = widget.card.tasks![index].id;
                              });
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.card.tasks![index].name,
                                    style: TextStyle(
                                      decoration: widget.card.tasks![index].isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                    overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            padding: EdgeInsets.zero, // Remove padding from the trailing icon
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _showDeleteTaskConfirmationDialog(context, index);
                            },
                          ),
                        );
                  },
                ),
              ),
              TextField(
                controller: _taskController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  labelText: 'write_task'.tr(),
                ),
                onTapOutside: (newVal) {
                  FocusScope.of(context).unfocus(); // This will defocus the TextField when tapping outside
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _addTask(value);
                  }
                },
              ),
              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attachment),
                      const SizedBox(width: 10),
                      Text('attachments'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  IconButton(
                      onPressed: _showFileSelectionOptions,
                      icon: const Icon(Icons.add, size: 30, color: Colors.indigo,),
                  )
                ],
              ),

              if (widget.card.attachments != null && widget.card.attachments!.isNotEmpty)
                const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.card.attachments!.length,
                itemBuilder: (context, index) {
                  final attachment = widget.card.attachments![index];
                  bool isEditing = false; // Track if a field is being edited
                  final TextEditingController _controller = TextEditingController(text: attachment.name);

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => FAttachScreen(
                              attachmentUrl: attachment.url ?? "",
                              attachmentName: attachment.name,
                            ),
                          ));
                        },
                        onLongPress: () {
                          _showDeleteAttachmentConfirmationDialog(context, attachment.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(5)),
                                child: SizedBox(
                                  width: 75,
                                  height: 75,
                                  child: buildAttachmentImage(attachment.coverUrl),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isEditing
                                        ? TextField(
                                      autofocus: true,
                                      controller: _controller,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      onTapOutside: (newVal) {
                                        setState(() {
                                          isEditing = false;
                                        });
                                      },
                                      onSubmitted: (newValue) {
                                        setState(() {
                                          isEditing = false;
                                          // Update local name immediately
                                          attachment.name = newValue;
                                        });

                                        // Call provider to rename the attachment on the server
                                        Provider.of<AttachmentProvider>(context, listen: false)
                                            .renameAttachment(
                                            context: context,
                                            cardId: attachment.cardId,
                                            newAttachName: newValue,
                                            attachId: attachment.id
                                        );
                                      },
                                    )
                                        : GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isEditing = true;
                                        });
                                      },
                                      child: Text(
                                        attachment.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.date_range_rounded,
                                          color: Colors.grey[700],
                                        ),
                                        Text(
                                          formatDate(attachment.createdAt),
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (attachment.url != null) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.info(
                                            message: 'downloading_file'.tr(),
                                          ),
                                        );

                                        Provider.of<AttachmentProvider>(context, listen: false)
                                            .downloadFile(
                                          attachment.url!,
                                          attachment.name,
                                          context,
                                        );
                                      } else {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.info(
                                            message: 'attachment_no_url'.tr(),
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      Icons.download,
                                      size: 25,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.comment_outlined),
                  const SizedBox(width: 10,),
                  Text('comments'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'write_comment'.tr(),
                ),
                onTapOutside: (newVal) {
                  FocusScope.of(context).unfocus(); // This will de-focus the TextField when tapping outside
                },
                onSubmitted: (text) async {
                  await Provider.of<CardActionsProvider>(context, listen: false).createComment(widget.card.id, text).then((_) {
                    // Call the onRefresh callback if it exists
                    if (widget.onRefresh != null) {
                      widget.onRefresh!();
                    }
                  });
                  setState(() {
                    _commentController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),
              widget.cardActions.isEmpty
                  ? Text('no_comments_available'.tr())
                  : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.cardActions.length,
                itemBuilder: (context, index) {
                  final commentAction = widget.cardActions[index];
                  final commentText = commentAction.data.text;
                  final authorName = commentAction.user?.name ?? "";
                  final createdAt = commentAction.createdAt;

                  return GestureDetector(
                    onLongPress: () {
                      _showDeleteCommentConfirmationDialog(context, widget.cardActions[index].id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: commentAction.user?.avatarUrl != null
                                ? NetworkImage(commentAction.user!.avatarUrl!)
                                : null,
                            radius: 15,
                            child: commentAction.user?.avatarUrl == null
                                ? Text(authorName[0])
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                MarkdownAutoPreview(
                                  controller: TextEditingController(text: commentText), // Wrap the comment text in a TextEditingController
                                  emojiConvert: true, // Enable emoji support
                                  onChanged: (text) async {
                                    if(text.isNotEmpty){
                                      await Provider.of<CardActionsProvider>(context, listen: false).updateComment(widget.cardActions[index].id, text);
                                    } else {
                                      await Provider.of<CardActionsProvider>(context, listen: false).updateComment(widget.cardActions[index].id, "No text.");
                                      showTopSnackBar(
                                        Overlay.of(context),
                                        CustomSnackBar.error(
                                          message:
                                          'comment_not_empty'.tr(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${'posted_on'.tr()} ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(createdAt))}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context1) async {
    try {
      await _picker.pickImage(source: ImageSource.gallery).then((result) async{

        // Convert XFile to File
        if(result != null){
          File fileToUpload = File(result.path);

          context1
              .read<AttachmentProvider>()
              .createAttachment(context: context1, cardId: widget.card.id, file: fileToUpload)
              .then((_) {
            // After successfully creating the attachment, update the card cover attachment ID to null
            context1.read<CardProvider>().updateCardCoverAttachId(
              context: context1,
              cardId: widget.card.id,
              newCardCoverAttachId: null,
            );

            Navigator.of(context1).pop();
          });
        }

      });
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context1),
        CustomSnackBar.info(
          message: "${'error'.tr()}: $e",
        ),
      );
    }
  }

  Future<void> _takePhoto(BuildContext context1) async {
    try {
      await _picker.pickImage(source: ImageSource.camera).then((pickedFile) async{

        // Convert XFile to File
        if (pickedFile != null) {
          File fileToUpload = File(pickedFile.path);

          context1
              .read<AttachmentProvider>()
              .createAttachment(context: context1, cardId: widget.card.id, file: fileToUpload)
              .then((_) {
            // After successfully creating the attachment, update the card cover attachment ID to null
            context1.read<CardProvider>().updateCardCoverAttachId(
              context: context1,
              cardId: widget.card.id,
              newCardCoverAttachId: null,
            );

            Navigator.of(context1).pop();
          })
              .catchError((error) {
            // Handle any errors that occur during the chain of operations
            debugPrint('Error: $error');
          });
        }

      });
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context1),
        CustomSnackBar.info(
          message: "${'error'.tr()}: $e",
        ),
      );
    }
  }

  Future<void> _pickFile(BuildContext context1) async {
    try {
      await FilePicker.platform.pickFiles().then((result) async{

        // Convert XFile to File
        if(result != null && result.files.single.path != null){
          File fileToUpload = File(result.files.single.path!);

          context1
              .read<AttachmentProvider>()
              .createAttachment(context: context1, cardId: widget.card.id, file: fileToUpload)
              .then((_) {
            // After successfully creating the attachment, update the card cover attachment ID to null
            context1.read<CardProvider>().updateCardCoverAttachId(
              context: context1,
              cardId: widget.card.id,
              newCardCoverAttachId: null,
            );

            Navigator.of(context1).pop();
          });
        }

      });
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context1),
        CustomSnackBar.info(
          message: "${'error'.tr()}: $e",
        ),
      );
    }
  }

  void _showFileSelectionOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('file_picker.from_gallery'.tr()),
                onTap: () async {
                  await _pickImageFromGallery(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('file_picker.from_photo'.tr()),
                onTap: () async {
                  await _takePhoto(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text('file_picker.from_file'.tr()),
                onTap: () async {
                  await _pickFile(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteCardConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_card_confirmation.0'.tr()),
        content: Text('delete_card_confirmation.1'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CardProvider>(ctx, listen: false).deleteCard(context: ctx, cardId: widget.card.id);
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAttachmentConfirmationDialog(BuildContext context, String attachId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_attachment_confirmation.0'.tr()),
        content: Text('delete_attachment_confirmation.1'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AttachmentProvider>(ctx, listen: false).deleteAttachment(context: context, attachmentId: attachId);
              Navigator.of(ctx).pop();
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  String formatDate(String dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    String formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    return formattedDate;
  }
}
