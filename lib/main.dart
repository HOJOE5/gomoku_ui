import 'package:flutter/material.dart';

void main() => runApp(GomokuApp());

class GomokuApp extends StatelessWidget {
  const GomokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: GomokuBoard());
  }
}

class GomokuBoard extends StatefulWidget {
  const GomokuBoard({super.key});

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
    if (board[x][y] != '' || currentPlayer != 'X') return;

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
        currentPlayer = 'O';
        Future.delayed(Duration(milliseconds: 500), aiMove);
      }
    });
  }

  void aiMove() {
    bool moved = false;

    // 1순위: 내가 이길 수 있는 자리 찾기
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == '') {
          board[i][j] = 'O';
          if (checkWin(i, j, 'O')) {
            setState(() {
              board[i][j] = 'O';
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: Text('🎉 O 승리!'),
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
            });
            moved = true;
            return;
          }
          board[i][j] = '';
        }
      }
    }

    // 2순위: 상대가 이길 수 있는 자리 막기
    if (!moved) {
      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          if (board[i][j] == '' && canEnemyWinIfPlaced(i, j)) {
            setState(() {
              board[i][j] = 'O';
              currentPlayer = 'X';
            });
            moved = true;
            return;
          }
        }
      }
    }

    // 3순위: 주변에 돌이 있는 곳에 둔다
    if (!moved) {
      List<List<int>> candidateMoves = [];

      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          if (board[i][j] == '' && hasNeighbor(i, j)) {
            candidateMoves.add([i, j]);
          }
        }
      }

      if (candidateMoves.isNotEmpty) {
        candidateMoves.shuffle();
        var move = candidateMoves.first;

        setState(() {
          board[move[0]][move[1]] = 'O';
          currentPlayer = 'X';
        });
        moved = true;
        print('📍 주변 돌 근처에 둠: (${move[0]}, ${move[1]})');
        return;
      }
    }

    if (!moved) {
      // 더 이상 둘 곳이 없는 경우
      setState(() {
        currentPlayer = 'X';
      });
    }
  }

  bool canEnemyWinIfPlaced(int x, int y) {
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      int count = 1;

      int nx = x + dir[0], ny = y + dir[1];
      while (nx >= 0 &&
          ny >= 0 &&
          nx < boardSize &&
          ny < boardSize &&
          board[nx][ny] == 'X') {
        count++;
        nx += dir[0];
        ny += dir[1];
      }

      nx = x - dir[0];
      ny = y - dir[1];
      while (nx >= 0 &&
          ny >= 0 &&
          nx < boardSize &&
          ny < boardSize &&
          board[nx][ny] == 'X') {
        count++;
        nx -= dir[0];
        ny -= dir[1];
      }

      if (count >= 5) return true;
    }

    return false;
  }

  bool hasNeighbor(int x, int y) {
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
      [0, -1],
      [-1, 0],
      [-1, -1],
      [-1, 1],
    ];

    for (var dir in directions) {
      int nx = x + dir[0];
      int ny = y + dir[1];

      if (nx >= 0 && ny >= 0 && nx < boardSize && ny < boardSize) {
        if (board[nx][ny] != '') {
          return true;
        }
      }
    }

    return false;
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
      if (1 + count(dir[0], dir[1]) + count(-dir[0], -dir[1]) >= 5) {
        return true;
      }
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
