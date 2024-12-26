{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  imports = lib.optionals (inputs.treefmt-nix ? flakeModule) [ inputs.treefmt-nix.flakeModule ];

  perSystem = lib.optionalAttrs (inputs.treefmt-nix ? flakeModule) {
    treefmt.config = {
      projectRootFile = "flake.nix";
      flakeCheck = true;

      programs = {
        deadnix.enable = true;
        nixfmt.enable = true;
        statix.enable = true;
        stylua.enable = true;
      };
    };
  };
}
