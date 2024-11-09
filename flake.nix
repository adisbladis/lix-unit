{
  description = "Nix unit test runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    lix.url = "git+https://git.lix.systems/lix-project/lix.git";
    lix.flake = false;

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-github-actions,
      treefmt-nix,
      lix,
    }:
    let
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      inherit (nixpkgs) lib;

      lix' = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.callPackage "${lix}/package.nix" {
          stdenv = pkgs.clangStdenv;
        }
      );

    in
    {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = {
          x86_64-linux = builtins.removeAttrs (self.packages.x86_64-linux // self.checks.x86_64-linux) [
            "default"
          ];
          # Note: Lix itself fails to build on Darwin
          # x86_64-darwin = builtins.removeAttrs (self.packages.x86_64-darwin // self.checks.x86_64-darwin) [
          #   "default"
          #   "treefmt"
          # ];
        };
      };

      lib = import ./lib { inherit lib; };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          drvArgs = {
            srcDir = self;
            lix = lix'.${system};
          };
        in
        {
          lix-unit = pkgs.callPackage ./default.nix drvArgs;
          default = self.packages.${system}.lix-unit;
          doc = pkgs.callPackage ./doc {
            inherit self;
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        (treefmt-nix.lib.evalModule pkgs ./dev/treefmt.nix).config.build.wrapper
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) stdenv;
          drvArgs = {
            srcDir = self;
            lix = lix'.${system};
          };
        in
        {
          default =
            let
              pythonEnv = pkgs.python3.withPackages (_ps: [ ]);
            in
            pkgs.mkShell {
              nativeBuildInputs = self.packages.${system}.lix-unit.nativeBuildInputs ++ [
                pythonEnv
                pkgs.difftastic
                pkgs.nixdoc
                pkgs.mdbook
                pkgs.mdbook-open-on-gh
                pkgs.mdbook-cmdrun
              ];
              inherit (self.packages.${system}.lix-unit) buildInputs;
              shellHook = lib.optionalString stdenv.isLinux ''
                export LIX_DEBUG_INFO_DIRS="${pkgs.curl.debug}/lib/debug:${drvArgs.lix.debug}/lib/debug''${LIX_DEBUG_INFO_DIRS:+:$LIX_DEBUG_INFO_DIRS}"
                export LIX_UNIT_OUTPATH=${self}
              '';
            };
        }
      );

    };
}
