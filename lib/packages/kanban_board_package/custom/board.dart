import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Provider/provider_list.dart';
import '../models/board_list.dart' as board_list;
import '../models/inputs.dart';
import 'board_list.dart';
import 'text_field.dart';

class KanbanBoard extends StatefulWidget {
  const KanbanBoard(
    this.list, {
    this.backgroundColor = Colors.white,
    this.cardPlaceHolderColor,
    this.boardScrollConfig,
    this.listScrollConfig,
    this.listPlaceHolderColor,
    this.boardDecoration,
    this.cardTransitionBuilder,
    this.listTransitionBuilder,
    this.cardTransitionDuration = const Duration(milliseconds: 150),
    this.listTransitionDuration = const Duration(milliseconds: 150),
    this.listDecoration,
    this.textStyle,
    this.onItemTap,
    this.displacementX = 0.0,
    this.displacementY = 0.0,
    this.onItemReorder,
    this.onListReorder,
    this.onListRename,
    this.onNewCardInsert,
    this.onItemLongPress,
    this.onListTap,
    this.onListLongPress,
    this.onListCreate,
    super.key,
  });

  final List<BoardListsData> list;
  final Color backgroundColor;
  final ScrollConfig? boardScrollConfig;
  final ScrollConfig? listScrollConfig;
  final Color? cardPlaceHolderColor;
  final Color? listPlaceHolderColor;
  final TextStyle? textStyle;
  final Decoration? listDecoration;
  final Decoration? boardDecoration;
  final void Function(int? cardIndex, int? listIndex)? onItemTap;
  final void Function(int? cardIndex, int? listIndex)? onItemLongPress;
  final void Function(int? listIndex)? onListTap;
  final void Function(int? listIndex)? onListLongPress;
  final void Function(String? title)? onListCreate;
  final void Function(int? oldCardIndex, int? newCardIndex, int? oldListIndex,
      int? newListIndex)? onItemReorder;
  final void Function(int? oldListIndex, int? newListIndex)? onListReorder;
  final void Function(String? oldName, String? newName)? onListRename;
  final void Function(String? cardIndex, String? listIndex, String? text)?
      onNewCardInsert;
  final Widget Function(Widget child, Animation<double> animation)?
      cardTransitionBuilder;
  final Widget Function(Widget child, Animation<double> animation)?
      listTransitionBuilder;
  final double displacementX;
  final double displacementY;
  final Duration cardTransitionDuration;
  final Duration listTransitionDuration;

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Board(widget.list,
          displacementX: widget.displacementX,
          displacementY: widget.displacementY,
          backgroundColor: widget.backgroundColor,
          boardDecoration: widget.boardDecoration,
          cardPlaceHolderColor: widget.cardPlaceHolderColor,
          listPlaceHolderColor: widget.listPlaceHolderColor,
          listDecoration: widget.listDecoration,
          boardScrollConfig: widget.boardScrollConfig,
          listScrollConfig: widget.listScrollConfig,
          textStyle: widget.textStyle,
          onItemTap: widget.onItemTap,
          onItemLongPress: widget.onItemLongPress,
          onListTap: widget.onListTap,
          onListLongPress: widget.onListLongPress,
          onItemReorder: widget.onItemReorder,
          onListReorder: widget.onListReorder,
          onListRename: widget.onListRename,
          onListCreate: widget.onListCreate,
          onNewCardInsert: widget.onNewCardInsert,
          cardTransitionBuilder: widget.cardTransitionBuilder,
          listTransitionBuilder: widget.listTransitionBuilder,
          cardTransitionDuration: widget.cardTransitionDuration,
          listTransitionDuration: widget.listTransitionDuration),
    ));
  }
}

class Board extends ConsumerStatefulWidget {
  const Board(
    this.list, {
    this.backgroundColor = Colors.white,
    this.cardPlaceHolderColor,
    this.listPlaceHolderColor,
    this.boardDecoration,
    this.boardScrollConfig,
    this.listScrollConfig,
    this.cardTransitionBuilder,
    this.listTransitionBuilder,
    this.cardTransitionDuration = const Duration(milliseconds: 150),
    this.listTransitionDuration = const Duration(milliseconds: 150),
    this.listDecoration,
    this.textStyle,
    this.onItemTap,
    this.displacementX = 0.0,
    this.displacementY = 0.0,
    this.onItemReorder,
    this.onListReorder,
    this.onListRename,
    this.onNewCardInsert,
    this.onItemLongPress,
    this.onListTap,
    this.onListLongPress,
    this.onListCreate,
    super.key,
  });

