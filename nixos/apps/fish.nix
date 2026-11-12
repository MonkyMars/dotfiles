{ config, pkgs, lib, ... }:

let
  # Tools the usb script calls. Appended to the front of PATH inside the
  # script only. sudo is intentionally not listed, so the setuid one from
  # /run/wrappers/bin is used.
  usbDeps = with pkgs; [
    util-linux
    coreutils
    gawk
    gnused
    gnugrep
    findutils
    rsync
    e2fsprogs
    dosfstools
    exfatprogs
    ntfs3g
  ];

  # Your zsh function, wrapped as a standalone bash script.
  # writeShellScriptBin does not enable `set -e`, so it behaves like your
  # original function.
  usbScript = pkgs.writeShellScriptBin "usb" ''
    export PATH="${lib.makeBinPath usbDeps}:$PATH"

    ${builtins.readFile ../../.zsh/usb}

    usb "$@"
    status=$?

    # For `usb -s`: tell the fish wrapper which directory to cd into
    if [ "$1" = "-s" ] && [ "$status" -eq 0 ] && [ -n "''${USB_CD_FILE:-}" ]; then
      pwd > "$USB_CD_FILE"
    fi
    exit "$status"
  '';
in
{
  home.packages = [
    usbScript
    pkgs.grc        # used by the grc fish plugin
    pkgs.libnotify  # notify-send, used by the done fish plugin
    pkgs.bat        # previews for fifc and fzf-fish
    pkgs.fd         # file search for fifc and fzf-fish
  ];

  # ── Environment variables ──────────────────────────────────────
  home.sessionVariables = {
    FILE_MANAGER = "nautilus";
    BROWSER = "xdg-open";
    BU_CDP_URL = "http://127.0.0.1:9222";
    CARAPACE_BRIDGES = "zsh,fish,bash";
    NIXOS_DIR = "${config.home.homeDirectory}/dotfiles/nixos";
  };

  # ── PATH ───────────────────────────────────────────────────────
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
    "$HOME/.spicetify"
    "$HOME/.opencode/bin"
  ];

  # ── Declarative tool integrations (fish integration is on by default) ─
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.atuin.enable = true;
  programs.carapace.enable = true;

  # fzf stays installed (the fish plugins use it), but its own fish key
  # bindings are off: fzf-fish replaces Ctrl+T, and atuin keeps Ctrl+R.
  programs.fzf = {
    enable = true;
    enableFishIntegration = false;
  };

  # Keeps fish (instead of bash) inside `nix develop` / `nix shell`
  programs.nix-your-shell.enable = true;

  # nh (used by the n* helpers below)
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/monky/dotfiles/nixos";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    extraOptions = [
      "--all"
      "--group-directories-first"
    ];
  };

  # ── Fish ───────────────────────────────────────────────────────
  programs.fish = {
    enable = true;

    # Plugins packaged by nixpkgs
    plugins = [
      { name = "done"; src = pkgs.fishPlugins.done.src; }                           # notify when long commands finish
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }                   # auto-close brackets and quotes
      { name = "puffer"; src = pkgs.fishPlugins.puffer.src; }                       # !! and !$ expansion
      { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }                       # interactive git via fzf
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }                           # run bash scripts, import their env
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }                             # colorized command output
      { name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages.src; } # colored man output
      { name = "fifc"; src = pkgs.fishPlugins.fifc.src; }                           # fzf-powered Tab completion
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }                   # fzf pickers (files, git, processes)
    ];

    # Abbreviations expand as you type, so history shows the real command
    shellAbbrs = {
      # Git
      g = "git";
      gs = "git status";
      gsw = "git switch";
      add = "git add";
      gc = "git commit -m";
      gp = "git push -u origin";
      gl = "git pull";
      gst = "git stash";

      # System
      rb = "reboot";
      pw = "poweroff";
      c = "clear";
      e = "exit";
      m = "mkdir";

      # Go
      gr = "go run";
      gb = "go build";
      gt = "go test";
      gfmt = "gofmt -w .";

      # Rust
      cr = "cargo run";
      cc = "cargo check";
      ct = "cargo test";
      cb = "cargo build";

      # Bun
      b = "bun";
      bd = "bun run dev";
      bi = "bun install";

      # Docker
      dc = "docker compose up --build";
      ddev = "docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build";
      dprod = "docker compose up -d --build";
      dp = "docker ps -sa";
      dr = "docker run -t";

      # Misc (ls comes from programs.eza)
      ff = "fastfetch";
      py = "python3";
      pyr = "python3 main.py";
      zed = "zeditor";
    };

    # ── Functions ────────────────────────────────────────────────
    functions = {
      fish_user_key_bindings = ''
             bind \t _fifc
           '';
      # usb: the script does everything except `usb -s`, which has to
      # change this shell's directory, so it is handled here.
      usb = {
        description = "USB helper (cp, mv, rm, mount, ...); `usb -s` cds into a USB";
        body = ''
          if test "$argv[1]" = "-s"
            set -lx USB_CD_FILE (mktemp)
            command usb $argv
            set -l code $status
            if test $code -eq 0; and test -s $USB_CD_FILE
              cd (cat $USB_CD_FILE)
            end
            rm -f $USB_CD_FILE
            return $code
          else
            command usb $argv
          end
        '';
      };

      # ── NixOS helpers (nh) ─────────────────────────────────────
      # Host name: $NIXOS_HOST if set, otherwise the machine's hostname
      _nix_host = ''
        if set -q NIXOS_HOST
          echo $NIXOS_HOST
        else
          echo $hostname
        end
      '';

      # Flakes only see git-tracked files, so stage everything before building.
      _nix_stage = ''
        git -C $NIXOS_DIR add -A
      '';

      nrs = {
        description = "Rebuild and switch (nh shows a diff)";
        body = ''
          _nix_stage; and nh os switch $NIXOS_DIR -H (_nix_host) $argv
        '';
      };

      nrt = {
        description = "Build and activate without a boot entry (reverts on reboot)";
        body = ''
          _nix_stage; and nh os test $NIXOS_DIR -H (_nix_host) $argv
        '';
      };

      nrb = {
        description = "Build and apply on next boot only";
        body = ''
          _nix_stage; and nh os boot $NIXOS_DIR -H (_nix_host) $argv
        '';
      };

      nup = {
        description = "Update all flake inputs, then rebuild";
        body = ''
          nix flake update --flake $NIXOS_DIR; and nrs $argv
        '';
      };

      nupi = {
        description = "Update a single flake input, then rebuild: nupi nixpkgs";
        body = ''
          if test (count $argv) -eq 0
            echo "usage: nupi <input>" >&2
            return 1
          end
          set -l input $argv[1]
          set -e argv[1]
          nix flake update $input --flake $NIXOS_DIR; and nrs $argv
        '';
      };

      nrollback = {
        description = "Roll back to the previous generation";
        body = ''
          sudo nixos-rebuild switch --rollback
        '';
      };

      ngens = {
        description = "List system generations";
        body = ''
          nixos-rebuild list-generations
        '';
      };

      ngc = {
        description = "Garbage collect: keep last 7 days and at least 5 generations";
        body = ''
          nh clean all --keep-since 7d --keep 5 $argv
        '';
      };

      nsearch = {
        description = "Search for a package";
        body = ''
          nh search $argv
        '';
      };

      nedit = {
        description = "Open the config repo in Zed";
        body = ''
          cd $NIXOS_DIR; and zeditor .
        '';
      };

      ncheck = {
        description = "Check the flake evaluates without building anything";
        body = ''
          _nix_stage; and nix flake check $NIXOS_DIR
        '';
      };
    };

    interactiveShellInit = ''
      # No greeting
      set -g fish_greeting

      # Autosuggestion color (same navy as the old zsh config)
      set -g fish_color_autosuggestion 1e3a5f

      # done: only notify for commands that ran longer than 15 seconds
      set -g __done_min_cmd_duration 15000

      # fzf-fish: don't bind Ctrl+R, so atuin keeps it
      fzf_configure_bindings --history=

      # fifc: Ctrl+O in the Tab popup opens the file in Zed
      set -g fifc_editor zeditor
    '';
  };
}
