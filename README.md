# FlatCube

FlatCube is a compact color puzzle game built around a 9×9 board split into visible 3×3 groups. The goal is to restore the board to its solved arrangement by sliding entire rows or columns until each 3×3 block returns to a single color.

## How it works

- The board contains 9 colors arranged as nine 3×3 color blocks in the solved state.
- A move shifts one full row or one full column with wrap-around behavior.
- The game tracks move count and detects when the board returns to the solved pattern.

## Current prototype

The current version is a SwiftUI prototype focused on the core gameplay loop: shuffle, drag a row or column, and solve the board in as few moves as possible

## Screenshots

|  |  |  |  |
| :--- | :---: | :---: | ---: |
| <img width="294" height="639" alt="" src="https://github.com/user-attachments/assets/ea7833a2-2b1c-4749-9743-e9ea643c8c98" /> | <img width="294" height="639" alt="" src="https://github.com/user-attachments/assets/a373cf12-cff1-4187-8bd4-b675733dd28d" /> |  <img width="294" height="639" alt="" src="https://github.com/user-attachments/assets/d03fc8b7-6f58-4952-8869-56077267da01" /> | <img width="294" height="639" alt="ezgif-8d2c44c670762870" src="https://github.com/user-attachments/assets/22eb4cf8-1e18-4a91-99aa-9f57f8f55795" /> |



