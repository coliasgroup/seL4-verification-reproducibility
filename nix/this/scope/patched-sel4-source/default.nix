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
  '' + lib.optionalString (scopeConfig.extraKernelCFlags != []) ''
    substituteInPlace CMakeLists.txt \
      --replace '-fno-stack-protector' '-fno-stack-protector ${
        lib.concatStringsSep " " scopeConfig.extraKernelCFlags
      }'
  '';

  installPhase = ''
    cp -r . $out
  '';
}
