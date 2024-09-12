import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../custom/list_item.dart';
import '../custom/text_field.dart';
import '../models/item_state.dart';
import 'provider_list.dart';

class BoardListProvider extends ChangeNotifier {
  BoardListProvider(ChangeNotifierProviderRef<BoardListProvider> this.ref);
  Ref ref;
  var scrolling = false;
  var scrollingUp = false;
  var scrollingDown = false;
  var newList = false;

  void calculateSizePosition(
      {required int listIndex,
      required BuildContext context,
      required VoidCallback setstate}) {
    var prov = ref.read(ProviderList.boardProvider);
    prov.board.lists[listIndex].context = context;
    var box = context.findRenderObject() as RenderBox;
    var location = box.localToGlobal(Offset.zero);
    prov.board.lists[listIndex].x =
        location.dx - prov.board.displacementX! - 10;
    prov.board.lists[listIndex].setState = setstate;
    prov.board.lists[listIndex].y =
        location.dy - prov.board.displacementY! + 24;
    prov.board.lists[listIndex].width ??= box.size.width;
    prov.board.lists[listIndex].height ??= box.size.height;
  }
  Future addNewCard({required String position, required int listIndex}) async {
    var prov = ref.read(ProviderList.boardProvider);
    if (prov.board.newCardFocused == true) {
      ref.read(ProviderList.cardProvider).saveNewCard();
    }

    var scroll = prov.board.lists[listIndex].scrollController;

    prov.board.lists[listIndex].items.insert(
      position == "TOP" ? 0 : prov.board.lists[listIndex].items.length,
      ListItem(
        child: Container(
          width: prov.board.lists[listIndex].width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // Rounded edges with a radius of 8
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: const TField(),
        ),
        listIndex: listIndex,
        isNew: true,
        index: prov.board.lists[listIndex].items.length,
        prevChild: Container(
          width: prov.board.lists[listIndex].width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // Rounded edges with a radius of 8
          ),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          child: const TField(),
        ),
      ),
    );

