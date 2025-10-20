import 'package:dart_application_1/dart_application_1.dart';
import 'package:test/test.dart';

void main() {
  test('Board creation', () {
    Board board = Board();
    expect(board.grid.length, 3);
    expect(board.grid[0].length, 3);
  });

  test('Ship placement', () {
    Board board = Board();
    expect(board.tryPlaceShip(0, 0), true);
    expect(board.tryPlaceShip(0, 0), false); // Already occupied
    expect(board.tryPlaceShip(-1, 0), false); // Out of bounds
  });

  test('Attack mechanics', () {
    Board board = Board();
    board.tryPlaceShip(0, 0);
    
    var result = board.tryAttack(0, 0);
    expect(result.$1, true); // Valid attack
    expect(result.$2, true); // Hit
    
    result = board.tryAttack(1, 1);
    expect(result.$1, true); // Valid attack
    expect(result.$2, false); // Miss
  });
}
