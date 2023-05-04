class PathItem {
  bool? topExistWall=false;
  bool? bottomExistWall=false;
  bool? leftExistWall=false;
  bool? rightExistWall=false;

  bool? isLast=false;
  bool? isFirst=false;

  int? row=0;
  int? column=0;

  PathItem({this.topExistWall, this.bottomExistWall, this.leftExistWall, this.rightExistWall,
      this.isLast, this.isFirst,this.row,this.column});
}
