let
  overlay = self: super: with self; {
    this = callPackage ./this {};
    pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
      (callPackage ./python-packages-extension.nix {})
      # HACK
      (self: super: {
        psutilForPython2 = self.psutil.overridePythonAttrs {
          disabled = false;
          doCheck = false;
        };
      })
    ];
  };

  pkgs = import ../nixpkgs/pkgs/top-level {
    localSystem = "x86_64-linux";
    overlays = [
      overlay
    ];
    config = {
      permittedInsecurePackages = [
        pkgs.python2.name
      ];
    };
  };

  inherit (pkgs) this;

in

this.defaultScope // # TODO consider dropping
this.scopes //
this //
{
  inherit this pkgs;
}
