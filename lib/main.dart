import 'package:flutter/material.dart';

void main() => runApp(GomokuApp());

class GomokuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: GomokuBoard());
  }
}

class GomokuBoard extends StatefulWidget {
  @override
  _GomokuBoardState createState() => _GomokuBoardState();
}

class _GomokuBoardState extends State<GomokuBoard> {
  static const int boardSize = 10;
  List<List<String>> board = List.generate(
    boardSize,
    (_) => List.filled(boardSize, ''),
  );
  String currentPlayer = 'X';

  void handleTap(int x, int y) {
    if (board[x][y] != '') return;

    setState(() {
      board[x][y] = currentPlayer;
      if (checkWin(x, y, currentPlayer)) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text('🎉 $currentPlayer 승리!'),
                actions: [
                  TextButton(
                    child: Text('다시 시작'),
                    onPressed: () {
                      Navigator.pop(context);
                      resetBoard();
                    },
                  ),
                ],
              ),
        );
      } else {
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
      }
    });
  }

  bool checkWin(int x, int y, String player) {
    int count(int dx, int dy) {
      int cnt = 0;
      int nx = x + dx, ny = y + dy;
      while (nx >= 0 &&
          ny >= 0 &&
          nx < boardSize &&
          ny < boardSize &&
          board[nx][ny] == player) {
        cnt++;
        nx += dx;
        ny += dy;
      }
      return cnt;
    }

    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      int total = 1 + count(dir[0], dir[1]) + count(-dir[0], -dir[1]);
      if (total >= 5) return true;
    }

    return false;
  }

  void resetBoard() {
    setState(() {
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      currentPlayer = 'X';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('오목 게임')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: boardSize * boardSize,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: boardSize,
          ),
          itemBuilder: (context, index) {
            int x = index ~/ boardSize;
            int y = index % boardSize;
            return GestureDetector(
              onTap: () => handleTap(x, y),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                ),
                child: Center(
                  child: Text(
                    board[x][y],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
