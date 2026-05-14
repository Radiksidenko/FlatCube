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
    @State private var overlayTiles: [Tile] = []

    private let cellSpacing: CGFloat = 2
    private let blockSpacing: CGFloat = 10
    private let boardPadding: CGFloat = 8

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                GeometryReader { geometry in
                    let side = min(geometry.size.width, geometry.size.height)
                    let totalSpacing = cellSpacing * 6 + blockSpacing * 2
                    let tileSize = max(0, (side - boardPadding * 2 - totalSpacing) / 9)
                    let logicalStep = tileSize + cellSpacing
                    let boardSize = tileSize * 9 + totalSpacing
                    let boardOrigin = CGPoint(x: boardPadding, y: boardPadding)

                    ZStack(alignment: .topLeading) {
                        boardGrid(tileSize: tileSize, logicalStep: logicalStep)
                            .padding(boardPadding)

                        overlayLayer(
                            tileSize: tileSize,
                            logicalStep: logicalStep,
                            boardOrigin: boardOrigin,
                            boardSize: boardSize
                        )
                    }
                    .frame(width: side, height: side)
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
            }
            .padding()
            .navigationTitle("Flat Cube")
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
                clearOverlayState()
                viewModel.newGame()
            }
            .buttonStyle(.borderedProminent)

            Button("Reset") {
                clearOverlayState()
                viewModel.reset()
            }
            .buttonStyle(.bordered)
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Text("Controls")
                .font(.headline)
            Text("Drag rows or columns.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func boardGrid(tileSize: CGFloat, logicalStep: CGFloat) -> some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<9, id: \.self) { col in
                        TileView(
                            tile: viewModel.tile(row: row, col: col),
                            row: row,
                            col: col,
                            size: tileSize
                        )
                        .opacity(isTileHidden(row: row, col: col) ? 0 : 1)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(row: row, col: col, logicalStep: logicalStep))

                        if col == 2 || col == 5 {
                            Color.clear.frame(width: blockSpacing)
                        }
                    }
                }

                if row == 2 || row == 5 {
                    Color.clear.frame(height: blockSpacing)
                }
            }
        }
    }

    @ViewBuilder
    private func overlayLayer(
        tileSize: CGFloat,
        logicalStep: CGFloat,
        boardOrigin: CGPoint,
        boardSize: CGFloat
    ) -> some View {
        guard let line = activeLine, !overlayTiles.isEmpty else { return EmptyView() }

        switch line {
        case .row(let row):
            return MovingLineOverlay(
                tiles: overlayTiles,
                axis: .horizontal,
                fixedIndex: row,
                tileSize: tileSize,
                boardSize: boardSize,
                origin: boardOrigin,
                translation: dragOffset.width,
                logicalStep: logicalStep,
                cellSpacing: cellSpacing,
                blockSpacing: blockSpacing
            )
            .zIndex(2)

        case .column(let col):
            return MovingLineOverlay(
                tiles: overlayTiles,
                axis: .vertical,
                fixedIndex: col,
                tileSize: tileSize,
                boardSize: boardSize,
                origin: boardOrigin,
                translation: dragOffset.height,
                logicalStep: logicalStep,
                cellSpacing: cellSpacing,
                blockSpacing: blockSpacing
            )
            .zIndex(2)
        }
    }

    private func dragGesture(row: Int, col: Int, logicalStep: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                if activeLine == nil {
                    activeLine = abs(dx) > abs(dy) ? .row(row) : .column(col)
                    overlayTiles = snapshotTiles(for: activeLine)
                }

                guard let activeLine else { return }

                switch activeLine {
                case .row(let activeRow) where activeRow == row:
                    dragOffset = CGSize(width: dx, height: 0)

                case .column(let activeCol) where activeCol == col:
                    dragOffset = CGSize(width: 0, height: dy)

                default:
                    break
                }
            }
            .onEnded { value in
                finishDrag(
                    translation: value.translation,
                    predicted: value.predictedEndTranslation,
                    logicalStep: logicalStep
                )
            }
    }

    private func finishDrag(translation: CGSize, predicted: CGSize, logicalStep: CGFloat) {
        guard let activeLine else { return }

        let raw: CGFloat
        let predictedRaw: CGFloat

        switch activeLine {
        case .row:
            raw = translation.width
            predictedRaw = predicted.width
        case .column:
            raw = translation.height
            predictedRaw = predicted.height
        }

        let blended = raw * 0.75 + predictedRaw * 0.25
        let steps = snappedStepCount(for: blended, logicalStep: logicalStep)

        if steps == 0 {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.88)) {
                dragOffset = .zero
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                clearOverlayState()
            }
            return
        }

        let snapped = snappedOffset(for: steps, logicalStep: logicalStep)

        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.84)) {
            switch activeLine {
            case .row:
                dragOffset = CGSize(width: snapped, height: 0)
            case .column:
                dragOffset = CGSize(width: 0, height: snapped)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            apply(steps: steps)
            clearOverlayState()
        }
    }

    private func snappedStepCount(for translation: CGFloat, logicalStep: CGFloat) -> Int {
        let steps = Int((translation / logicalStep).rounded())
        return max(-4, min(4, steps))
    }

    private func snappedOffset(for steps: Int, logicalStep: CGFloat) -> CGFloat {
        CGFloat(steps) * logicalStep
    }

    private func isTileHidden(row: Int, col: Int) -> Bool {
        guard let line = activeLine else { return false }

        switch line {
        case .row(let activeRow):
            return row == activeRow
        case .column(let activeCol):
            return col == activeCol
        }
    }

    private func snapshotTiles(for line: ActiveLine?) -> [Tile] {
        guard let line else { return [] }

        switch line {
        case .row(let row):
            return viewModel.rowTiles(row)
        case .column(let col):
            return viewModel.columnTiles(col)
        }
    }

    private func apply(steps: Int) {
        guard let line = activeLine else { return }

        switch line {
        case .row(let row):
            viewModel.shiftRow(row, by: steps)
        case .column(let col):
            viewModel.shiftColumn(col, by: steps)
        }
    }

    private func clearOverlayState() {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            activeLine = nil
            dragOffset = .zero
            overlayTiles = []
        }
    }
}

