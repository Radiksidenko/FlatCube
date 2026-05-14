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
                    let boardOrigin = CGPoint(x: padding, y: padding)

                    ZStack(alignment: .topLeading) {
                        boardGrid(tileSize: tileSize, spacing: spacing, step: step)
                            .padding(padding)
//                        
//                        BlockSeparators(step: step, tileSize: tileSize)
//                            .padding(padding)
//                            .allowsHitTesting(false)
                        
                        overlayLayer(
                            tileSize: tileSize,
                            spacing: spacing,
                            step: step,
                            boardOrigin: boardOrigin
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

                Text("Simplified release logic without fade handoff.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Flat Cube")
        }
    }

    private func boardGrid(tileSize: CGFloat, spacing: CGFloat, step: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<9, id: \.self) { row in
                ForEach(0..<9, id: \.self) { col in
                    let hidden = isTileHidden(row: row, col: col)

                    TileView(
                        tile: viewModel.tile(row: row, col: col),
                        row: row,
                        col: col,
                        size: tileSize
                    )
                    .opacity(hidden ? 0 : 1)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(row: row, col: col, step: step))
                }
            }
        }
    }

    @ViewBuilder
    private func overlayLayer(
        tileSize: CGFloat,
        spacing: CGFloat,
        step: CGFloat,
        boardOrigin: CGPoint
    ) -> some View {
        if let line = activeLine, !overlayTiles.isEmpty {
            switch line {
            case .row(let row):
                let y = boardOrigin.y + CGFloat(row) * step
                SeamlessRowOverlay(
                    tiles: overlayTiles,
                    tileSize: tileSize,
                    spacing: spacing,
                    visibleLength: step * 9 - spacing,
                    offsetX: dragOffset.width
                )
                .frame(width: step * 9 - spacing, height: tileSize)
                .position(
                    x: boardOrigin.x + (step * 9 - spacing) / 2,
                    y: y + tileSize / 2
                )
                .zIndex(2)

            case .column(let col):
                let x = boardOrigin.x + CGFloat(col) * step
                SeamlessColumnOverlay(
                    tiles: overlayTiles,
                    tileSize: tileSize,
                    spacing: spacing,
                    visibleLength: step * 9 - spacing,
                    offsetY: dragOffset.height
                )
                .frame(width: tileSize, height: step * 9 - spacing)
                .position(
                    x: x + tileSize / 2,
                    y: boardOrigin.y + (step * 9 - spacing) / 2
                )
                .zIndex(2)
            }
        } else {
            EmptyView()
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
                cancelOverlayState()
                viewModel.newGame()
            }
            .buttonStyle(.borderedProminent)

            Button("Reset") {
                cancelOverlayState()
                viewModel.reset()
            }
            .buttonStyle(.bordered)
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Text("Controls")
                .font(.headline)

            Text("Drag farther to move more cells.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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

    private func dragGesture(row: Int, col: Int, step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6)
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
                    dragOffset = CGSize(width: value.translation.width, height: 0)

                case .column(let activeCol) where activeCol == col:
                    dragOffset = CGSize(width: 0, height: value.translation.height)

                default:
                    break
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
        var steps = Int((blended / step).rounded())

        if steps == 0 {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.88)) {
                dragOffset = .zero
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                clearOverlayState()
            }
            return
        }

        steps = normalizedSteps(steps)
        let snapped = CGFloat(steps) * step

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

    private func clearOverlayState() {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            activeLine = nil
            dragOffset = .zero
            overlayTiles = []
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

    private func normalizedSteps(_ steps: Int) -> Int {
        var value = steps % 9
        if value > 4 { value -= 9 }
        if value < -4 { value += 9 }
        return value
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

    private func cancelOverlayState() {
        clearOverlayState()
    }
}

enum ActiveLine: Equatable {
    case row(Int)
    case column(Int)
}

struct SeamlessRowOverlay: View {
    let tiles: [Tile]
    let tileSize: CGFloat
    let spacing: CGFloat
    let visibleLength: CGFloat
    let offsetX: CGFloat

    private var segmentLength: CGFloat {
        CGFloat(tiles.count) * (tileSize + spacing) - spacing
    }

    private var repeatedTiles: [Tile] {
        tiles + tiles + tiles
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(repeatedTiles.enumerated()), id: \.offset) { _, tile in
                TileOverlayCell(tile: tile, size: tileSize)
            }
        }
        .offset(x: wrappedOffset(base: offsetX) - segmentLength)
        .frame(width: visibleLength, height: tileSize, alignment: .leading)
        .clipped()
    }

    private func wrappedOffset(base: CGFloat) -> CGFloat {
        var x = base.truncatingRemainder(dividingBy: segmentLength)
        if x < 0 { x += segmentLength }
        return x
    }
}

struct SeamlessColumnOverlay: View {
    let tiles: [Tile]
    let tileSize: CGFloat
    let spacing: CGFloat
    let visibleLength: CGFloat
    let offsetY: CGFloat

    private var segmentLength: CGFloat {
        CGFloat(tiles.count) * (tileSize + spacing) - spacing
    }

    private var repeatedTiles: [Tile] {
        tiles + tiles + tiles
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(repeatedTiles.enumerated()), id: \.offset) { _, tile in
                TileOverlayCell(tile: tile, size: tileSize)
            }
        }
        .offset(y: wrappedOffset(base: offsetY) - segmentLength)
        .frame(width: tileSize, height: visibleLength, alignment: .top)
        .clipped()
    }

    private func wrappedOffset(base: CGFloat) -> CGFloat {
        var y = base.truncatingRemainder(dividingBy: segmentLength)
        if y < 0 { y += segmentLength }
        return y
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

struct BlockSeparators: View {
    let step: CGFloat
    let tileSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let boardSize = step * 9 - (step - tileSize)

                let x1 = step * 3 - (step - tileSize) / 2
                let x2 = step * 6 - (step - tileSize) / 2
                let y1 = step * 3 - (step - tileSize) / 2
                let y2 = step * 6 - (step - tileSize) / 2

                path.move(to: CGPoint(x: x1, y: 0))
                path.addLine(to: CGPoint(x: x1, y: boardSize))

                path.move(to: CGPoint(x: x2, y: 0))
                path.addLine(to: CGPoint(x: x2, y: boardSize))

                path.move(to: CGPoint(x: 0, y: y1))
                path.addLine(to: CGPoint(x: boardSize, y: y1))

                path.move(to: CGPoint(x: 0, y: y2))
                path.addLine(to: CGPoint(x: boardSize, y: y2))
            }
            .stroke(.white.opacity(0.85), lineWidth: 3)
        }
    }
}
