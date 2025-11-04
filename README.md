## 🚧 WORK IN PROGRESS 🚧

> **Note:** This project is currently under active development. Features, gameplay, and documentation are subject to change. Stay tuned for updates!

## ASSETS USED:
TinyTown: https://kenney.nl/assets/tiny-town

The Adventurer - Female Character Asset: https://sscary.itch.io/the-adventurer-female

Tiny RPG Character Asset Pack: https://zerie.itch.io/tiny-rpg-character-asset-pack

IMMORTAL font by Apostrophic Labs: https://www.1001freefonts.com/immortal.font

Menu Background: https://edermunizz.itch.io/free-pixel-art-forest

---

# Overview

### ⬇️[Downlaods/Releases](https://github.com/CaSc2000-dotcom/MergeOnslaught/releases/)⬇️

You are an adventurer and have to survive the onslaught of orcs coming from all angles! 
[Software Demo Video](https://youtu.be/pku5_7JMaco)

### Controls:
# Cloud Database

The cloud database I chose was Supabase. It has built-in features for PostGres database creating and maniuplation as well as user authentication.

The main table I created is called `leaderboard` and it contains an ID, the username of the player, and an integer that represents their score. Because Godot does not have a maintained library for Supabase, I used PostgREST to have it interact with the database.

# Development Environment

IDE: Godot Engine (Version: 4.5)
Compiler: Microsoft Visual C++ (MSVC) 2015-2022 14.44.35211
Operating System: Windows 10
Hardware: CPU Intel i7-1255U | 16.0 GB DDR4 RAM | Intel Iris Xe Graphics
Other Tools: Git, GitHub Desktop, Supabase
Programming Language: GDScript
Libraries: 
- Godot Engine API: Built-in nodes like TileMap, RigidBody2D, AnimatedSprite2D, Area2D, etc.
- Supabase PostgREST

# Useful Websites

- [PostgREST](https://docs.postgrest.org/en/v14/)

# Future Work

- I'm not sure about the security of the admin panel, since the key combo is hard-coded and the authenticated tokens are likely easy to get
- I want to make the game more challenging, as it's very easy to get a high score
- I want the UI for the leaderboard to be more polished and refined
