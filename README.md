# Warung Brainrot

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ngadukun/roblox-brainrot-game/rank.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ngadukun/roblox-brainrot-game/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Rebut, kumpul, kaya — di pasar malam paling absurd sedunia.**

Warung Brainrot is a 3D brainrot game set in an Indonesian night market,
built for make.fun's [roblox-brainrot-01](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
bounty. Absurd characters ride a conveyor belt through the middle of the
market; buy them, and they walk home to your base and earn you money every
second. Climb the ladder from a flying cracker to the Tung-Tung Sahur
himself — then watch your back, because everyone else wants them too.

## The loop

1. You spawn at the night market with **$150**.
2. Brainrots stroll down the central conveyor. Walk up and press **E** to
   buy one; it takes a slot on your base and ticks money at its rate.
3. Other players can **steal** from your base (hold E for 2.5 s) and carry
   the catch home over their head. Defend with the **Kunci Base** button:
   20 seconds locked, 60 seconds cooldown.
4. Every ~100 seconds the **Hujan Krupuk** hits: a five-second warning,
   then a cracker wave sweeps the map. Anyone caught outside their own base
   is flung back to spawn and drops what they were carrying.
5. **Rebirth** at $25,000 lifetime earnings: lose the run, gain a permanent
   +50% income multiplier, stacking every time. Extra base slots (up to 10)
   cost a doubling price.

## The cast

Ten original characters on a rarity ladder, with Gold (5%, ×2 income) and
Diamond (1%, ×5 income) mutations rolled at spawn:

| # | Name | Rarity | $/sec | Price |
|---|------|--------|-------|-------|
| 1 | Krupuk Terbang | Common | 2 | $30 |
| 2 | Es Teh Manis | Common | 4 | $75 |
| 3 | Gorengan Sakti | Rare | 9 | $200 |
| 4 | Kopi Tubruk Titan | Rare | 15 | $450 |
| 5 | Nasi Padang Raksasa | Epic | 30 | $1,000 |
| 6 | Becak Terbang | Epic | 55 | $2,200 |
| 7 | Komodo Berkepala Dua | Legendary | 110 | $5,000 |
| 8 | Garuda Emas | Mythic | 250 | $12,000 |
| 9 | Kujang Petir | Brainrot God | 600 | $30,000 |
| 10 | Tung-Tung Sahur | Secret | 1,500 | $75,000 |

## How it is built

A [Rojo](https://rojo.space) project: every script of the place is a `.luau`
file under `src/`, and `game.rbxl` is built from them with
`rojo build default.project.json --output game.rbxl`.

- `src/shared/` — the cast (`BrainrotData`) and every tuning number
  (`Config`), mapped into ReplicatedStorage.
- `src/server/` — one module per job, all state in one store:
  `PlayerState` (the single state store), `BrainrotFactory` (builds the
  characters from parts), `ConveyorService` (the belt), `EconomyService`
  (the income tick and buying), `BaseService` (plots, slots, locking),
  `StealService` (theft and carrying), `EventService` (the krupuk wave),
  `RebirthService`, `WorldBuilder` (the market's stalls, lamps, trees and
  signs) and `TourHelper` (the reviewer shortcuts TOUR.json names).
- `src/client/` — a small HUD (`Hud`) and its bootstrap: cash, income and
  rebirth across the top centre, the three action buttons at the bottom,
  toasts and the wave banner. Nothing covers the top-left corner.
- `main.ts` (Node 22, standard library only) hands the entry in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output and
  writes `dossier.json` with the vendored make.fun library.

Run it as the grader does:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

## License

MIT — see `LICENSE`.
