
{ lib
, haskell
}:

(haskell.packages.ghc94.override {
  overrides = self: super: {
    mtl = self.callPackage ./mtl_2_2_2.nix {};
  };
}).ghcWithPackages (p: with p; [
  mtl
])