  final List<BoardListsData> list;
  final Color backgroundColor;
  final Color? cardPlaceHolderColor;
  final Color? listPlaceHolderColor;
  final TextStyle? textStyle;
  final Decoration? listDecoration;
  final Decoration? boardDecoration;
  final ScrollConfig? boardScrollConfig;
  final ScrollConfig? listScrollConfig;
  final void Function(int? cardIndex, int? listIndex)? onItemTap;
  final void Function(int? cardIndex, int? listIndex)? onItemLongPress;
  final void Function(int? listIndex)? onListTap;
  final void Function(int? listIndex)? onListLongPress;
  final void Function(String? newName)? onListCreate;
  final void Function(int? oldCardIndex, int? newCardIndex, int? oldListIndex,
      int? newListIndex)? onItemReorder;
  final void Function(int? oldListIndex, int? newListIndex)? onListReorder;
  final void Function(String? oldName, String? newName)? onListRename;
  final void Function(String? cardIndex, String? listIndex, String? text)?
      onNewCardInsert;
  final Widget Function(Widget child, Animation<double> animation)?
      cardTransitionBuilder;
  final Widget Function(Widget child, Animation<double> animation)?
      listTransitionBuilder;
  final double displacementX;
  final double displacementY;
  final Duration cardTransitionDuration;
  final Duration listTransitionDuration;

  @override
  ConsumerState<Board> createState() => _BoardState();
}

