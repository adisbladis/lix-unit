{
  description = "Nix unit test runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    mdbook-nixdoc.url = "github:adisbladis/mdbook-nixdoc";
    mdbook-nixdoc.inputs.nixpkgs.follows = "nixpkgs";
    mdbook-nixdoc.inputs.nix-github-actions.follows = "nix-github-actions";
  };

  outputs =
    inputs@{ flake-parts, nix-github-actions, ... }:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (inputs) self;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.treefmt-nix.flakeModule ];

      flake.githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = {
          x86_64-linux = builtins.removeAttrs (self.packages.x86_64-linux // self.checks.x86_64-linux) [
            "default"
          ];
          x86_64-darwin = builtins.removeAttrs (self.packages.x86_64-darwin // self.checks.x86_64-darwin) [
            "default"
            "treefmt"
          ];
        };
      };

      flake.lib = import ./lib { inherit lib; };

      perSystem =
        {
          pkgs,
          self',
          system,
          ...
        }:
        let
          inherit (pkgs) stdenv;
          drvArgs = {
            srcDir = self;
            lix = pkgs.lixVersions.lix_2_90;
          };
        in
        {
          treefmt.imports = [ ./dev/treefmt.nix ];
          packages.lix-unit = pkgs.callPackage ./default.nix drvArgs;
          packages.default = self'.packages.lix-unit;
          packages.doc = pkgs.callPackage ./doc {
            inherit self;
            mdbook-nixdoc = inputs.mdbook-nixdoc.packages.${system}.default;
          };
          devShells.default =
            let
              pythonEnv = pkgs.python3.withPackages (_ps: [ ]);
            in
            pkgs.mkShell {
              nativeBuildInputs = self'.packages.lix-unit.nativeBuildInputs ++ [
                pythonEnv
                pkgs.difftastic
                pkgs.nixdoc
                pkgs.mdbook
                pkgs.mdbook-open-on-gh
                inputs.mdbook-nixdoc.packages.${system}.default
              ];
              inherit (self'.packages.lix-unit) buildInputs;
              shellHook = lib.optionalString stdenv.isLinux ''
                export LIX_DEBUG_INFO_DIRS="${pkgs.curl.debug}/lib/debug:${drvArgs.lix.debug}/lib/debug''${LIX_DEBUG_INFO_DIRS:+:$LIX_DEBUG_INFO_DIRS}"
                export LIX_UNIT_OUTPATH=${self}
              '';
            };
        };
    };
}
