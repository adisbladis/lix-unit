{
  stdenv,
  lib,
  srcDir ? null,
  boost,
  clang-tools,
  cmake,
  difftastic,
  makeWrapper,
  meson,
  ninja,
  lix,
  nlohmann_json,
  pkg-config,
}:

let
  filterMesonBuild = builtins.filterSource (
    path: type: type != "directory" || baseNameOf path != "build"
  );
in
stdenv.mkDerivation {
  pname = "lix-unit";
  version = "2.90.0";
  src = if srcDir == null then filterMesonBuild ./. else srcDir;
  buildInputs = [
    nlohmann_json
    lix
    boost
  ];
  nativeBuildInputs = [
    makeWrapper
    meson
    pkg-config
    ninja
    # nlohmann_json can be only discovered via cmake files
    cmake
  ] ++ (lib.optional stdenv.cc.isClang [ clang-tools ]);

  postInstall = ''
    wrapProgram "$out/bin/nix-unit" --prefix PATH : ${difftastic}/bin
  '';

  meta = {
    description = "Lix unit test runner";
    homepage = "https://github.com/adisbladis/lix-unit";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ adisbladis ];
    platforms = lib.platforms.unix;
    mainProgram = "nix-unit";
  };
}
