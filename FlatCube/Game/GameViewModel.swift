//
//  GameViewModel.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import SwiftUI

final class GameViewModel: ObservableObject {
    @AppStorage("best_score") private var storedBestScore = 0
    
    @Published private(set) var board = Board()
    @Published private(set) var moves = 0
    @Published private(set) var isSolved = true
    @Published private(set) var bestScore = 0
    
    init() {
        bestScore = storedBestScore
        newGame()
    }

    func newGame() {
        board = Board()
        board.shuffle()
        moves = 0
        bestScore = storedBestScore
        isSolved = board.isSolved()
    }

    func reset() {
        board.reset()
        moves = 0
        bestScore = storedBestScore
        isSolved = board.isSolved()
    }

    func tile(row: Int, col: Int) -> Tile {
        board.tileAt(row: row, col: col)
    }

    func rowTiles(_ row: Int) -> [Tile] {
        (0..<9).map { board.tileAt(row: row, col: $0) }
    }

    func columnTiles(_ col: Int) -> [Tile] {
        (0..<9).map { board.tileAt(row: $0, col: col) }
    }

    func shiftRow(_ row: Int, by amount: Int) {
        guard !isSolved else { return }
        guard amount != 0 else { return }
        board.shiftRow(row, by: amount)
        moves += abs(amount)
        updateSolvedState()
    }

    func shiftColumn(_ col: Int, by amount: Int) {
        guard !isSolved else { return }
        guard amount != 0 else { return }
        
        board.shiftColumn(col, by: amount)
        moves += abs(amount)
        updateSolvedState()
    }

    private func updateSolvedState() {
        isSolved = board.isSolved()
        
        if isSolved {
            updateBestScoreIfNeeded()
        }
    }
    
    private func updateBestScoreIfNeeded() {
        if storedBestScore == 0 || moves < storedBestScore {
            storedBestScore = moves
        }
        
        bestScore = storedBestScore
    }
}
