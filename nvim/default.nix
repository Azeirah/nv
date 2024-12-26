{
  inputs,
  system,
  pkgs,
  ...
}:
{
  # Install ripgrep
  extraPackages = [ pkgs.ripgrep ];

  # Define pkgs for the current system, with unfree packages enabled.
  nixpkgs.pkgs = import inputs.nixpkgs {
    inherit system;

    config = {
      allowUnfree = true;
    };
  };
}
