_: {
  # Used to find the project root
  projectRootFile = "flake.lock";

  programs.clang-format.enable = true;

  programs.deadnix.enable = true;
  programs.statix.enable = true;
  programs.nixfmt-rfc-style.enable = true;

  settings.formatter = {
    clang-format = { };
  };
}
