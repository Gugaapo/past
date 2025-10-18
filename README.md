# 🕐 past — A Simple Bash TUI Directory Navigator

`past` is a lightweight **Bash-based terminal UI** to quickly jump between your **recently visited** and **favorite** directories — without leaving your shell.

It’s built entirely in Bash (no Python, no C dependencies) and works seamlessly inside any terminal emulator.

---

## ✨ Features

- **View last 10 visited directories**
- **Manage favorites** (`past --fav`)
- **Interactive navigation** using arrow keys or number keys
- **Instant jump** by pressing a number key (`1–9`, or `0` for 10th)
- **Add to favorites** with `Shift+Enter`
- **Fast** — pure Bash, no external dependencies
- Works in **Alacritty, Konsole, GNOME Terminal, Kitty**, etc.

---

## ⚙️ Requirements

`past` requires only standard Bash and a few basic utilities:

- `bash` (≥ 4.0)
- `tput` (usually from `ncurses`)
- `clear` (from `coreutils`)
- `grep`, `sed`, and `cat` (default on all Linux distros)

To check:
```bash
bash --version
```
## Installation

Clone the repository and run the setup script:
```bash
git clone https://github.com/Gugaapo/past.git
cd past-script
./setup.sh
```

The installer will copy the script to:
```bash
~/.local/bin/past
```

and create the configuration directory:
```bash
~/.config/dir_history/
```

If you see this message:
```
Make sure ~/.local/bin is in your PATH
```

then add the following line to your ~/.bashrc (if it’s not already there):
```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:
```bash
exec bash
```
## Usage
### Show recent directories
```bash
past
```

### Use:

- ↑ / ↓ → navigate
- Enter → open selected directory
- Shift+Enter → add to favorites
- 1–9 / 0 → jump directly
- q → quit

### Show and manage favorites
```bash
past --fav
```
Options:
- Top item lets you add current directory to favorites
- Select any favorite to jump directly into it

## Uninstall
To remove everything:
```bash
rm -f ~/.local/bin/past
rm -rf ~/.config/dir_history
sed -i '/past() {/,+4d' ~/.bashrc
```
## Project Structure
past-script/
├── past/                 # Core Bash script
├── setup.sh              # Installer
└── README.md             # This file


## Example Setup Workflow
```bash
git clone https://github.com/<your-username>/past-script.git
cd past-script
./setup.sh
echo 'past() {
  local target
  target=$("$HOME/.local/bin/past" "$@")
  if [[ -n "$target" && -d "$target" ]]; then
    cd "$target" || echo "Failed to cd to $target"
  fi
}' >> ~/.bashrc
exec bash
past
```
## Author
Gustavo Oliveira
github.com/Gugaapo/past

