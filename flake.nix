{
  description = "Nix unit test runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    mdbook-nixdoc.url = "github:adisbladis/mdbook-nixdoc";
    mdbook-nixdoc.inputs.nixpkgs.follows = "nixpkgs";
    mdbook-nixdoc.inputs.nix-github-actions.follows = "nix-github-actions";
    mdbook-nixdoc.inputs.flake-parts.follows = "flake-parts";
    mdbook-nixdoc.inputs.treefmt-nix.follows = "treefmt-nix";
  };

  outputs = inputs @ { flake-parts, nix-github-actions, ... }:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (inputs) self;
    in
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        systems = inputs.nixpkgs.lib.systems.flakeExposed;
        imports = [ inputs.treefmt-nix.flakeModule ];

        flake.githubActions = nix-github-actions.lib.mkGithubMatrix {
          checks = {
            x86_64-linux = builtins.removeAttrs (self.packages.x86_64-linux // self.checks.x86_64-linux) [ "default" ];
            x86_64-darwin = builtins.removeAttrs (self.packages.x86_64-darwin // self.checks.x86_64-darwin) [ "default" "treefmt" ];
          };
        };

        flake.lib = import ./lib { inherit lib; };

        perSystem = { pkgs, self', system, ... }:
          let
            inherit (pkgs) stdenv;
            drvArgs = {
              srcDir = self;
              nix = pkgs.nixVersions.nix_2_23;
            };
          in
          {
            treefmt.imports = [ ./dev/treefmt.nix ];
            packages.nix-unit = pkgs.callPackage ./default.nix drvArgs;
            packages.default = self'.packages.nix-unit;
            packages.doc = pkgs.callPackage ./doc {
              inherit self;
              mdbook-nixdoc = inputs.mdbook-nixdoc.packages.${system}.default;
            };
            devShells.default =
              let
                pythonEnv = pkgs.python3.withPackages (_ps: [ ]);
              in
              pkgs.mkShell {
                nativeBuildInputs = self'.packages.nix-unit.nativeBuildInputs ++ [
                  pythonEnv
                  pkgs.difftastic
                  pkgs.nixdoc
                  pkgs.mdbook
                  pkgs.mdbook-open-on-gh
                  inputs.mdbook-nixdoc.packages.${system}.default
                ];
                inherit (self'.packages.nix-unit) buildInputs;
                shellHook = lib.optionalString stdenv.isLinux ''
                  export NIX_DEBUG_INFO_DIRS="${pkgs.curl.debug}/lib/debug:${drvArgs.nix.debug}/lib/debug''${NIX_DEBUG_INFO_DIRS:+:$NIX_DEBUG_INFO_DIRS}"
                  export NIX_UNIT_OUTPATH=${self}
                '';
              };
          };
      };
}
