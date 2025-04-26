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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showFirstMoveDialog();
    });
  }

  void showFirstMoveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 무조건 선택하게
      builder:
          (_) => AlertDialog(
            title: Text('선공 / 후공 선택'),
            content: Text('X (선공) 또는 O (후공)을 선택하세요.'),
            actions: [
              TextButton(
                child: Text('X (선공)'),
                onPressed: () {
                  setState(() {
                    currentPlayer = 'X';
                  });
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text('O (후공)'),
                onPressed: () {
                  setState(() {
                    currentPlayer = 'X'; // 기본은 X로 시작
                  });
                  Navigator.pop(context);
                  Future.delayed(
                    Duration(milliseconds: 500),
                    aiMove,
                  ); // 후공이면 AI가 먼저 둠
                },
              ),
            ],
          ),
    );
  }

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

  // 모든 판을 점수 1차 수정정
  int evaluateMove(int x, int y) {
    if (board[x][y] != '') return -1; // 이미 놓인 칸 무효

    int totalScore = 0;

    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      totalScore += evaluateDirection(x, y, dir[0], dir[1], 'O'); // 내 돌 평가
      totalScore += evaluateDirection(x, y, dir[0], dir[1], 'X'); // 상대 돌 평가
    }

    return totalScore;
  }

  int evaluateDirection(int x, int y, int dx, int dy, String player) {
    int count = 0;
    int openEnds = 0;

    // ➡️ 한쪽 방향 체크
    int nx = x + dx;
    int ny = y + dy;
    while (nx >= 0 && ny >= 0 && nx < boardSize && ny < boardSize) {
      if (board[nx][ny] == player) {
        count++;
        nx += dx;
        ny += dy;
      } else if (board[nx][ny] == '') {
        openEnds++;
        break;
      } else {
        break;
      }
    }

    // ⬅️ 반대 방향 체크
    nx = x - dx;
    ny = y - dy;
    while (nx >= 0 && ny >= 0 && nx < boardSize && ny < boardSize) {
      if (board[nx][ny] == player) {
        count++;
        nx -= dx;
        ny -= dy;
      } else if (board[nx][ny] == '') {
        openEnds++;
        break;
      } else {
        break;
      }
    }

    // ✨ 점수 부여
    if (player == 'O') {
      // 내 돌 평가
      if (count == 1 && openEnds == 1) return 20;
      if (count == 1 && openEnds == 2) return 80;
      if (count == 2 && openEnds == 1) return 300;
      if (count == 2 && openEnds == 2) return 800;
      if (count == 3 && openEnds == 1) return 5000;
      if (count == 3 && openEnds == 2) return 9000;
    } else if (player == 'X') {
      // 상대 돌 평가
      if (count == 1 && openEnds == 1) return 30;
      if (count == 1 && openEnds == 2) return 120;
      if (count == 2 && openEnds == 1) return 400;
      if (count == 2 && openEnds == 2) return 1200;
      if (count == 3 && openEnds == 1) return 7000;
      if (count == 3 && openEnds == 2) return 15000;
    }

    return 0;
  }

  void aiMove() {
    int bestScore = -1;
    int bestX = -1;
    int bestY = -1;

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        int score = evaluateMove(i, j);
        if (score > bestScore) {
          bestScore = score;
          bestX = i;
          bestY = j;
        }
      }
    }

    if (bestX != -1 && bestY != -1) {
      setState(() {
        board[bestX][bestY] = 'O';
        if (checkWin(bestX, bestY, 'O')) {
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
        } else {
          currentPlayer = 'X';
        }
      });
    } else {
      // 만약 둘 곳이 아예 없다면 (예외)
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
