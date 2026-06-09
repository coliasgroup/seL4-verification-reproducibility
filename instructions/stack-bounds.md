I want you to complete the implementation of this file:

projects/binary-verification/components/search/search-core/BV/Search/Core/StackBounds.hs

so that `(cd projects/binary-verification && nix-shell --run 'make new-harness')` passes.

Note that you are actually running in that nix shell, so all you should need to run is `cd projects/binary-verification && make new-harness`.

You may want to instrument `graph-refine` in your effort to understand it better. I've set up `nix-build -A wip.oldHarness` for that.

You can modify e.g. tmp/src/graph-refine/stack_logic.py and re-run `nix-build -A wip.oldHarness` to see the output. Uncomment `keepBigLogs = true;` to see SMT interaction in the `./trace` subdir of that derivation, but please do so sparingly to avoid using up too much disk space.

Please ask questions up front so that I can let you run unattended overnight.