enum ActiveLine: Equatable {
    case row(Int)
    case column(Int)
}

enum OverlayAxis {
    case horizontal
    case vertical
}

struct MovingLineOverlay: View {
    let tiles: [Tile]
    let axis: OverlayAxis
    let fixedIndex: Int
    let tileSize: CGFloat
    let boardSize: CGFloat
    let origin: CGPoint
    let translation: CGFloat
    let logicalStep: CGFloat
    let cellSpacing: CGFloat
    let blockSpacing: CGFloat

    private var lineLength: CGFloat {
        tileSize * 9 + cellSpacing * 6 + blockSpacing * 2
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            tileCopies(shift: -lineLength)
            tileCopies(shift: 0)
            tileCopies(shift: lineLength)
        }
        .frame(width: boardSize + origin.x * 2, height: boardSize + origin.y * 2, alignment: .topLeading)
        .clipped()
    }

    @ViewBuilder
    private func tileCopies(shift: CGFloat) -> some View {
        ForEach(0..<9, id: \.self) { index in
            TileOverlayCell(tile: tiles[index], size: tileSize)
                .position(position(for: index, shift: shift))
        }
    }

    private func position(for movingIndex: Int, shift: CGFloat) -> CGPoint {
        let movingLeading = leadingOffset(for: movingIndex)
        let fixedLeading = leadingOffset(for: fixedIndex)
        let edgeOffset: CGFloat = shift == 0 ? 0 : (shift > 0 ? origin.x : -origin.x)

        let fixedAxisCorrection = CGFloat(fixedIndex / 3) * 4

        switch axis {
        case .horizontal:
            return CGPoint(
                x: origin.x + movingLeading + translation + shift + edgeOffset + tileSize / 2,
                y: origin.y + fixedLeading + fixedAxisCorrection + tileSize / 2
            )

        case .vertical:
            return CGPoint(
                x: origin.x + fixedLeading + fixedAxisCorrection + tileSize / 2,
                y: origin.y + movingLeading + translation + shift + edgeOffset + tileSize / 2
            )
        }
    }

    private func leadingOffset(for index: Int) -> CGFloat {
        let blockJumps = index / 3
        let normalGaps = index - blockJumps

        return CGFloat(index) * tileSize
            + CGFloat(normalGaps) * cellSpacing
            + CGFloat(blockJumps) * blockSpacing
    }
}

struct TileOverlayCell: View {
    let tile: Tile
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
    }
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
