F ?= .
A ?= this.cached

file := $(F)
attr := $(A)

cache_name := coliasgroup

.PHONY: none
none:

.PHONY: clean
clean:

.PHONY: eval-all
eval-all:
	nix-instantiate -A this.all

.PHONY: push
push:
	nix-store -qR --include-outputs $$(nix-store -qd $$(nix-build $(file) -j1 -A $(attr) --no-out-link)) \
		| grep -v '\.drv$$' \
		| cachix push $(cache_name)

bv_project_dir := projects/binary-verification
bv_example_target_dir := $(bv_project_dir)/examples/seL4/target-dir
bv_test_target_dirs := $(bv_project_dir)/tmp/test-target-dirs
update_bv_test_target_dir_cmd = nix-build -A w.$(1) -o $(bv_test_target_dirs)/$(2)

update-bv-target-dirs:
	d=$$(nix-build -A w.example) && rm -rf $(bv_example_target_dir) && cp -r --no-preserve=mode,ownership $$d $(bv_example_target_dir)
	$(call update_bv_test_target_dir_cmd,focused,focused)
	$(call update_bv_test_target_dir_cmd,small,small)
	$(call update_bv_test_target_dir_cmd,smallTrace,small-trace)
	$(call update_bv_test_target_dir_cmd,big,big)
