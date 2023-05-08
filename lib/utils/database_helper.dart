import 'package:custom_mazeapp/models/level/level_item.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {

  static DatabaseHelper? _databaseHelper;    // Singleton DatabaseHelper
  static Database? _database;                // Singleton Database

  String gameTable = 'game_level';
  String id = 'id';
  String levelname = 'level_name';
  String isOpen = 'isOpen';
  String row = 'row';
  String column = 'column';
  String count = 'count';

  DatabaseHelper._createInstance(); // Named constructor to create instance of DatabaseHelper

  factory DatabaseHelper() {
    return _databaseHelper ??= DatabaseHelper._createInstance();
  }

  Future<Database> get database async {
    return  _database ??= await initializeDatabase();
  }

  Future<Database> initializeDatabase() async {
    // Get the directory path for both Android and iOS to store database.
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}level.db';

    // Open/create the database at a given path
    var notesDatabase = await openDatabase(path, version: 1, onCreate: _createDb);
    return notesDatabase;
  }

  void _createDb(Database db, int newVersion) async {

    await db.execute('CREATE TABLE $gameTable($id INTEGER PRIMARY KEY AUTOINCREMENT, $levelname TEXT, '
        '$isOpen BOOLEAN,$row INTEGER, $column INTEGER, $count INTEGER)');
  }

  // Fetch Operation: Get all level objects from database
  Future<List<Map<String, dynamic>>> getLevelMapList() async {
    Database db = await database;

//		var result = await db.rawQuery('SELECT * FROM $levelTable order by $colPriority ASC');
    var result = await db.query(gameTable);
    return result;
  }

  // Insert Operation: Insert a level object to database
  Future<int> insertLevel(LevelItem level) async {
    Database db = await database;
    var result = await db.insert(gameTable, level.toMap());
    return result;
  }

  // Update Operation: Update a level object and save it to database
  void updateLevel(int id) async {
    var db = await database;
    var result=await db.rawQuery("UPDATE $gameTable SET isOpen=1 WHERE id=" + id.toString());
  }

  // Delete Operation: Delete a level object from database
  Future<int> deleteLevel(int id) async {
    var db = await database;
    int result = await db.rawDelete('DELETE FROM $gameTable WHERE $id = $id');
    return result;
  }

  // Get number of level objects in database
  Future<int?> getCount() async {
    Database db = await database;
    List<Map<String, dynamic>> x = await db.rawQuery('SELECT COUNT (*) from $gameTable');
    int? result = Sqflite.firstIntValue(x);
    return result;
  }

  // Get the 'Map List' [ List<Map> ] and convert it to 'level List' [ List<levelItem> ]
  Future<List<LevelItem>> getLevelList() async {
    Database db = await database;
    var levelMapList = await getLevelMapList(); // Get 'Map List' from database
    int count = levelMapList.length;         // Count the number of map entries in db table

    List<LevelItem> levelList = <LevelItem>[];
    // For loop to create a 'level List' from a 'Map List'
    for (int i = 0; i < count; i++) {
      levelList.add(LevelItem.fromMapObject(levelMapList[i]));
    }
    return levelList;
  }


  Future<LevelItem> getLevel(int id) async {
    final db = await database;
    final maps = await db.query(gameTable, where: 'id = ?', whereArgs: [id]);
    return LevelItem.fromMapObject(maps[0]);

  }




  Future<int?> tableIsEmpty() async{
    Database db = await database;
    int? count = Sqflite
        .firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $gameTable'));
    return count;
    //print(count);
  }


  Future<Object?> getLastItemId() async{
    Database db = await database;
    final data = await db.rawQuery('SELECT * FROM $gameTable');
    Object? lastId = data.last['id'];

    return lastId;
}


}
