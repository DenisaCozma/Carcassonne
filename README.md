# 🏰 Carcassonne

![Godot](https://img.shields.io/badge/Godot-4.6-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-100%25-355570?style=for-the-badge&logo=godot-engine&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Development-f39c12?style=for-the-badge)

A digital implementation of the classic board game **Carcassonne**, built in **Godot** using **GDScript**.

The game focuses on tile placement, turn-based gameplay, meeple placement and scoring logic.

---

## 🎮 About the Game

Carcassonne is a tile-based board game where players build a medieval landscape by placing tiles with roads, cities, fields and monasteries.

In this version, players take turns drawing and placing tiles on the board. Tiles must match the existing neighboring tiles, and players can place meeples to claim features and score points.

---

## ✨ Features

- Tile drawing and placement system
- Tile rotation before placement
- Validation for correct tile placement
- Local 2-player gameplay
- Meeple placement system
- Road, city, field and monastery feature validation
- Scoring system for completed features
- In-game HUD with player information
- Randomized player colors
- Turn-based game state management

---

## 🕹️ Controls

| Action | Control |
|---|---|
| Rotate current tile | Left Click |
| Place current tile | Right Click |
| Place meeple North | `1` |
| Place meeple East | `2` |
| Place meeple South | `3` |
| Place meeple West | `4` |
| Place meeple on Monastery / Center | `5` |
| Skip meeple placement | `0` or `Space` |

---

## 📁 Project Structure

```text
Carcassonne/
│
├── assets/          # Game textures and visual resources
├── script/          # Main gameplay scripts
├── states/          # Game state logic
├── main.tscn        # Main scene
├── project.godot    # Godot project configuration
└── README.md
```

---

## 🧠 Main Scripts

```text
script/
├── board_layer.gd        # Board logic, tile placement and turn flow
├── tile.gd               # Tile data and rotation logic
├── tile_deck.gd          # Tile deck generation and drawing
├── meeple.gd             # Meeple model and positions
├── player.gd             # Player data, score and meeples
├── feature_validator.gd  # Validation for occupied features
├── scoring_system.gd     # Score calculation
└── GameHUD.gd            # Interface updates
```

```text
states/
├── game_state.gd         # Base game state
└── turn_state.gd         # Turn phases and input handling
```

---

## 🚀 How to Run

1. Clone the repository:

```bash
git clone https://github.com/DenisaCozma/Carcassonne.git
```

2. Open **Godot**.

3. Click **Import**.

4. Select the `project.godot` file from the cloned folder.

5. Run the project.

---

## 📌 Current Status

The project is currently in development and includes the core gameplay systems needed for a playable local version of Carcassonne.

Future improvements may include:

- better menu screens;
- improved UI design;
- more complete scoring rules;
- animations and sound effects;
- AI player or online multiplayer;
- final game-over screen.