class _BoardState extends ConsumerState<Board> {
  @override
  void initState() {
    var boardProv = ref.read(ProviderList.boardProvider);
    var boardListProv = ref.read(ProviderList.boardListProvider);
    boardProv.initializeBoard(
        data: widget.list,
        boardScrollConfig: widget.boardScrollConfig,
        listScrollConfig: widget.listScrollConfig,
        displacementX: widget.displacementX,
        displacementY: widget.displacementY,
        backgroundColor: widget.backgroundColor,
        boardDecoration: widget.boardDecoration,
        cardPlaceHolderColor: widget.cardPlaceHolderColor,
        listPlaceHolderColor: widget.listPlaceHolderColor,
        listDecoration: widget.listDecoration,
        textStyle: widget.textStyle,
        onItemTap: widget.onItemTap,
        onItemLongPress: widget.onItemLongPress,
        onListTap: widget.onListTap,
        onListLongPress: widget.onListLongPress,
        onItemReorder: widget.onItemReorder,
        onListReorder: widget.onListReorder,
        onListRename: widget.onListRename,
        onNewCardInsert: widget.onNewCardInsert,
        cardTransitionBuilder: widget.cardTransitionBuilder,
        listTransitionBuilder: widget.listTransitionBuilder,
        cardTransitionDuration: widget.cardTransitionDuration,
        listTransitionDuration: widget.listTransitionDuration);

    for (var element in boardProv.board.lists) {
      // List Scroll Listener
      element.scrollController.addListener(() {
        if (boardListProv.scrolling) {
          if (boardListProv.scrollingDown) {
            boardProv.valueNotifier.value = Offset(
                boardProv.valueNotifier.value.dx,
                boardProv.valueNotifier.value.dy + 0.00001);
          } else {
            boardProv.valueNotifier.value = Offset(
                boardProv.valueNotifier.value.dx,
                boardProv.valueNotifier.value.dy + 0.00001);
          }
        }
      });
    }

    // Board Scroll Listener
    boardProv.board.controller.addListener(() {
      if (boardProv.scrolling) {
        if (boardProv.scrollingLeft && boardProv.board.isListDragged) {
          for (var element in boardProv.board.lists) {
            if (element.context == null) break;
            var of = (element.context!.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero);
            element.x = of.dx - boardProv.board.displacementX! - 10;
            element.width = element.context!.size!.width - 30;
            element.y = of.dy - widget.displacementY + 24;
          }
          boardListProv.moveListLeft();
        } else if (boardProv.scrollingRight && boardProv.board.isListDragged) {
          for (var element in boardProv.board.lists) {
            if (element.context == null) break;
            var of = (element.context!.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero);
            element.x = of.dx - boardProv.board.displacementX! - 10;
            element.width = element.context!.size!.width - 30;
            element.y = of.dy - widget.displacementY + 24;
          }
          boardListProv.moveListRight();
        }
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var boardProv = ref.read(ProviderList.boardProvider);
    var boardListProv = ref.read(ProviderList.boardListProvider);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      boardProv.board.setstate = () => setState(() {});
      var box = context.findRenderObject() as RenderBox;
      boardProv.board.displacementX =
          box.localToGlobal(Offset.zero).dx - 10; //- margin
      boardProv.board.displacementY =
          box.localToGlobal(Offset.zero).dy + 24; // statusbar
    });
    return Listener(
      onPointerUp: (event) {
        if (boardProv.board.isElementDragged || boardProv.board.isListDragged) {
          if (boardProv.board.isElementDragged) {
            ref.read(ProviderList.cardProvider).reorderCard();
          }
          if (boardProv.board.isListDragged) {
            ref.read(ProviderList.boardListProvider).reorderListFromKanBanBoard();
          }
          boardProv.setcanDrag(value: false, listIndex: 0, itemIndex: 0);
          setState(() {});
        }
      },
      onPointerMove: (event) {
        if (boardProv.board.isElementDragged) {
          if (event.delta.dx > 0) {
            boardProv.boardScroll();
          } else {
            boardProv.boardScroll();
          }
        } else if (boardProv.board.isListDragged) {
          if (event.delta.dx > 0) {
            boardProv.boardScroll();
            boardListProv.moveListRight();
          } else {
            boardProv.boardScroll();
            boardListProv.moveListLeft();
          }
        }
        boardProv.valueNotifier.value = Offset(
            event.delta.dx + boardProv.valueNotifier.value.dx,
            event.delta.dy + boardProv.valueNotifier.value.dy);
      },
      child: GestureDetector(
        onTap: () {
          if (boardProv.board.newCardFocused == true) {
            ref.read(ProviderList.cardProvider).saveNewCard();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: widget.boardDecoration ??
                BoxDecoration(color: widget.backgroundColor),
            child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 1200,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.touch,
                            },
                          ),
                          child: SingleChildScrollView(
                            controller: boardProv.board.controller,
                            physics: const PageScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            child: Transform(
                              alignment: Alignment.topLeft,
                              // scaleX: 0.45,
                              transform: Matrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0,
                                  1, 0, 0, 0, 0, 1),
                              child: Row(
                                  children: boardProv.board.lists
                                      .map(
                                          (e) =>
                                              boardProv.board.lists
                                                          .indexOf(e) !=
                                                      boardProv.board.lists
                                                              .length -
                                                          1
                                                  ? Container(
                                                       margin: const EdgeInsets.only(left: 20,),
                                                    child: BoardList(
                                                        index: boardProv
                                                            .board.lists
                                                            .indexOf(e),
                                                      ),
                                                  )
                                                  : Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        BoardList(
                                                          index: boardProv
                                                              .board.lists
                                                              .indexOf(e),
                                                        ),
                                                        boardListProv.newList
                                                            ? Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  top: 20,
                                                                  right: 30,
                                                                ),
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  bottom: 20,
                                                                ),
                                                                width: 300,
                                                                color: const Color
                                                                    .fromARGB(
                                                                  255,
                                                                  247,
                                                                  248,
                                                                  252,
                                                                ),
                                                                child: Wrap(
                                                                  children: [
                                                                    SizedBox(
                                                                      height:
                                                                          50,
                                                                      width:
                                                                          300,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          IconButton(
                                                                            onPressed:
                                                                                () {
                                                                              setState(() {
                                                                                boardListProv.newList = false;
                                                                                boardProv.board.newCardTextController.clear();
                                                                              });
                                                                            },
                                                                            icon: const Icon(Icons.close),
                                                                          ),
                                                                          IconButton(
                                                                              onPressed: () {
                                                                                setState(() {
                                                                                  boardListProv.newList = false;
                                                                                  // boardProv.board.lists.add(board_list.BoardList(
                                                                                  //   width: 300,
                                                                                  //   scrollController: ScrollController(),
                                                                                  //   items: [],
                                                                                  //   title: boardProv.board.newCardTextController.text,
                                                                                  // ));

                                                                                  ///Create New List Here
                                                                                  if (widget.onListCreate != null) {
                                                                                    widget.onListCreate!(boardProv.board.newCardTextController.text);
                                                                                  }

                                                                                  boardProv.board.newCardTextController.clear();
                                                                                });
                                                                              },
                                                                              icon: const Icon(Icons.done))
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                        width:
                                                                            300,
                                                                        color: Colors
                                                                            .white,
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                20,
                                                                            right:
                                                                                10,
                                                                            left:
                                                                                10),
                                                                        child:
                                                                            const TField()),
                                                                  ],
                                                                ),
                                                              )
                                                            : GestureDetector(
                                                                onTap: () {
                                                                  if (boardProv
                                                                          .board
                                                                          .newCardFocused ==
                                                                      true) {
                                                                    ref
                                                                        .read(ProviderList
                                                                            .cardProvider)
                                                                        .saveNewCard();
                                                                  }
                                                                  boardListProv
                                                                          .newList =
                                                                      true;
                                                                  setState(
                                                                      () {});
                                                                },
                                                                child: Container(
                                                                    height: 50,
                                                                    width: 300,
                                                                    margin: const EdgeInsets.only(top: 20, right: 20,),
                                                                    decoration: BoxDecoration(
                                                                        color: const Color.fromARGB(
                                                                          255,
                                                                          247,
                                                                          248,
                                                                          252,
                                                                        ),
                                                                        borderRadius: BorderRadius.circular(6)),
                                                                    child: Center(child: Text("Add List", style: widget.textStyle))),
                                                              )
                                                      ],
                                                    ))
                                      .toList()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: boardProv.valueNotifier,
                  builder: (ctx, Offset value, child) {
                    if (boardProv.board.isElementDragged) {
                      boardListProv.maybeListScroll();
                    }
                    return boardProv.board.isElementDragged ||
                            boardProv.board.isListDragged
                        ? Positioned(
                            left: value.dx,
                            top: value.dy,
                            child: Opacity(
                              opacity: 0.4,
                              child: boardProv.draggedItemState!.child,
                            ),
                          )
                        : Container();
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
