.PHONY: roles lint

help: ## Show this help.
	@grep -F -h "##" $(MAKEFILE_LIST) | grep -v grep | sed -e 's/\\$$//' | sed -e 's/##//'

roles: ## Pull roles
	rm -rf roles/galaxy
	ansible-galaxy collection install -r requirements.yml

lint: ## Runs ansible-lint against all roles in the playbook
	ansible-lint roles/custom
