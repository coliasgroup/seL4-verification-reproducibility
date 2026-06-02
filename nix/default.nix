let
  overlay = self: super: with self; {
    this = callPackage ./this {};
    pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
      (callPackage ./python-packages-extension.nix {})
    ];
  };

  args = {
    localSystem = "x86_64-linux";
    overlays = [
      overlay
      (self: super: {
        inherit oldPkgs;
      })
    ];
    config = {
      permittedInsecurePackages = [
        pkgs.python2.name
      ];
    };
  };

  pkgs = import ../nixpkgs/pkgs/top-level args;

  oldPkgs =
    let
      rev = "574d1eac1c200690e27b8eb4e24887f8df7ac27c";
      source = builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
        sha256 = "sha256:0s6h7r9jin9sd8l85hdjwl3jsvzkddn3blggy78w4f21qa3chymz";
      };
    in import source args;

  inherit (pkgs) this;

in

this.defaultScope // # TODO consider dropping
this.scopes //
this //
{
  inherit this pkgs;
}
