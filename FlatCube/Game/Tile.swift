//
//  Tile.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import SwiftUI

enum TileColor: Int, CaseIterable, Codable {
    case tangerine, orange, yellow, lime, green, cyan, twilight, purple, peach

    var color: Color {
        switch self {
        case .tangerine: Color(#colorLiteral(red: 0.855, green: 0.224, blue: 0.169, alpha: 1)) // #da392b
        case .orange:    Color(#colorLiteral(red: 0.859, green: 0.224, blue: 0.529, alpha: 1)) // #db3987
        case .yellow:    Color(#colorLiteral(red: 0.894, green: 0.722, blue: 0.000, alpha: 1)) // #e4b800
        case .lime:      Color(#colorLiteral(red: 0.620, green: 0.745, blue: 0.114, alpha: 1)) // #9ebe1d
        case .green:     Color(#colorLiteral(red: 0.141, green: 0.635, blue: 0.247, alpha: 1)) // #24a23f
        case .cyan:      Color(#colorLiteral(red: 0.000, green: 0.651, blue: 0.765, alpha: 1)) // #00a6c3
        case .twilight:  Color(#colorLiteral(red: 0.149, green: 0.365, blue: 0.808, alpha: 1)) // #265dce
        case .purple:    Color(#colorLiteral(red: 0.545, green: 0.271, blue: 0.808, alpha: 1)) // #8b45ce
        case .peach:     Color(#colorLiteral(red: 0.808, green: 0.447, blue: 0.639, alpha: 1)) // #ce72a3
        }
    }

    var accessibilityName: String {
        switch self {
        case .tangerine: return "tangerine"
        case .orange: return "orange"
        case .yellow: return "yellow"
        case .lime: return "lime"
        case .green: return "green"
        case .cyan: return "cyan"
        case .twilight: return "twilight"
        case .purple: return "purple"
        case .peach: return "peach"
        }
    }
}

struct Tile: Identifiable, Equatable, Codable {
    let id: UUID
    let color: TileColor

    init(id: UUID = UUID(), color: TileColor) {
        self.id = id
        self.color = color
    }
}
