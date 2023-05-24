import 'dart:async';
import 'dart:ui' as ui;
import 'package:custom_mazeapp/models/cell.dart';
import 'package:custom_mazeapp/models/path_item.dart';
import 'package:custom_mazeapp/screens/maze_screen.dart';
import 'package:custom_mazeapp/utils/MazeSolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:universal_io/io.dart';
import 'maze_painter.dart';
import 'models/item.dart';

///Maze
///
///Create a simple but powerfull maze game
///You can customize [pointColor],[wallColor], [wallThickness],
///[columns] and [rows]. A [player] is required and also
///you can pass a List of [checkpoints] and you will be notified
///if the player pass through a checkout at [onCheckpoint]
class Maze extends StatefulWidget {
  ///Default constructor
  Maze(
      {required this.player,
        required this.playerUp,
        required this.playerDown,
        required this.playerLeft,
        required this.playerRight,
      this.checkpoints = const [],
      this.columns = 10,
      this.finish,
      this.height,
      this.loadingWidget,
      this.onCheckpoint,
      this.onFinish,
      this.onDrawPath,
      this.rows = 7,
      this.wallColor = Colors.black,
      this.pointColor = Colors.black,
      this.wallThickness = 3.0,
      this.width,
      this.sel = 0,
      required this.playerColor});

  int sel;
  Color playerColor;

  ///List of checkpoints
  final List<MazeItem> checkpoints;

  ///Columns of the maze
  final int columns;

  ///The finish image
  final MazeItem? finish;

  ///Height of the maze
  final double? height;

  ///A widget to show while loading all
  final Widget? loadingWidget;

  ///Callback when the player pass through a checkpoint
  final Function(int)? onCheckpoint;

  ///Callback when the player reach finish
  final Function()? onFinish;
  final Function(List<PathItem>)? onDrawPath;

  ///The main player
  final MazeItem player;

  final MazeItem playerLeft;
  final MazeItem playerRight;
  final MazeItem playerUp;
  final MazeItem playerDown;






  ///Rows of the maze
  final int rows;

  ///Wall color
  final Color? wallColor;
  final Color? pointColor;

  ///Wall thickness
  ///
  ///Default: 3.0
  final double? wallThickness;

  ///Width of the maze
  final double? width;

  @override
  MazeState createState() => MazeState();
}

class MazeState extends State<Maze> {
  bool _loaded = false;
  MazePainter? _mazePainter;
  List<PathItem> listPath = [];
  bool isDrawSelect = false;


  @override
  void initState() {
    super.initState();
    setUp();
  }

  void solutionDraw() async {
    _mazePainter?.isSolSelect = true;
    _mazePainter?.solution = await _mazePainter?.computeSolutionPath(Cell(0, 0));
    _mazePainter?.notifyListeners();
  }

  void setUp() async {
    final playerImage = await _itemToImage(widget.player);
    final playerImageUp = await _itemToImage(widget.playerUp);
    final playerImageDown = await _itemToImage(widget.playerDown);
    final playerImageLeft = await _itemToImage(widget.playerLeft);
    final playerImageRight = await _itemToImage(widget.playerRight);

    final checkpoints = await Future.wait(
        widget.checkpoints.map((c) async => await _itemToImage(c)));
    final finishImage =
        widget.finish != null ? await _itemToImage(widget.finish!) : null;

    _mazePainter = MazePainter(
      checkpointsImages: checkpoints,
      columns: widget.columns,
      finishImage: finishImage,
      onCheckpoint: widget.onCheckpoint,
      onFinish: widget.onFinish,
      onDrawPath: widget.onDrawPath,
      playerImage: playerImage,
      playerImageUp: playerImageUp,
      playerImageDown: playerImageDown,
      playerImageLeft: playerImageLeft,
      playerImageRight: playerImageRight,
      playerColor: widget.playerColor,
      rows: widget.rows,
      wallColor: widget.wallColor ?? Colors.black,
      wallThickness: widget.wallThickness ?? 4.0,
    );
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sel==0) {
        _mazePainter?.removeSolution();
      } else {
        solutionDraw();
      }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Container(child: Builder(builder: (context) {
        if (_loaded) {
          return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (info) async {
                _mazePainter?.updatePosition(info.localPosition);
                // _mazePainter.solution =await _mazePainter.computeSolutionPath(Cell(0, 0));
                _mazePainter?.notifyListeners();
              },
              child: Container(
                child: Stack(
                  children: [
                    CustomPaint(
                        painter: _mazePainter,
                        size: Size(widget.width ?? context.width,
                            widget.height ?? context.height)),
                  ],
                ),
              ));
        } else {
          if (widget.loadingWidget != null) {
            return widget.loadingWidget!;
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      })),
    );
  }

  Future<ui.Image> _itemToImage(MazeItem item) {
    switch (item.type) {
      case ImageType.file:
        return _fileToByte(item.path);
      case ImageType.network:
        return _networkToByte(item.path);
      default:
        return _assetToByte(item.path);
    }
  }

  /// Creates a Image from file
  Future<ui.Image> _fileToByte(String path) async {
    final completer = Completer<ui.Image>();
    final bytes = await File(path).readAsBytes();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  /// Creates a Image from asset
  Future<ui.Image> _assetToByte(String asset) async {
    final completer = Completer<ui.Image>();
    final bytes = await rootBundle.load(asset);
    ui.decodeImageFromList(bytes.buffer.asUint8List(), completer.complete);
    return completer.future;
  }

  /// Creates a Image from network
  Future<ui.Image> _networkToByte(String url) async {
    final completer = Completer<ui.Image>();
    final response = await http.get(Uri.parse(url));
    ui.decodeImageFromList(
        response.bodyBytes.buffer.asUint8List(), completer.complete);
    return completer.future;
  }
}

/// Extension to get screen size
extension ScreenSizeExtension on BuildContext {
  /// Gets the current height
  double get height => MediaQuery.of(this).size.height;

  /// Gets the current width
  double get width => MediaQuery.of(this).size.width;
}
