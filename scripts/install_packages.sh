# Install spotify_player with a fix for authenticating:
git clone https://github.com/bbzylstra/spotify-player.git
cd spotify-player
cargo install --path spotify_player/ --no-default-features --features pulseaudio-backend,pixelate,streaming,media-control

# Install yazi (file-manager)
sudo pacman -S yazi

# Install wtype (needed for the custom fzf clipboard manager)
sudo pacman -S wtype

# Install fzf (fuzzy finder)
sudo pacman -S fzf
