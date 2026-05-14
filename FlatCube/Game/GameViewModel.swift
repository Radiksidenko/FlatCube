//
//  GameViewModel.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import SwiftUI

final class GameViewModel: ObservableObject {
    @Published private(set) var board = Board()
    @Published private(set) var moves = 0
    @Published private(set) var isSolved = true

    init() {
        newGame()
    }

    func newGame() {
        board = Board()
        board.shuffle()
        moves = 0
        updateSolvedState()
    }

    func reset() {
        board.reset()
        moves = 0
        updateSolvedState()
    }

    func tile(row: Int, col: Int) -> Tile {
        board.tileAt(row: row, col: col)
    }

    func shiftRow(_ row: Int, by amount: Int) {
        guard amount != 0 else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            board.shiftRow(row, by: amount)
            moves += abs(amount)
            updateSolvedState()
        }
    }

    func shiftColumn(_ col: Int, by amount: Int) {
        guard amount != 0 else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            board.shiftColumn(col, by: amount)
            moves += abs(amount)
            updateSolvedState()
        }
    }

    private func updateSolvedState() {
        isSolved = board.isSolved()
    }
}
