define RUN_ANSIBLE
( \
	export ANSIBLE_LOG_PATH=$(ANSIBLE_LOG_PATH); \
	. $(VENV_PATH)/bin/activate; \
	ansible-playbook -i $(INVENTORY) $(VAULT_OPT) $(ARGS) playbook.yml; \
)
endef

#
# Configurable variables
#

# Path to the Python virtual environment
VENV_PATH ?= .venv

# Ansible log path
ANSIBLE_LOG_PATH ?= log/ansible.log

# Name of the inventory file
INVENTORY ?= inventory

VAULT_FILE ?= group_vars/vault.yml
USEVAULT ?= 1

ifeq ($(USEVAULT),1)
VAULT_OPT := --ask-vault-pass
else
VAULT_OPT :=
endif

default: setup-all

#
# Python environment
#

.venv:
	python3 -m venv $(VENV_PATH)

.PHONY: python-setup
python-setup: .venv
	. $(VENV_PATH)/bin/activate \
		&& pip install --upgrade pip \
		&& pip install -r requirements.txt \
		&& ansible-galaxy collection install -r requirements.yml
#
# Tests
#

.PHONY: ping
ping: .venv
	. $(VENV_PATH)/bin/activate && \
		ansible -i $(INVENTORY) all -m ping

#
# Targets
#

.PHONY: setup-all
setup-all: .venv check-vault
	$(RUN_ANSIBLE)

.PHONY: check-vault
check-vault:
	@if [ "$(USEVAULT)" = "1" ] && [ ! -f "$(VAULT_FILE)" ]; then \
		echo "Missing $(VAULT_FILE). Create it from group_vars/vault.yml.example and encrypt it."; \
		exit 1; \
	fi
	@if [ "$(USEVAULT)" = "1" ] && [ -f "$(VAULT_FILE)" ] && ! head -n 1 "$(VAULT_FILE)" | grep -q '^\$$ANSIBLE_VAULT;'; then \
		echo "$(VAULT_FILE) must be encrypted with ansible-vault."; \
		exit 1; \
	fi

.PHONY: registry
registry: .venv check-vault
	$(eval ARGS := --tags "registry" -v)
	$(RUN_ANSIBLE)

.PHONY: images
images: .venv check-vault
	$(eval ARGS := --tags "images" -v)
	$(RUN_ANSIBLE)

.PHONY: services
services: .venv check-vault
	$(eval ARGS := --tags "services" -v)
	$(RUN_ANSIBLE)

.PHONY: deploy
deploy: .venv check-vault
	$(eval ARGS := --tags "deploy" -v)
	$(RUN_ANSIBLE)
