{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    lix-unit.url = "github:adisbladis/lix-unit";
    lix-unit.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      lix-unit,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-windows"
      ];
    in
    {
      tests.testPass = {
        expr = 3;
        expected = 4;
      };

      checks = forAllSystems (system: {
        default =
          nixpkgs.legacyPackages.${system}.runCommand "tests"
            {
              nativeBuildInputs = [ lix-unit.packages.${system}.default ];
            }
            ''
              export HOME="$(realpath .)"
              # The nix derivation must be able to find all used inputs in the nix-store because it cannot download it during buildTime.
              nix-unit --eval-store "$HOME" \
                --extra-experimental-features flakes \
                --override-input nixpkgs ${nixpkgs} \
                --flake ${self}#tests
              touch $out
            '';
      });
    };
}
