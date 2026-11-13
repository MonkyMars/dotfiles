{ pkgs, ... }:

{
  programs.gh = {
    enable = true;

    # Same thing `gh auth setup-git` would do, but declared in Nix
    # so it ends up in the read-only generated git config.
    gitCredentialHelper.enable = true;

    settings = {
      git_protocol = "ssh";
    };
  };
}
