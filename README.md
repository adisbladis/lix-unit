# lix-unit

> [!NOTE]
> This is a fork of nix-unit that works with Lix.

This project runs an attribute set of tests compatible with `lib.debug.runTests` while allowing individual attributes to fail.

![](./.github/demo.gif)

## Why use lix-unit?

- Simple structure compatible with `lib.debug.runTests`

- Allows individual test attributes to fail individually.

Rather than evaluating the entire test suite in one go, serialise & compare `lix-unit` uses the Nix evaluator C++ API.
Meaning that we can catch test failures individually, even if the failure is caused by an evaluation error.

- Fast.

No additional processing and coordination overhead caused by the external process approach.

## Comparison with other tools
This comparison matrix was originally taken from [Unit test your Nix code](https://www.tweag.io/blog/2022-09-01-unit-test-your-nix-code/) but has been adapted.
Pythonix is excluded as it's unmaintained.

| Tool        | Can test eval failures | Tests defined in Nix | in nixpkgs | snapshot testing(1) | Supports Lix |
| ----------- | ---------------------- | -------------------- | ---------- |-------------------- | ------------ |
| Lix-unit    | yes                    | yes                  | no         | no                  | yes          |
| Nix-unit    | yes                    | yes                  | yes        | no                  | no           |
| runTests    | no                     | yes                  | yes        | no                  | yes          |
| Nixt        | no                     | yes                  | no         | no                  | yes          |
| Namaka      | no                     | yes                  | yes        | yes                 | ?            |

1. [Snapshot testing](https://github.com/nix-community/namaka#snapshot-testing)

## Documentation

https://adisbladis.github.io/lix-unit/
