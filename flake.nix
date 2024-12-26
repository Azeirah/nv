{
  description = "nv - A batteries-included nixvim distribution for nix development, inspired by kickstart.nvim";

  #  ::::    ::::::     :::
  #  :+:+:   :+::+:     :+:
  #  :+:+:+  +:++:+     +:+
  #  +#+ +:+ +#++#+     +:+
  #  +#+  +#+#+# +#+   +#+
  #  #+#   #+#+#  #+#+#+#
  #  ###    ####    ### 
  #
  #  What is nv?
  #
  #    nv (pronounced "envy") is *not* a distribution.
  #    
  #    nv is a starting point for your own Nix development environment using nixvim.
  #    The goal is that you can read every line of code, top-to-bottom, understand
  #    what your configuration is doing, and modify it to suit your needs.
  #
  #    Once you've done that, you can start exploring, configuring and tinkering to
  #    make your nv editor your own!
  #
  #  Getting Started:
  #    1. Visit https://github.com/Azeirah/nv
  #    2. Fork the repository (or use it as a template)
  #    3. Clone your fork locally using:
  #         git clone https://github.com/username/nv
  #    4. `cd` into the repository
  #    5. Start it up with: nix run .#
  #    
  #    If you don't want to fork, you can also run it directly:
  #      nix run github:Azeirah/nv#

  # Input declarations - these are dependencies of our configuration.
  inputs = {
    # Flake framework for writing flakes in a modular way.
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      # Specify which inputs to follow to avoid duplicate dependencies, and also remove unnecessary dependencies.
      inputs = {
        flake-compat.follows = "";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "";
        hercules-ci-effects.follows = "";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    # Latest nix packages from nixos-unstable, to ensure updated neovim and plugins.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Nixvim, the configuration system for neovim, that uses nix to manage plugins and configuration.
    nixvim = {
      url = "github:nix-community/nixvim";
      # Again, specify which inputs to follow to avoid duplicate dependencies, and also remove unnecessary dependencies.
      inputs = {
        devshell.follows = "";
        flake-compat.follows = "";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "";
        home-manager.follows = "";
        nixpkgs.follows = "nixpkgs";
        nix-darwin.follows = "";
        nuschtosSearch.follows = "";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    /*
      Treefmt for project-wide formatting.
      This input is optional, so you can remove it in your configuration if you don't want to use it.

      For example:
      {
        inputs.nv = {
          url = "github:Azeirah/nv";
          inputs = {
            nixpkgs.follows = "nixpkgs";
            treefmt-nix.follows = "";
          };
        };
      }
    */
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    # Configure nix-community binary cache for faster builds.
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Output declarations - what this flake provides.
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # Define the systems this flake supports.
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # Development-specific flake outputs.
      imports = [ ./dev ];

      # Configuration for each system.
      perSystem =
        {
          inputs', # Inputs for the current system.
          pkgs, # Nixpkgs for the current system.
          self', # Our own outputs for the current system.
          system, # The current system.
          ...
        }:
        let
          # Import nixvim and nixvim libraries for the current system.
          nixvim = inputs.nixvim.legacyPackages.${system};
          nixvimLib = inputs.nixvim.lib.${system};
          # Define the nixvim module for our configuration.
          nixvimModule = {
            module = import ./nvim; # Import our neovim configurations.
            extraSpecialArgs = {
              inherit inputs system; # Pass the inputs and system to the nixvim module, so we can acess them in our configuration.
            };
          };
        in
        {
          # Define the checks for our configuration. You can test if the current configuration is working by running `nix flake check`.
          checks = {
            default = self'.checks.nvim;
            nvim = nixvimLib.check.mkTestDerivationFromNixvimModule nixvimModule;
          };

          # Development shell for developing the distribution.
          devShells = {
            default = self'.devShells.nvim;
            # Development shell for the stable neovim release.
            nvim = pkgs.mkShell {
              strictDeps = true;
              nativeBuildInputs = [ self'.packages.nvim ];
            };
            # Development shell for the nightly neovim builds.
            nvim-nightly = pkgs.mkShell {
              strictDeps = true;
              nativeBuildInputs = [ self'.packages.nvim-nightly ];
            };
          };

          # Neovim packages, including the stable and nightly versions.
          packages = {
            default = self'.packages.nvim;
            # Stable neovim with our nixvim configuration.
            nvim = nixvim.makeNixvimWithModule nixvimModule;
            # Nightly neovim with our nixvim configuration.
            # We extend our configuration module and modify the neovim package to use the nightly version.
            nvim-nightly = self'.packages.nvim.extend {
              package = inputs'.neovim-nightly.packages.neovim;
            };
          };
        };
    };
}
