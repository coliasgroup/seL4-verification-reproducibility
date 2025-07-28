F ?= .
A ?= this.cached

file := $(F)
attr := $(A)

cache_name := coliasgroup

display := display

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(display)

.PHONY: eval-all
eval-all:
	nix-instantiate -A this.all

.PHONY: push
push:
	nix-store -qR --include-outputs $$(nix-store -qd $$(nix-build $(file) -j1 -A $(attr) --no-out-link)) \
		| grep -v '\.drv$$' \
		| cachix push $(cache_name)

$(display):
	mkdir -p $@

$(display)/status: | $(display)
	src=$$(nix-build -j1 -A this.displayStatus --no-out-link) && \
	dst=$@ && \
	rm -rf $$dst && \
	cp -rL --no-preserve=owner,mode $$src $$dst

show-coverage-diff: $(display)/status
	diff \
		<(grep -e '^Skipping' -e '^Aborting' docker-archaeology/release-12.0.0/target-sample/target/ARM-O1/coverage.txt | sort) \
		<(grep -e '^Skipping' -e '^Aborting' $(display)/status/ARM-O1/coverage.txt | sort) \
	|| true

bv_project_dir := projects/bv-sandbox
bv_example_target_dir := $(bv_project_dir)/examples/seL4/target-dir
bv_test_target_dirs := $(bv_project_dir)/tmp/test-target-dirs
update_bv_test_target_dir_cmd = nix-build -A wip.$(1) -o $(bv_test_target_dirs)/$(1)

update-bv-target-dirs:
	d=$$(nix-build -A wip.example) && rm -rf $(bv_example_target_dir) && cp -r --no-preserve=mode,ownership $$d $(bv_example_target_dir)
	$(call update_bv_test_target_dir_cmd,focused)
	$(call update_bv_test_target_dir_cmd,small)
	$(call update_bv_test_target_dir_cmd,big)
