import 'package:flutter/foundation.dart';
import '../models/mood_data.dart';

class MoodViewModel extends ChangeNotifier {
  final List<MoodData> _moods = [];

  List<MoodData> get moods => List.unmodifiable(_moods);

  void addMood(MoodData mood) {
    _moods.add(mood);
    notifyListeners();
  }
}
