import 'dart:io';
import 'package:dart_application_1/dart_application_1.dart';

void main() {
  print('=== Простой Морской бой 3x3 ===');
  print('У каждого по 3 одноклеточным кораблям.');
  print('Режимы: 1 - vs ИИ, 2 - vs Игрок');
  stdout.write('Выберите режим (1 или 2): ');
  String? input = stdin.readLineSync();
  
  Player p1 = HumanPlayer('Игрок 1');
  Player p2;
  if (input == '1') {
    p2 = AIPlayer('ИИ');
  } else if (input == '2') {
    p2 = HumanPlayer('Игрок 2');
  } else {
    print('❌ Неверный выбор. Запустите заново.');
    return;
  }
  
  SeaBattle game = SeaBattle(p1, p2);
  game.play();
}
