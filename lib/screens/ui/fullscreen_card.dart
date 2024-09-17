import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/models/planka_card.dart';
import 'package:planka_app/providers/card_provider.dart';
import 'package:planka_app/widgets/card_list.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../providers/card_actions_provider.dart';
import '../../providers/list_provider.dart';

class FCardScreen extends StatefulWidget {
  const FCardScreen({super.key});

  @override
  _FCardScreenState createState() => _FCardScreenState();
}

class _FCardScreenState extends State<FCardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isEditingTitle = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleEditTitle(String cardName) {
    setState(() {
      _isEditingTitle = !_isEditingTitle;
      if (_isEditingTitle) {
        _titleController.text = cardName;
      }
    });
  }

  void _saveTitle(PlankaCard card, BuildContext ctx) {
    if(_titleController.text.isNotEmpty && _titleController.text != ""){
      Provider.of<CardProvider>(ctx, listen: false).updateCardTitle(
        newCardTitle: _titleController.text,
        context: ctx,
        cardId: card.id,
      );

      setState(() {
        card.name = _titleController.text;
        _isEditingTitle = false;
      });
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message:
          'not_empty_name'.tr(),
        ),
      );

      setState(() {
        _isEditingTitle = false;
      });
    }
  }

  // Callback method to refresh the lists
  void _refreshCard() {
    final PlankaCard card = ModalRoute.of(context)!.settings.arguments as PlankaCard;

    setState(() {
      Provider.of<CardProvider>(context, listen: false).fetchCard(cardId: card.id, context: context);
      Provider.of<CardActionsProvider>(context, listen: false).fetchCardComment(card.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final PlankaCard card = ModalRoute.of(context)!.settings.arguments as PlankaCard;

    return Scaffold(
      appBar: AppBar(
        title: _isEditingTitle
            ? Container(
          color: Colors.transparent,
          height: kToolbarHeight,
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _titleController,
            autofocus: true,
            onSubmitted: (_) => _saveTitle(card, context),
          ),
        )
            : GestureDetector(
          onTap: () => _toggleEditTitle(card.name),
          child: Container(
            color: Colors.transparent,
            height: kToolbarHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(card.name),
          ),
        ),
      ),

      body: FutureBuilder(
        future: Future.wait([
          Provider.of<CardProvider>(context, listen: false).fetchCard(cardId: card.id, context: context),
          Provider.of<CardActionsProvider>(context, listen: false).fetchCardComment(card.id),
        ]),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${'error'.tr()}: ${snapshot.error}'));
          } else {
            return Consumer2<CardProvider, CardActionsProvider>(
              builder: (ctx, cardProvider, cardActionsProvider, _) {
                final fetchedCard = cardProvider.card;
                final cardActions = cardActionsProvider.cardActions;

                if (fetchedCard == null) {
                  return Center(child: Text('card_not_found'.tr()));
                } else {
                  return CardList(
                    fetchedCard,
                    previewCard: card,
                    cardActions: cardActions,
                    onRefresh: _refreshCard,
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
