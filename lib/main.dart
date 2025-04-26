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

  //사람이 클릭햇을 때 동작 함수수
  void handleTap(int x, int y) {
    if (board[x][y] != '' || currentPlayer != 'X') return;

    print('📌 사람이 $x, $y 클릭');

    bool hasWinner = false;

    setState(() {
      board[x][y] = currentPlayer;
      if (checkWin(x, y, currentPlayer)) {
        hasWinner = true;
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
      }
    });

    if (!hasWinner) {
      print('🕑 AI 호출 대기...');
      Future.delayed(Duration(milliseconds: 500), () {
        aiMove();
      });
    }
  }

  // AI 구동 함수수
  void aiMove() {
    print('🧠 AI 작동 시작! (1, 2순위 적용)');

    bool moved = false;
    bool canEnemyWinIfPlaced(int x, int y) {
      const directions = [
        [0, 1], // 가로 →
        [1, 0], // 세로 ↓
        [1, 1], // 대각 ↘
        [1, -1], // 대각 ↙
      ];

      for (var dir in directions) {
        int count = 1; // 지금 놓을 (x, y) 포함해서 시작

        // ➡️ 한 방향으로
        int nx = x + dir[0];
        int ny = y + dir[1];
        while (nx >= 0 &&
            ny >= 0 &&
            nx < boardSize &&
            ny < boardSize &&
            board[nx][ny] == 'X') {
          count++;
          nx += dir[0];
          ny += dir[1];
        }

        // ⬅️ 반대 방향으로
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

        if (count >= 5) {
          return true;
        }
      }

      return false;
    }

    // 1순위: 내가 이길 수 있는 자리 찾기
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == '') {
          board[i][j] = 'O';
          bool willWin = checkWin(i, j, 'O');
          board[i][j] = '';

          if (willWin) {
            setState(() {
              board[i][j] = 'O';
              if (checkWin(i, j, 'O')) {
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
            moved = true;
            return;
          }
        }
      }
    }

    // 2순위: 상대가 이길 수 있는 자리 막기
    if (!moved) {
      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          if (board[i][j] == '' && canEnemyWinIfPlaced(i, j)) {
            setState(() {
              board[i][j] = 'O'; // 막는다
              currentPlayer = 'X'; // 다시 사람 차례
            });
            print('🛡️ 상대방 승리 막기 성공!');
            return;
          }
        }
      }
    }

    // 1, 2순위 모두 실패한 경우 턴 넘기기
    print('😶 이길 곳도 막을 곳도 없음. (현재 1, 2순위까지만)');
    setState(() {
      currentPlayer = 'X';
    });
  }

  // 승리 체크 함수
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

  // 게임을 초기화 하는 함수수
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
