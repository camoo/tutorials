# === WordPress on Docker — Makefile ===
# Usage: `make help` to see all commands

SHELL := /bin/bash
.ONESHELL:
.DEFAULT_GOAL := help

# --- Config (override via env or make VAR=value) ---
COMPOSE        ?= docker compose
PROJECT        ?= wpdemo
CERT_DIR       ?= .certs
CERT_HOSTS     ?= wp.localhost pma.localhost
TRAEFIK_CERT   ?= $(CERT_DIR)/wp.localhost-cert.pem
TRAEFIK_KEY    ?= $(CERT_DIR)/wp.localhost-key.pem
URL_WP         ?= https://wp.localhost:8443
URL_PMA        ?= https://pma.localhost:8443
DASHBOARD_URL  ?= http://localhost:8088

# --- Helpers ---
define CHECK_TOOL
	@command -v $(1) >/dev/null 2>&1 || { echo "Error: '$(1)' not found. Please install it."; exit 1; }
endef

define PRINT_LINE
	@printf '\033[1;36m==> %s\033[0m\n' "$(1)"
endef


# --- Targets ---
.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nCommands:\n"} /^[a-zA-Z0-9_.-]+:.*?##/ {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2} /^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0,5)} ' $(MAKEFILE_LIST)

##@ One-time setup

.PHONY: certs
certs: ## Generate local TLS certs with mkcert for wp.localhost & pma.localhost
	$(call CHECK_TOOL,mkcert)
	$(call PRINT_LINE,Generating local CA (if needed))
	mkcert -install
	$(call PRINT_LINE,Creating certs in $(CERT_DIR))
	mkdir -p $(CERT_DIR)
	mkcert -key-file $(TRAEFIK_KEY) -cert-file $(TRAEFIK_CERT) $(CERT_HOSTS)
	@ls -lh $(TRAEFIK_CERT) $(TRAEFIK_KEY)

##@ Compose lifecycle

.PHONY: build
build: ## Build images
	$(call PRINT_LINE, Building images)
	$(COMPOSE) -p $(PROJECT) build

.PHONY: up
up: ## Start stack (detached)
	$(call PRINT_LINE, Starting services)
	$(COMPOSE) -p $(PROJECT) up -d

.PHONY: down
down: ## Stop stack (keep volumes)
	$(call PRINT_LINE, Stopping services)
	$(COMPOSE) -p $(PROJECT) down

.PHONY: restart
restart: ## Restart stack
	$(MAKE) down
	$(MAKE) up

.PHONY: ps
ps: ## List containers
	$(COMPOSE) -p $(PROJECT) ps

.PHONY: logs
logs: ## Tail all logs
	$(COMPOSE) -p $(PROJECT) logs -f

.PHONY: logs-wp
logs-wp: ## Tail WordPress logs
	$(COMPOSE) -p $(PROJECT) logs -f wordpress

.PHONY: logs-traefik
logs-traefik: ## Tail Traefik logs
	$(COMPOSE) -p $(PROJECT) logs -f traefik

##@ Developer goodies

.PHONY: open
open: ## Open WP + phpMyAdmin in browser
	$(call PRINT_LINE, Opening $(URL_WP) and $(URL_PMA))
	@command -v xdg-open >/dev/null && xdg-open "$(URL_WP)" || true
	@sleep 1
	@command -v xdg-open >/dev/null && xdg-open "$(URL_PMA)" || true
	@echo "Traefik dashboard: $(DASHBOARD_URL)"

.PHONY: wp-cli
wp-cli: ## Run arbitrary WP-CLI, e.g. `make wp-cli ARGS="plugin list"`
	@test -n "$(ARGS)" || { echo "Usage: make wp-cli ARGS=\"plugin list\""; exit 2; }
	$(COMPOSE) -p $(PROJECT) exec -it wordpress wp --path=/var/www/html --allow-root $(ARGS)

.PHONY: wp-shell
wp-shell: ## Bash into WordPress container
	$(COMPOSE) -p $(PROJECT) exec -it wordpress bash

.PHONY: db-shell
db-shell: ## MySQL shell inside db container
	$(COMPOSE) -p $(PROJECT) exec -it db mysql -u$${MYSQL_USER:-wpuser} -p$${MYSQL_PASSWORD:-secret} $${MYSQL_DATABASE:-wordpress}

.PHONY: pma
pma: ## Open phpMyAdmin
	@command -v xdg-open >/dev/null && xdg-open "$(URL_PMA)" || echo "phpMyAdmin: $(URL_PMA)"

##@ Cleanup

.PHONY: clean
clean: ## Remove containers + anonymous networks (keep volumes)
	$(call PRINT_LINE,Compose down (no volumes))
	$(COMPOSE) -p $(PROJECT) down

.PHONY: reset
reset: ## Full reset (containers + volumes) — DANGEROUS
	$(call PRINT_LINE, Full reset: removing containers and volumes)
	$(COMPOSE) -p $(PROJECT) down -v

.PHONY: prune
prune: ## Docker prune (dang! removes unused images/networks)
	$(call PRINT_LINE, Docker system prune (confirming))
	docker system prune -f

.PHONY: wp-install
wp-install: ## Install WP using values from .env
	@set -a; . .env; set +a; \
	$(COMPOSE) -p $(PROJECT) exec -T wordpress wp core install \
	  --url="$$WP_URL" \
	  --title="$$WP_TITLE" \
	  --admin_user="$$WP_ADMIN_USER" \
	  --admin_password="$$WP_ADMIN_PASS" \
	  --admin_email="$$WP_ADMIN_EMAIL" \
	  --path=/var/www/html \
	  --allow-root \
	  --skip-email
