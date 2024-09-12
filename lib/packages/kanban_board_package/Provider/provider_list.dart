import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'list_item_provider.dart';

import 'board_list_provider.dart';
import 'kanban_board_provider.dart';

class ProviderList {

  static final boardProvider = ChangeNotifierProvider<KanBanBoardProvider>(
    (ref) => KanBanBoardProvider(ref),
    
  );
  static final cardProvider = ChangeNotifierProvider<ListItemProvider>(
    (ref) => ListItemProvider(ref),
    
  );
  static final boardListProvider = ChangeNotifierProvider<BoardListProvider>(
    (ref) => BoardListProvider(ref),
    
  );
}
