import 'package:flutter/foundation.dart';

class PageIndexChangeNotifier extends ChangeNotifier {
  int _pageIndex = 0;

  int get pageIndex => _pageIndex;

  void setPageIndex(int index) {
    _pageIndex = index;
    notifyListeners();
  }
}
