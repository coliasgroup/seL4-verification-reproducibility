{ lib
, stdenvNoCC
, python3
, cmake
, scopeConfig
}:

stdenvNoCC.mkDerivation {
  name = "sel4-source";

  src = scopeConfig.seL4Source;

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  nativeBuildInputs = [
    python3
    cmake
  ];

  postPatch = ''
    patchShebangs .
  '' + /* HACK: */ lib.optionalString (
    scopeConfig.arch == "ARM"
      && scopeConfig.targetCC.version == "14.2.0"
  ) ''
    substituteInPlace CMakeLists.txt \
      --replace '-fno-stack-protector' '-fno-stack-protector -fno-jump-tables'
  '';

  installPhase = ''
    cp -r . $out
  '';
}