    position == "TOP" ? await scrollToMin(scroll) : scrollToMax(scroll);
    prov.board.newCardListIndex = listIndex;
    prov.board.newCardFocused = true;
    prov.board.newCardIndex =
    position == "TOP" ? 0 : prov.board.lists[listIndex].items.length - 1;
    prov.board.lists[listIndex].setState!();
  }

  void onListLongpress(
      {required int listIndex,
      required BuildContext context,
      required VoidCallback setstate}) {
    var prov = ref.read(ProviderList.boardProvider);
    for (var element in prov.board.lists) {
      if (element.context == null) break;
      var of = (element.context!.findRenderObject() as RenderBox)
          .localToGlobal(Offset.zero);
      element.x = of.dx - prov.board.displacementX!;
      element.width = element.context!.size!.width - 30;
      element.height = element.context!.size!.height - 30;
      element.y = of.dy - prov.board.displacementY!;
    }
    var box = context.findRenderObject() as RenderBox;
    var location = box.localToGlobal(Offset.zero);
    prov.updateValue(
        dx: location.dx - prov.board.displacementX! - 10,
        dy: location.dy - prov.board.displacementY! + 24);

    prov.board.dragItemIndex = null;
    prov.board.dragItemOfListIndex = listIndex;
    prov.draggedItemState = DraggedItemState(
        child: Container(
          width: box.size.width - 30,
          height: box.size.height - 30,
          color: prov.board.lists[listIndex].backgroundColor,
          child: Column(children: [

            ///HEADER
            prov.board.lists[listIndex].header ?? const SizedBox.shrink(),

            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  controller: null,
                  itemCount: prov.board.lists[listIndex].items.length,
                  shrinkWrap: true,
                  itemBuilder: (ctx, index) {
                    return Item(
                      color: prov.board.lists[listIndex].items[index]
                              .backgroundColor ??
                          Colors.grey.shade200,
                      itemIndex: index,
                      listIndex: listIndex,
                    );
                  },

                  // itemCount: prov.items.length,
                ),
              ),
            ),

            ///FOOTER
            prov.board.lists[listIndex].footer ?? const SizedBox.shrink(),
          ]),
        ),
        listIndex: listIndex,
        itemIndex: null,
        height: box.size.height - 30,
        width: box.size.width - 30,
        x: location.dx - prov.board.displacementX!,
        y: location.dy - prov.board.displacementY!);
    prov.draggedItemState!.setState = () => setstate;
    prov.board.dragItemIndex = null;
    prov.board.isListDragged = true;
    prov.board.dragItemOfListIndex = listIndex;
    setstate();
  }

  Future scrollToMax(ScrollController controller) async {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      return;
    }

    //log(controller.position.extentAfter.toString());
    await controller.animateTo(
      controller.position.pixels + controller.position.extentAfter,
      duration: Duration(
          milliseconds: (int.parse(controller.position.extentAfter
              .toString()
              .substring(0, 3)
              .split('.')
              .first))),
      curve: Curves.linear,
    );
    scrollToMax(controller);
  }

  Future scrollToMin(ScrollController controller) async {
    if (controller.position.pixels == controller.position.minScrollExtent) {
      return;
    }

    log(controller.position.extentBefore.toString());
    await controller.animateTo(
      controller.position.pixels - controller.position.extentBefore,
      duration: Duration(
          milliseconds: (int.parse(controller.position.extentBefore
              .toString()
              .substring(0, 3)
              .split('.')
              .first))),
      curve: Curves.linear,
    );
    scrollToMin(controller);
  }

  void maybeListScroll() async {
    var prov = ref.read(ProviderList.boardProvider);
    if (prov.board.isElementDragged == false || scrolling) {
      return;
    }
    var controller =
        prov.board.lists[prov.board.dragItemOfListIndex!].scrollController;
    if (controller.offset < controller.position.maxScrollExtent &&
        prov.valueNotifier.value.dy >
            controller.position.viewportDimension - 50) {
      scrolling = true;
      scrollingDown = true;
      if (prov.board.listScrollConfig == null) {
        await controller.animateTo(controller.offset + 45,
            duration: const Duration(milliseconds: 250), curve: Curves.linear);
      } else {
        await controller.animateTo(
            prov.board.listScrollConfig!.offset + controller.offset,
            duration: prov.board.listScrollConfig!.duration,
            curve: prov.board.listScrollConfig!.curve);
      }
      scrolling = false;
      scrollingDown = false;

      maybeListScroll();
    } else if (controller.offset > 0 && prov.valueNotifier.value.dy < 100) {
      scrolling = true;
      scrollingUp = true;
      if (prov.board.listScrollConfig == null) {
        await controller.animateTo(controller.offset - 45,
            duration: const Duration(milliseconds: 250), curve: Curves.linear);
      } else {
        await controller.animateTo(
            controller.offset - prov.board.listScrollConfig!.offset,
            duration: prov.board.listScrollConfig!.duration,
            curve: prov.board.listScrollConfig!.curve);
      }
      scrolling = false;
      scrollingUp = false;
      maybeListScroll();
    } else {
      return;
    }
  }

  void moveListRight() {
    var prov = ref.read(ProviderList.boardProvider);
    if (prov.draggedItemState!.listIndex == prov.board.lists.length - 1) {
      return;
    }
    if (prov.valueNotifier.value.dx +
            prov.board.lists[prov.draggedItemState!.listIndex!].width! / 2 <
        prov.board.lists[prov.draggedItemState!.listIndex! + 1].x!) {
      return;
    }
    // dev.log("LIST RIGHT");
    prov.board.lists.insert(prov.draggedItemState!.listIndex! + 1,
        prov.board.lists.removeAt(prov.draggedItemState!.listIndex!));
    prov.draggedItemState!.listIndex = prov.draggedItemState!.listIndex! + 1;
    prov.board.dragItemIndex = null;
    prov.draggedItemState!.itemIndex = null;
    prov.board.lists[prov.draggedItemState!.listIndex! - 1].setState!();
    prov.board.lists[prov.draggedItemState!.listIndex!].setState!();
  }

  void moveListLeft() {
    var prov = ref.read(ProviderList.boardProvider);
    if (prov.draggedItemState!.listIndex == 0) {
      return;
    }
    if (prov.valueNotifier.value.dx >
        prov.board.lists[prov.draggedItemState!.listIndex! - 1].x! +
            (prov.board.lists[prov.draggedItemState!.listIndex! - 1].width! /
                2)) {
      // dev.log(
      // "RETURN LEFT LIST ${prov.valueNotifier.value.dx} ${prov.board.lists[prov.draggedItemState!.listIndex! - 1].x! + (prov.board.lists[prov.draggedItemState!.listIndex! - 1].width! / 2)} ");
      return;
    }
    // dev.log("LIST LEFT ${prov.valueNotifier.value.dx} ${prov.board.lists[prov.draggedItemState!.listIndex! - 1].x! + (prov.board.lists[prov.draggedItemState!.listIndex! - 1].width! / 2)} ");
    prov.board.lists.insert(prov.draggedItemState!.listIndex! - 1,
        prov.board.lists.removeAt(prov.draggedItemState!.listIndex!));
    prov.draggedItemState!.listIndex = prov.draggedItemState!.listIndex! - 1;
    prov.board.dragItemIndex = null;
    prov.draggedItemState!.itemIndex = null;
    prov.board.lists[prov.draggedItemState!.listIndex!].setState!();
    prov.board.lists[prov.draggedItemState!.listIndex! + 1].setState!();
  }

  void reorderListFromKanBanBoard() {
    var prov = ref.read(ProviderList.boardProvider);

    // Get the old and new indices of the dragged list
    int oldListIndex = prov.draggedItemState!.listIndex!;
    int newListIndex = prov.board.dragItemOfListIndex!;

    // If the old and new positions are the same, no reordering is necessary
    if (oldListIndex == newListIndex) {
      return;
    }

    // Trigger the `onListReorder` callback, passing the old and new list indices
    if (prov.board.onListReorder != null) {
      prov.board.onListReorder!(oldListIndex, newListIndex);
    }
  }

  void createNewList() {}
}
