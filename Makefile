# Makefile para gestão simplificada do ambiente AutoSOC+ (v2.0)
# Comentários iniciados com ## serão usados para gerar a ajuda.

.DEFAULT_GOAL := help

# Cores para o output
GREEN  := $(shell tput -T xterm setaf 2)
YELLOW := $(shell tput -T xterm setaf 3)
RESET  := $(shell tput -T xterm sgr0)

## GESTÃO DO AMBIENTE
up: ## Inicia a VM e provisiona todos os serviços (Wazuh, etc.). O comando principal.
	@echo "$(YELLOW)-> Iniciando e provisionando o ambiente AutoSOC+...$(RESET)"
	@echo "$(YELLOW)-> Este processo é automático e pode demorar vários minutos na primeira vez.$(RESET)"
	vagrant up --provision
	@echo ""
	@echo "$(GREEN)Ambiente iniciado! Use 'make status' para ver os serviços.$(RESET)"
	@echo "A password do Wazuh foi guardada em 'wazuh_admin_password.txt'."

down: ## Para a máquina virtual (sem apagar os dados).
	@echo "$(YELLOW)-> Parando a VM...$(RESET)"
	vagrant halt

destroy: ## ATENÇÃO: Destrói a VM completamente. Todos os dados dentro da VM serão perdidos.
	@read -p "Tem a certeza que quer destruir a VM? [y/N] " choice; \
	if [ "$$choice" = "y" ] || [ "$$choice" = "Y" ]; then \
		echo "$(YELLOW)-> Destruindo a VM...$(RESET)"; \
		vagrant destroy -f; \
	else \
		echo "Operação cancelada."; \
	fi

ssh: ## Conecta-se à máquina virtual via SSH para executar comandos manuais.
	vagrant ssh

## GESTÃO DOS SERVIÇOS E TESTES
status: ## Mostra o estado de todos os contentores Docker (Wazuh, Suricata, etc.).
	@echo "$(YELLOW)-> Verificando o estado dos serviços Docker dentro da VM...$(RESET)"
	@vagrant ssh -c "cd /vagrant && docker compose ps"

logs: ## Mostra os logs de TODOS os serviços em tempo real. Pressione Ctrl+C para sair.
	@echo "$(YELLOW)-> A mostrar os logs de todos os serviços. Pressione Ctrl+C para sair.$(RESET)"
	vagrant ssh -c "cd /vagrant && docker compose logs -f"

test: ## Executa testes de conectividade para garantir que os serviços principais estão a funcionar.
	@echo "$(YELLOW)-> Executando testes de conectividade nos serviços...$(RESET)"
	@passed=0; \
	services_to_test="Wazuh:https://localhost:5601 Prometheus:http://localhost:9090 Grafana:http://localhost:3000 FlaskUI:http://localhost:5000"; \
	for service in $$services_to_test; do \
		name=$${service%%:*}; \
		url=$${service#*:}; \
		printf "  - Testando %-12s em %-25s..." "$$name" "$$url"; \
		status=$$(curl -k -s -o /dev/null -w "%{http_code}" $$url); \
		if [ "$$status" -eq 200 ] || [ "$$status" -eq 302 ] || [ "$$status" -eq 401 ]; then \
			echo "$(GREEN)OK (Status: $$status)$(RESET)"; \
			passed=$$((passed+1)); \
		else \
			echo "$(RED)FALHOU (Status: $$status)$(RESET)"; \
		fi; \
	done;
	@echo "$(YELLOW)-> Testes concluídos.$(RESET)"


## AJUDA
help: ## Mostra esta mensagem de ajuda com todos os os comandos disponíveis.
	@echo "Comandos disponíveis para o ambiente AutoSOC+:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

.PHONY: up down destroy ssh status logs test help
