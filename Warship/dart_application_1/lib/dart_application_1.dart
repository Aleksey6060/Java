import 'dart:io';
import 'dart:math';

enum CellState { empty, ship, hit, miss }

class Cell {
  CellState state = CellState.empty;
}

class Board {
  List<List<Cell>> grid = List.generate(3, (_) => List.generate(3, (_) => Cell()));

  bool tryPlaceShip(int row, int col) {
    if (row < 0 || row >= 3 || col < 0 || col >= 3) return false;
    var cell = grid[row][col];
    if (cell.state != CellState.empty) return false;
    cell.state = CellState.ship;
    return true;
  }

  (bool success, bool hit) tryAttack(int row, int col) {
    if (row < 0 || row >= 3 || col < 0 || col >= 3) return (false, false);
    var cell = grid[row][col];
    if (cell.state == CellState.hit || cell.state == CellState.miss) return (false, false);
    if (cell.state == CellState.ship) {
      cell.state = CellState.hit;
      return (true, true);
    } else {
      cell.state = CellState.miss;
      return (true, false);
    }
  }

  bool allShipsSunk() {
    for (var row in grid) {
      for (var cell in row) {
        if (cell.state == CellState.ship) return false;
      }
    }
    return true;
  }

  int getRemainingShips() {
    int count = 0;
    for (var row in grid) {
      for (var cell in row) {
        if (cell.state == CellState.ship) count++;
      }
    }
    return count;
  }

  @override
  String toString({bool showShips = true}) {
    String getDisplay(CellState state, bool showShips) {
      switch (state) {
        case CellState.hit:
          return 'X';
        case CellState.miss:
          return 'O';
        case CellState.ship:
          return showShips ? 'S' : '.';
        case CellState.empty:
          return '.';
      }
    }
    StringBuffer sb = StringBuffer();
    sb.writeln(' A B C');
    for (int r = 0; r < 3; r++) {
      sb.write('${r + 1} ');
      for (int c = 0; c < 3; c++) {
        String char = getDisplay(grid[r][c].state, showShips);
        sb.write('$char ');
      }
      sb.writeln();
    }
    return sb.toString();
  }
}

(int?, int?) parsePosition(String s) {
  if (s.length != 2) return (null, null);
  String letter = s[0].toUpperCase();
  int? col = 'ABC'.indexOf(letter);
  if (col == -1) return (null, null);
  int? rowNum = int.tryParse(s[1]);
  if (rowNum == null || rowNum < 1 || rowNum > 3) return (null, null);
  return (rowNum - 1, col);
}

abstract class Player {
  final String name;
  final Board board;
  Player(this.name) : board = Board();
  void placeShips();
  (int, int) getAttack(Board target);
}

class HumanPlayer extends Player {
  HumanPlayer(super.name);

  @override
  void placeShips() {
    print('$name, разместите 3 корабля. Вводите позиции вроде A1 (A-C, 1-3), без пересечений.');
    int placed = 0;
    while (placed < 3) {
      stdout.write('Корабль ${placed + 1}: ');
      String? posStr = stdin.readLineSync();
      var pos = parsePosition(posStr ?? '');
      if (pos != null) {
        if (!board.tryPlaceShip(pos.$1!, pos.$2!)) {
          print('Позиция занята или неверная. Попробуйте снова.');
          continue;
        }
        placed++;
        print('Корабль размещён на $posStr');
      } else {
        print('Неверная позиция. Попробуйте снова.');
        continue;
      }
    }
  }

  @override
  (int, int) getAttack(Board target) {
    while (true) {
      stdout.write('$name, введите позицию атаки (A1-C3): ');
      String? posStr = stdin.readLineSync();
      var pos = parsePosition(posStr ?? '');
      if (pos != null) {
        return (pos.$1!, pos.$2!);
      } else {
        print('Неверная позиция. Попробуйте снова.');
      }
    }
  }
}

class AIPlayer extends Player {
  AIPlayer(super.name);

  @override
  void placeShips() {
    Random rand = Random();
    int placed = 0;
    while (placed < 3) {
      int r = rand.nextInt(3);
      int c = rand.nextInt(3);
      if (board.tryPlaceShip(r, c)) {
        placed++;
      }
    }
    print('$name разместил корабли случайно.');
  }

  @override
  (int, int) getAttack(Board target) {
    List<(int, int)> available = [];
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        var cell = target.grid[r][c];
        if (cell.state != CellState.hit && cell.state != CellState.miss) {
          available.add((r, c));
        }
      }
    }
    if (available.isEmpty) {
      throw Exception('Нет доступных атак');
    }
    Random rand = Random();
    return available[rand.nextInt(available.length)];
  }
}

class SeaBattle {
  final Player player1;
  final Player player2;
  bool player1Turn = true;
  int player1Hits = 0;
  int player1Misses = 0;
  int player2Hits = 0;
  int player2Misses = 0;

  SeaBattle(this.player1, this.player2);

