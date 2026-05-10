import 'package:flutter/foundation.dart';

import '../browse/display_mode.dart';
import '../models/filter_type.dart';

/// Browse filters + search + sort + home display mode (mirrors web shell state).
class BrowseState extends ChangeNotifier {
  BrowseState()
      : filters = FilterType.empty,
        searchTerm = '',
        sortChain = const ['most_relevant'],
        displayMode = HackathonListDisplayMode.grid;

  FilterType filters;
  String searchTerm;
  List<String> sortChain;
  HackathonListDisplayMode displayMode;

  void setFilters(FilterType value) {
    filters = value;
    notifyListeners();
  }

  void setSearchTerm(String value) {
    searchTerm = value;
    notifyListeners();
  }

  void setSortChain(List<String> value) {
    sortChain = List.from(value);
    notifyListeners();
  }

  void setDisplayMode(HackathonListDisplayMode value) {
    displayMode = value;
    notifyListeners();
  }

  void resetFilters() {
    filters = FilterType.empty;
    notifyListeners();
  }
}
