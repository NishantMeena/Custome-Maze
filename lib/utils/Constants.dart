import 'package:custom_mazeapp/models/level/level_item.dart';

class Constants {
  static const String ROW_NUMBER = "row_num";
  static const String COLUMN_NUMBER = "column_num";
  static const String LEVEL = "level";
  static const int DEF_LEVEL = 1;
  static int DEF_ROW_NUMBER = 15;
  static int DEF_COLUMN_NUMBER = 10;

  List<LevelItem> getLevelList() {
    return <LevelItem>[
      LevelItem(null,"1", 1, 10, 5, 60),
      LevelItem(null,"2", 0, 11, 6, 60),
      LevelItem(null,"3", 0, 12, 7, 60),
      LevelItem(null,"4", 0, 13, 8, 60),
      LevelItem(null,"5", 0, 14, 9, 60),
      LevelItem(null,"6", 0, 15, 10, 60),
      LevelItem(null,"7", 0, 16, 11, 60),
      LevelItem(null,"8", 0, 17, 12, 60),
      LevelItem(null,"9", 0, 18, 13, 60),
      LevelItem(null,"10", 0, 19, 14, 60),
      LevelItem(null,"11", 0, 20, 15, 60),
      LevelItem(null,"12", 0, 21, 16, 60),
      LevelItem(null,"13", 0, 22, 17, 60),
      LevelItem(null,"14", 0, 23, 18, 60),
      LevelItem(null,"15", 0, 24, 19, 60),
      LevelItem(null,"16", 0, 25, 20, 0),
      LevelItem(null,"17", 0, 26, 21, 0),
      LevelItem(null,"18", 0, 27, 22, 0),
      LevelItem(null,"19", 0, 28, 23, 0),
      LevelItem(null,"20", 0, 29, 24, 0),
      LevelItem(null,"21", 0, 30, 25, 0),
      LevelItem(null,"22", 0, 31, 26, 0),
      LevelItem(null,"23", 0, 32, 27, 0),
      LevelItem(null,"24", 0, 33, 28, 0),
      LevelItem(null,"25", 0, 34, 29, 0),
    ];
  }
}