  void play() {
    player1.placeShips();
    player2.placeShips();
    print('\nИгра началась! Игрок 1 ходит первым.\n');

    while (!player1.board.allShipsSunk() && !player2.board.allShipsSunk()) {
      Player current = player1Turn ? player1 : player2;
      Board target = player1Turn ? player2.board : player1.board;
      print('\nХод ${current.name}.');
      
      if (current is HumanPlayer) {
        print('Ваше поле:\n${current.board.toString(showShips: true)}');
        print('Поле противника:\n${target.toString(showShips: false)}');
      }
      
      bool validAttack = false;
      (int, int) attackPos = (0, 0);
      while (!validAttack) {
        attackPos = current.getAttack(target);
        var result = target.tryAttack(attackPos.$1, attackPos.$2);
        if (!result.$1) {
          if (current is HumanPlayer) {
            print('Эта клетка уже атакована. Попробуйте другую.');
          } else {
            print('Ошибка ИИ: повторная атака.');
            continue;
          }
        } else {
          validAttack = true;
          if (result.$2) {
            if (player1Turn) {
              player1Hits++;
            } else {
              player2Hits++;
            }
            print('${current.name} попал! (X)');
            if (target.allShipsSunk()) {
              print('\n${current.name} победил! Все корабли противника потоплены.');
              print('Финальное поле противника:\n${target.toString(showShips: true)}');
              _saveStatistics(current.name);
              return;
            }
          } else {
            if (player1Turn) {
              player1Misses++;
            } else {
              player2Misses++;
            }
            print('${current.name} промахнулся! (O)');
          }
        }
      }
      
      if (current is AIPlayer) {
        String posStr = '${String.fromCharCode(65 + attackPos.$2)}${attackPos.$1 + 1}';
        print('ИИ атакует $posStr.');
      }
      player1Turn = !player1Turn;
    }
    
    String winner = player1.board.allShipsSunk() ? player2.name : player1.name;
    print('\n$winner победил!');
    _saveStatistics(winner);
  }

  void _saveStatistics(String winner) {
    // ✅ РАСЧЕТ СТАТИСТИКИ (остается тот же)
    int initialShips = 3;
    int player1Lost = initialShips - player1.board.getRemainingShips();
    int player2Lost = initialShips - player2.board.getRemainingShips();
    int player1Remaining = player1.board.getRemainingShips();
    int player2Remaining = player2.board.getRemainingShips();

    // ✅ ФОРМАТИРОВАНИЕ СТАТИСТИКИ
    String stats = '''
СТАТИСТИКА ИГРЫ МОРСКОЙ БОЙ 3x3
============================================
Дата: ${DateTime.now().toString().split('.')[0]}
Победитель: $winner

ИГРОК 1 (${player1.name}):
├─ Попадания: $player1Hits
├─ Промахи: $player1Misses  
├─ Потерянные корабли: $player1Lost
└─ Оставшиеся корабли: $player1Remaining / $initialShips

ИГРОК 2 (${player2.name}):
├─ Попадания: $player2Hits
├─ Промахи: $player2Misses
├─ Потерянные корабли: $player2Lost
└─ Оставшиеся корабли: $player2Remaining / $initialShips

Общая статистика:
├─ Всего ходов: ${player1Hits + player1Misses + player2Hits + player2Misses}
├─ Точность Игрока 1: ${player1Hits > 0 ? (player1Hits / (player1Hits + player1Misses) * 100).toStringAsFixed(1) : '0.0'}%
└─ Точность Игрока 2: ${player2Hits > 0 ? (player2Hits / (player2Hits + player2Misses) * 100).toStringAsFixed(1) : '0.0'}%
============================================
''';

    print(stats);

    // ✅ РАБОТА С КАТАЛОГАМИ И ФАЙЛАМИ ИЗ ЛЕКЦИИ
    
    // 1. Создание каталога "game_statistics" (из лекции: createSync с recursive)
    Directory statsDir = Directory('game_statistics');
    if (!statsDir.existsSync()) {  // ✅ Проверка существования (existsSync)
      statsDir.createSync(recursive: true);  // ✅ Создание каталога
      print('✅ Создан каталог: game_statistics');
    }

    // 2. Создание файла статистики с уникальным именем
    String fileName = 'game_${DateTime.now().millisecondsSinceEpoch}.txt';
    File statsFile = File('game_statistics/$fileName');

    // 3. Проверка, создан ли файл (existsSync)
    if (!statsFile.existsSync()) {
      statsFile.createSync();  // ✅ Создание файла (createSync)
      print('✅ Создан файл: $fileName');
    }

    // 4. Запись статистики (writeAsStringSync)
    statsFile.writeAsStringSync(stats);  // ✅ Синхронная запись строки
    
    // 5. Получение информации о файле (statSync, lengthSync)
    FileStat fileStat = statsFile.statSync();  // ✅ Информация о файле
    int fileSize = statsFile.lengthSync();     // ✅ Размер файла
    
    print('📁 Файл статистики сохранен:');
    print('   Путь: ${statsFile.path}');
    print('   Размер: $fileSize байт');
    print('   Дата создания: ${fileStat.type}');
    print('   Последняя модификация: ${fileStat.modified}');
    
    // 6. Дополнительно: исследование содержимого каталога (listSync)
    print('\n📂 Содержимое каталога game_statistics:');
    List<FileSystemEntity> files = statsDir.listSync();  // ✅ Список файлов
    for (var entity in files) {
      if (entity is File) {
        print('   📄 ${entity.uri.pathSegments.last}');
      }
    }
  }
}
