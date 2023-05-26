import 'package:flutter/material.dart';

class LevelItem {
  int? _id;
  String _levelName = "";
  int _isOpen=0;
  int _row = 0;
  int _column = 0;
  int _count=0;
  int _stars=0;

  LevelItem(this._id,this._levelName, this._isOpen, this._row, this._column,this._count,this._stars);

  int? get id => _id;

  // Convert a Note object into a Map object
  Map<String, dynamic> toMap() {

    var map = Map<String, dynamic>();
    if (_id != null) {
      map['id'] = _id;
    }
    map['level_name'] = _levelName;
    map['isOpen'] = _isOpen;
    map['row'] = _row;
    map['column'] = _column;
    map['count'] = _count;
    map['stars'] = _stars;
    return map;
  }

  // Extract a Note object from a Map object
  LevelItem.fromMapObject(Map<String, dynamic> map) {
    this._id = map['id'];
    this.levelName = map['level_name'];
    this.isOpen=map['isOpen'];
    this.row = map['row'];
    this.column = map['column'];
    this.count = map['count'];
    this.stars = map['stars'];
  }

  String get levelName => _levelName;

  set levelName(String value) {
    _levelName = value;
  }

  int get isOpen => _isOpen;

  set isOpen(int value) {
    _isOpen = value;
  }

  int get row => _row;

  set row(int value) {
    _row = value;
  }

  int get column => _column;

  set column(int value) {
    _column = value;
  }

  int get count => _count;

  set count(int value) {
    _count = value;
  }

  int get stars => _stars;

  set stars(int value) {
    _stars = value;
  }
}
