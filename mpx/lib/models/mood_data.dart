enum MoodIcon {
  sunny,
  cloudy,
  rainy,
  sad,
  mellow,
}

class MoodData {
  final String mood;
  final MoodIcon icon;

  MoodData({required this.mood, required this.icon});
}

class DayMood {
  final String day;
  final MoodIcon icon;

  DayMood({required this.day, required this.icon});
}

