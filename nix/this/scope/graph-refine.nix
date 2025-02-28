{ lib
, runCommand
, python2Packages
, python3Packages
, git
, ncurses

, scopeConfig
, kernel
, preprocessedKernelsAreEquivalent
, cFunctionsTxt
, asmFunctionsTxt
, graphRefineSolverLists
, graphRefineSource
, smtfmt-in-place
}:

{ name ? null
, extraNativeBuildInputs ? []
, solverList ? graphRefineSolverLists.default
, source ? graphRefineSource
, args ? []
, argLists ? [ args ]
, dontDecorateCommands ? false
, decorateCommand ? if dontDecorateCommands then lib.id else (command: "(time ${command}) 2>&1 | tee log.txt")
, commands ? lib.flip lib.concatMapStrings argLists (argList: ''
    ${decorateCommand "python ${source}/graph-refine.py . ${lib.concatStringsSep " " argList}"}
  '')
, keepBigLogs ? false
, prettifyBigLogs ? false
, stackBounds ? null
}:

let
  targetPy = source + "/seL4-example/target.py";

  targetDir = runCommand "graph-refine-initial-target-dir" {
    inherit preprocessedKernelsAreEquivalent;
  } (''
    mkdir $out
    cp ${kernel}/{kernel.elf.rodata,kernel.elf.txt,kernel.elf.symtab} $out
    cp ${cFunctionsTxt} $out/CFunctions.txt
    cp ${asmFunctionsTxt} $out/ASMFunctions.txt
    cp ${targetPy} $out/target.py
  '' + lib.optionalString (stackBounds != null) ''
    cp ${stackBounds} $out/StackBounds.txt
  '');

in
runCommand "graph-refine${lib.optionalString (name != null) "-${name}"}-${scopeConfig.bvName}" {
  nativeBuildInputs = [
    python2Packages.python
    python2Packages.typing
    python2Packages.enum
    python2Packages.psutilForPython2
    git
  ] ++ lib.optionals keepBigLogs [
    smtfmt-in-place
  ] ++ extraNativeBuildInputs;

  # avoid warnings from solvers
  TERMINFO = "${ncurses.out}/share/terminfo/";

  passthru = {
    inherit
      solverList
      preprocessedKernelsAreEquivalent
      targetDir
    ;
  };
} ''
  cp -r --no-preserve=owner,mode ${targetDir} target
  cd target
  ln -sf ${solverList} .solverlist

  ${commands}

  rm -f target.pyc

  ${if keepBigLogs then ''
    ${lib.optionalString prettifyBigLogs ''
      PYTHONPATH= find trace -name 'in.smt2' -exec smtfmt-in-place '{}' ';'
    ''}
  '' else ''
    rm -rf trace
  ''}

  cp -r . $out
''
