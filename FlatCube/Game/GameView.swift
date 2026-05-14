//
//  GameView.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()

    @State private var activeLine: ActiveLine?
    @State private var dragOffset: CGSize = .zero

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 9)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                GeometryReader { geometry in
                    let side = min(geometry.size.width, geometry.size.height)
                    let spacing: CGFloat = 2
                    let padding: CGFloat = 8
                    let tileSize = (side - padding * 2 - spacing * 8) / 9
                    let step = tileSize + spacing

                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(0..<9, id: \.self) { row in
                            ForEach(0..<9, id: \.self) { col in
                                TileView(
                                    tile: viewModel.tile(row: row, col: col),
                                    row: row,
                                    col: col,
                                    size: tileSize
                                )
                                .offset(tileOffset(row: row, col: col))
                                .zIndex(zIndex(row: row, col: col))
                                .gesture(dragGesture(row: row, col: col, step: step))
                            }
                        }
                    }
                    .frame(width: side, height: side)
                    .padding(padding)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }

                controls

                if viewModel.isSolved {
                    Text("Solved!")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                Text("Drag like a slider: the farther you pull, the more cells shift.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Navigation Title")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Moves")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.moves)")
                    .font(.title2.bold())
            }

            Spacer()

            Button("New Game") {
                resetDragState(animated: false)
                viewModel.newGame()
            }
            .buttonStyle(.borderedProminent)

            Button("Reset") {
                resetDragState(animated: false)
                viewModel.reset()
            }
            .buttonStyle(.bordered)
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Text("Controls")
                .font(.headline)

            Text("Pull farther to move more than one cell.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func tileOffset(row: Int, col: Int) -> CGSize {
        guard let activeLine else { return .zero }

        switch activeLine {
        case .row(let activeRow) where activeRow == row:
            return CGSize(width: dragOffset.width, height: 0)
        case .column(let activeCol) where activeCol == col:
            return CGSize(width: 0, height: dragOffset.height)
        default:
            return .zero
        }
    }

    private func zIndex(row: Int, col: Int) -> Double {
        guard let activeLine else { return 0 }

        switch activeLine {
        case .row(let activeRow) where activeRow == row:
            return 1
        case .column(let activeCol) where activeCol == col:
            return 1
        default:
            return 0
        }
    }

    private func dragGesture(row: Int, col: Int, step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                if activeLine == nil {
                    activeLine = abs(dx) > abs(dy) ? .row(row) : .column(col)
                }

                guard let activeLine else { return }

                var transaction = Transaction(animation: .interactiveSpring(response: 0.18, dampingFraction: 0.9))
                transaction.disablesAnimations = false

                withTransaction(transaction) {
                    switch activeLine {
                    case .row(let activeRow) where activeRow == row:
                        dragOffset = CGSize(width: dx, height: 0)
                    case .column(let activeCol) where activeCol == col:
                        dragOffset = CGSize(width: 0, height: dy)
                    default:
                        break
                    }
                }
            }
            .onEnded { value in
                finishDrag(translation: value.translation,
                           predicted: value.predictedEndTranslation,
                           step: step)
            }
    }

    private func finishDrag(translation: CGSize, predicted: CGSize, step: CGFloat) {
        guard let activeLine else { return }

        let axisValue: CGFloat
        let predictedAxisValue: CGFloat

        switch activeLine {
        case .row:
            axisValue = translation.width
            predictedAxisValue = predicted.width
        case .column:
            axisValue = translation.height
            predictedAxisValue = predicted.height
        }

        let blended = axisValue * 0.7 + predictedAxisValue * 0.3
        var steps = Int((blended / step).rounded())

        steps = max(-8, min(8, steps))

        if steps == 0 {
            resetDragState(animated: true)
            return
        }

        let snappedOffset = CGFloat(steps) * step

        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.82)) {
            switch activeLine {
            case .row:
                dragOffset = CGSize(width: snappedOffset, height: 0)
            case .column:
                dragOffset = CGSize(width: 0, height: snappedOffset)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            apply(steps: steps)
            resetDragState(animated: false)
        }
    }

    private func apply(steps: Int) {
        guard let activeLine else { return }

        switch activeLine {
        case .row(let row):
            viewModel.shiftRow(row, by: steps)
        case .column(let col):
            viewModel.shiftColumn(col, by: steps)
        }
    }

    private func resetDragState(animated: Bool) {
        let changes = {
            dragOffset = .zero
            activeLine = nil
        }

        if animated {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.86)) {
                changes()
            }
        } else {
            changes()
        }
    }
}

enum ActiveLine: Equatable {
    case row(Int)
    case column(Int)
}

struct TileView: View {
    let tile: Tile
    let row: Int
    let col: Int
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(tile.color.color.gradient)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(tile.color.accessibilityName), row \(row + 1), column \(col + 1)")
            .accessibilityHint("Drag horizontally to move row or vertically to move column")
    }
}
