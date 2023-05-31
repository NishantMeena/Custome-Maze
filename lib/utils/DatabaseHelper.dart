import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static DatabaseHelper? _databaseHelper; // Singleton DatabaseHelper
  static Database? _database; // Singleton Database
  String gameTableBeg = 'game_level_beginner';
  String gameTableInter = 'game_level_intermediate';
  String gameTableAdvance = 'game_level_advance';
  String id = 'id';
  String levelname = 'level_name';
  String isOpen = 'isOpen';
  String row = 'row';
  String column = 'column';
  String count = 'count';
  String stars = 'stars';

  DatabaseHelper._createInstance(); // Named constructor to create instance of DatabaseHelper

  factory DatabaseHelper() {
    return _databaseHelper ??= DatabaseHelper._createInstance();
  }

  Future<Database> get database async {
    return _database ??= await initializeDatabase();
  }

  Future<Database> initializeDatabase() async {
    // Get the directory path for both Android and iOS to store database.
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}level.db';

    // Open/create the database at a given path
    var notesDatabase =
        await openDatabase(path, version: 1, onCreate: _createDb);
    return notesDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE $gameTableBeg($id INTEGER PRIMARY KEY AUTOINCREMENT, $levelname TEXT, '
        '$isOpen BOOLEAN,$row INTEGER, $column INTEGER, $count INTEGER,$stars INTEGER)');

    await db.execute(
        'CREATE TABLE $gameTableInter($id INTEGER PRIMARY KEY AUTOINCREMENT, $levelname TEXT, '
        '$isOpen BOOLEAN,$row INTEGER, $column INTEGER, $count INTEGER,$stars INTEGER)');

    await db.execute(
        'CREATE TABLE $gameTableAdvance($id INTEGER PRIMARY KEY AUTOINCREMENT, $levelname TEXT, '
        '$isOpen BOOLEAN,$row INTEGER, $column INTEGER, $count INTEGER,$stars INTEGER)');
  }

  // Fetch Operation: Get all level objects from database
  Future<List<Map<String, dynamic>>> getLevelMapList(int dificulty) async {
    Database db = await database;
    //	var result = await db.rawQuery('SELECT * FROM $levelTable order by $colPriority ASC');
    var result;
    if (dificulty == 0) {
      result = await db.query(gameTableBeg);
    } else if (dificulty == 1) {
      result = await db.query(gameTableInter);
    } else if (dificulty == 2) {
      result = await db.query(gameTableAdvance);
    }

    return result;
  }

  // Insert Operation: Insert a level object to database
  Future<int> insertLevel(LevelItem level, int dificulty) async {
    Database db = await database;
    var result;
    if (dificulty == 0) {
      result = await db.insert(gameTableBeg, level.toMap());
    } else if (dificulty == 1) {
      result = await db.insert(gameTableInter, level.toMap());
    } else if (dificulty == 2) {
      result = await db.insert(gameTableAdvance, level.toMap());
    }
    return result;
  }

  // Update Operation: Update a level object and save it to database
  void updateLevel(int id, int dificulty) async {
    var db = await database;
    var result;
    if (dificulty == 0) {
      result = await db
          .rawQuery("UPDATE $gameTableBeg SET isOpen=1 WHERE id=" + id.toString());
    } else if (dificulty == 1) {
      result = await db
          .rawQuery("UPDATE $gameTableInter SET isOpen=1 WHERE id=" + id.toString());
    } else if (dificulty == 2) {
      result = await db
          .rawQuery("UPDATE $gameTableAdvance SET isOpen=1 WHERE id=" + id.toString());
    }
  }



  // Update Operation: Update a level object and save it to database
  void updateStars(int id, int dificulty,int stars) async {
    var db = await database;
    var result;
    if (dificulty == 0) {
      result = await db
          .rawQuery("UPDATE $gameTableBeg SET stars=$stars WHERE id=" + id.toString());
    } else if (dificulty == 1) {
      result = await db
          .rawQuery("UPDATE $gameTableInter SET stars=$stars WHERE id=" + id.toString());
    } else if (dificulty == 2) {
      result = await db
          .rawQuery("UPDATE $gameTableAdvance SET stars=$stars WHERE id=" + id.toString());
    }
  }



  // Delete Operation: Delete a level object from database
  Future<int?> deleteLevel(int id, int dificulty) async {
    var db = await database;
    int result;
    if (dificulty == 0) {
      result = await db.rawDelete('DELETE FROM $gameTableBeg WHERE $id = $id');
      return result;
    } else if (dificulty == 1) {
      result = await db.rawDelete('DELETE FROM $gameTableInter WHERE $id = $id');
      return result;
    } else if (dificulty == 2) {
      result = await db.rawDelete('DELETE FROM $gameTableAdvance WHERE $id = $id');
      return result;
    }
    return null;
  }

  // Get number of level objects in database
  Future<int?> getCount(int dificulty) async {
    Database db = await database;
    String gameTable="";
    if (dificulty == 0) {
    gameTable=gameTableBeg;
    } else if (dificulty == 1) {
      gameTable=gameTableInter;
    } else if (dificulty == 2) {
      gameTable=gameTableAdvance;
    }
    List<Map<String, dynamic>> x = await db.rawQuery('SELECT COUNT (*) from $gameTable');
    int? result = Sqflite.firstIntValue(x);
    return result;
  }

  // Get the 'Map List' [ List<Map> ] and convert it to 'level List' [ List<levelItem> ]
  Future<List<LevelItem>> getLevelList(
    int dificulty,
  ) async {
    Database db = await database;
    var levelMapList =
        await getLevelMapList(dificulty); // Get 'Map List' from database
    int count =
        levelMapList.length; // Count the number of map entries in db table

    List<LevelItem> levelList = <LevelItem>[];
    // For loop to create a 'level List' from a 'Map List'
    for (int i = 0; i < count; i++) {
      levelList.add(LevelItem.fromMapObject(levelMapList[i]));
    }
    return levelList;
  }

  Future<LevelItem?> getLevel(int id, int dificulty) async {
    final db = await database;
    if (dificulty == 0) {
      final maps =
          await db.query(gameTableBeg, where: 'id = ?', whereArgs: [id]);
      return LevelItem.fromMapObject(maps[0]);
    } else if (dificulty == 1) {
      final maps =
          await db.query(gameTableInter, where: 'id = ?', whereArgs: [id]);
      return LevelItem.fromMapObject(maps[0]);
    } else if (dificulty == 2) {
      final maps =
          await db.query(gameTableAdvance, where: 'id = ?', whereArgs: [id]);
      return LevelItem.fromMapObject(maps[0]);
    }

    return null;
  }

  Future<int?> tableIsEmpty(int dificulty) async {
    Database db = await database;
    int? count;

    if (dificulty == 0) {
      count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $gameTableBeg'));
    } else if (dificulty == 1) {
      count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $gameTableInter'));
    } else if (dificulty == 2) {
      count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $gameTableAdvance'));
    }
    return count;
    //print(count);
  }

  Future<Object?> getLastItemId(int dificulty) async {
    Database db = await database;

    Object? lastId;

    if (dificulty == 0) {
      final data = await db.rawQuery('SELECT * FROM $gameTableBeg');
      lastId = data.last['id'];
    } else if (dificulty == 1) {
      final data = await db.rawQuery('SELECT * FROM $gameTableInter');
      lastId = data.last['id'];
    } else if (dificulty == 2) {
      final data = await db.rawQuery('SELECT * FROM $gameTableAdvance');
      lastId = data.last['id'];
    }
    return lastId;
  }
}
