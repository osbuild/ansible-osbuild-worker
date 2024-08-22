.PHONY: help
help:
	@echo 'Usage:'
	@echo '  make <target>'
	@echo ''
	@echo 'Generic targets:'
	@awk 'match($$0, /^([a-zA-Z_\/-]+):.*?## (.*)$$/, m) {printf "  \033[36m%-30s\033[0m %s\n", m[1], m[2]}' $(MAKEFILE_LIST) | sort
	@echo ''
	@echo 'Special targets:'
	@for T in $(SCENARIOS); do \
	  printf "  \033[36mtests-%-24s\033[0m Only run the scenario '%s'\n" $$T $$T; \
	done

# using docker here to be close to the github actions
CONTAINER_EXECUTABLE?=docker

SCENARIOS := aws aws-extended azure azure-extended default default-extended \
             errors force-restart force-restart-check-mode gcp gcp-extended \
             koji proxy restart-on-config-change

# here we only test one target
# for other options, please have a look at
# .github/workflows/tests.yml  jobs->test->strategy->matrix
# and override with these environment variables:
MATRIX_IMAGE_NAMESPACE?=quay.io/fedora
MATRIX_IMAGE_NAME?=fedora
MATRIX_IMAGE_TAG?=latest
MATRIX_IMAGE_ADDITIONAL_PACKAGES?=""
# note:
# MATRIX_IMAGE_TAG=rawhide needs this
# MATRIX_IMAGE_ADDITIONAL_PACKAGES?=python3 python3-libdnf5

# Host executing the tests
MOLECULE_HOST_CONTAINER_NAMESPACE?=quay.io/fedora
MOLECULE_HOST_CONTAINER_NAME?=fedora
MOLECULE_HOST_CONTAINER_TAG?=latest

# Host executing the linter
ANSIBLE_LINT_HOST_CONTAINER_NAMESPACE?=$(MOLECULE_HOST_CONTAINER_NAMESPACE)
ANSIBLE_LINT_HOST_CONTAINER_NAME?=$(MOLECULE_HOST_CONTAINER_NAME)
ANSIBLE_LINT_HOST_CONTAINER_TAG?=$(MOLECULE_HOST_CONTAINER_TAG)

.PHONY: lint-container
lint-container: # internal rule to build the ansible-lint "host"
	$(CONTAINER_EXECUTABLE) build -f scripts/Containerfile.ansible-lint \
	  --build-arg ANSIBLE_LINT_HOST_CONTAINER_NAMESPACE=$(ANSIBLE_LINT_HOST_CONTAINER_NAMESPACE) \
	  --build-arg ANSIBLE_LINT_HOST_CONTAINER_NAME=$(ANSIBLE_LINT_HOST_CONTAINER_NAME) \
	  --build-arg ANSIBLE_LINT_HOST_CONTAINER_TAG=$(ANSIBLE_LINT_HOST_CONTAINER_TAG) \
	  -t ansible-osbuild-worker-ansible-lint .

.PHONY: lint
lint: lint-container ## run ansible lint
	$(CONTAINER_EXECUTABLE) run --rm -ti -v .:/app ansible-osbuild-worker-ansible-lint ansible-lint

.PHONY: lint-fix
lint-fix: lint-container ## run ansible lint and fix easy findings
	$(CONTAINER_EXECUTABLE) run --rm -ti -v .:/app ansible-osbuild-worker-ansible-lint ansible-lint --fix

.PHONY: tests
.ONESHELL:
test-scenario: # Internal rule to execute a given $(scenario)
	$(CONTAINER_EXECUTABLE) build -f scripts/Containerfile.moleculehost \
	  --build-arg MOLECULE_HOST_CONTAINER_NAMESPACE=$(MOLECULE_HOST_CONTAINER_NAMESPACE) \
	  --build-arg MOLECULE_HOST_CONTAINER_NAME=$(MOLECULE_HOST_CONTAINER_NAME) \
	  --build-arg MOLECULE_HOST_CONTAINER_TAG=$(MOLECULE_HOST_CONTAINER_TAG) \
	  -t ansible-osbuild-worker-tests .

	$(CONTAINER_EXECUTABLE) run --rm -ti --privileged --volume /sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host \
	  -e HOME="/app" \
	  -e image="$(MATRIX_IMAGE_NAME)" \
	  -e namespace="$(MATRIX_IMAGE_NAMESPACE)" \
	  -e tag="$(MATRIX_IMAGE_TAG)" \
	  -e additional_packages="$(MATRIX_IMAGE_ADDITIONAL_PACKAGES)" \
	  -e PY_COLORS=1 \
	  -e ANSIBLE_FORCE_COLOR=1 \
	  -e MOLECULE_NO_LOG="false" \
	  -v .:/app/.ansible/roles/ansible-osbuild-worker:z \
	  -v ./molecule:/app/molecule:z \
	  ansible-osbuild-worker-tests \
	  molecule test -d podman -s "$(scenario)"

# Generate targets dynamically for each scenario
$(foreach SCENARIO,$(SCENARIOS),$(eval .PHONY: tests-$(SCENARIO)))
$(foreach SCENARIO,$(SCENARIOS),$(eval tests-$(SCENARIO): ; $(MAKE) test-scenario scenario=$(SCENARIO)))

.PHONY: test-all
test-all: $(foreach SCENARIO,$(SCENARIOS),tests-$(SCENARIO)) ## Run all scenarios

.PHONY: test
test: ## Run only the default scenario
	$(MAKE) test-scenario scenario=default

.PHONY: push-check
push-check: tests lint ## Replicates the github workflow checks as close as possible
