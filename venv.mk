# remove default Makefile rules
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
.SUFFIXES:

THIS_MAKEFILE = $(lastword $(MAKEFILE_LIST))

PYTHON_VERSION ?= $(shell cat .python-version || echo "python3")
REQUIREMENTS_IN ?= $(shell ls requirements*.in)
REQUIREMENTS_TXT = $(REQUIREMENTS_IN:.in=.txt)


# public interface

# depend on this to ensure you have an up to date venv automatically
.PHONY: venv
venv: venv/ready

.PHONY: venv-format
venv-format:
	venv/bin/isort --skip venv .
	venv/bin/black --exclude venv .

.PHONY: venv-clean
venv-clean:
	rm -rf venv

.PHONY: venv-lint
venv-lint: private SHELL=/bin/bash
venv-lint: venv/ready
	@err=0; run() { echo "$$*" && "$$@" || err=1; } ;\
	run venv/bin/flake8 --exclude venv ;\
	run venv/bin/isort --check --skip venv . ;\
	run venv/bin/black --check --exclude venv . ;\
	exit $$err


# implementation rules, not meant to be invoked directly

# Create an up-to-date venv with the latest versions
# Note: currently this will not remove packages, you will to clean first
venv/ready: venv/basic $(REQUIREMENTS_TXT)
	venv/bin/pip install --upgrade $(addprefix -r , $(REQUIREMENTS_TXT))
	touch $@

# note: we do not explicitly depend on venv/basic here, or else when creating
# a venv, .txt files are always regenerated, which is undesirable. Instead, we 
# ensure it has been created manually in the target rules.
%.txt: %.in
	test -x venv/bin/pip-compile || $(MAKE) venv/basic
	venv/bin/pip install pip-tools toml
	venv/bin/pip-compile $<

venv/basic:
	virtualenv -p $(PYTHON_VERSION) venv
	venv/bin/pip install --upgrade pip
	touch $@


# TODO: example of self updating
.PHONY: venv-update
venv-update:
	echo wget https://github.com/path/to/current/venv.mk $(THIS_MAKEFILE)
	grep -q 'venv' .gitignore 2>/dev/null || echo 'venv' >> .gitignore
