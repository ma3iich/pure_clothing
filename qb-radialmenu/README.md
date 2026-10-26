# qb-radialmenu (QBCore)

**Français** — Le menu radial de QBCore a une partie « Clothing » (enlever / remettre un vêtement) qui déshabille le
personnage sans passer par l'inventaire : le vêtement ne devient pas un objet. Avec Pure Clothing, cette partie doit être retirée.

- `config.lua` : la configuration **par défaut** de qb-radialmenu, avec l'entrée `clothesmenu` retirée. Si tu n'as jamais
  modifié ta config, copie ce fichier dans `resources/[qb]/qb-radialmenu/config.lua`, puis `restart qb-radialmenu`.
- Si tu as modifié ta config : ouvre `qb-radialmenu/config.lua` et supprime seulement le bloc `{ id = 'clothesmenu', ... }`
  dans `Config.MenuItems`.

Avec ox_inventory, Pure Clothing gère aussi ce menu (une pièce retirée par le menu devient un objet, une pièce remise
est reprise dans l'inventaire) : la copie n'est pas obligatoire, mais conseillée.

**English** — The QBCore radial menu has a "Clothing" part (take off / put back a piece) that undresses the character
without the inventory: the piece never becomes an item. With Pure Clothing, that part has to be removed.

- `config.lua`: the **default** qb-radialmenu config with the `clothesmenu` entry removed. If you never changed your
  config, copy this file to `resources/[qb]/qb-radialmenu/config.lua`, then `restart qb-radialmenu`.
- If you changed your config: open `qb-radialmenu/config.lua` and delete only the `{ id = 'clothesmenu', ... }` block
  in `Config.MenuItems`.

With ox_inventory, Pure Clothing also handles that menu (a piece taken off by the menu becomes an item, a piece put
back is taken from the inventory): copying is optional, but recommended.
