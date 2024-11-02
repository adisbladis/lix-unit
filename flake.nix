{
  description = "Nix unit test runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    lix.url = "git+https://git.lix.systems/lix-project/lix.git";
    lix.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";

    mdbook-nixdoc.url = "github:adisbladis/mdbook-nixdoc";
    mdbook-nixdoc.inputs.nixpkgs.follows = "nixpkgs";
    mdbook-nixdoc.inputs.nix-github-actions.follows = "nix-github-actions";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-github-actions,
      mdbook-nixdoc,
      treefmt-nix,
      lix,
    }:
    let
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      inherit (nixpkgs) lib;

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
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          drvArgs = {
            srcDir = self;
            lix = lix.packages.${system}.default;
          };
        in
        {
          lix-unit = pkgs.callPackage ./default.nix drvArgs;
          default = self.packages.${system}.lix-unit;
          doc = pkgs.callPackage ./doc {
            inherit self;
            mdbook-nixdoc = mdbook-nixdoc.packages.${system}.default;
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
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          inherit (pkgs) stdenv;
          drvArgs = {
            srcDir = self;
            lix = pkgs.lixVersions.latest;
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
                mdbook-nixdoc.packages.${system}.default
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
