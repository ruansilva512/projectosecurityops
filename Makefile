# Makefile para gestão simplificada do ambiente AutoSOC+
# Comentários iniciados com ## serão usados para gerar a ajuda.

.DEFAULT_GOAL := help

## GESTÃO DO AMBIENTE
up: ## Inicia a VM e provisiona todos os serviços (Wazuh, etc.). O comando principal.
	@echo "-> Iniciando e provisionando o ambiente AutoSOC+..."
	@echo "-> Este processo é automático e pode demorar vários minutos na primeira vez."
	vagrant up --provision
	@echo ""
	@echo "Ambiente iniciado! Use 'make status' para ver os serviços."
	@echo "A password do Wazuh foi guardada em 'wazuh_admin_password.txt'."

down: ## Para a máquina virtual (sem apagar os dados).
	@echo "-> Parando a VM..."
	vagrant halt

destroy: ## ATENÇÃO: Destrói a VM completamente. Todos os dados dentro da VM serão perdidos.
	@read -p "Tem a certeza que quer destruir a VM? [y/N] " choice; \
	if [ "$$choice" = "y" ] || [ "$$choice" = "Y" ]; then \
		echo "-> Destruindo a VM..."; \
		vagrant destroy -f; \
	else \
		echo "Operação cancelada."; \
	fi

ssh: ## Conecta-se à máquina virtual via SSH para executar comandos manuais.
	vagrant ssh

## GESTÃO DOS SERVIÇOS (DOCKER)
status: ## Mostra o estado de todos os contentores Docker (Wazuh, Suricata, etc.).
	@echo "-> Verificando o estado dos serviços Docker dentro da VM..."
	@vagrant ssh -c "cd /vagrant && docker compose ps"

logs: ## Mostra os logs de TODOS os serviços em tempo real. Pressione Ctrl+C para sair.
	@echo "-> A mostrar os logs de todos os serviços. Pressione Ctrl+C para sair."
	vagrant ssh -c "cd /vagrant && docker compose logs -f"

logs-wazuh: ## Mostra os logs apenas do Wazuh-Manager.
	@echo "-> A mostrar os logs do Wazuh-Manager. Pressione Ctrl+C para sair."
	vagrant ssh -c "cd /vagrant && docker compose logs -f wazuh-manager"

logs-suricata: ## Mostra os logs apenas do Suricata.
	@echo "-> A mostrar os logs do Suricata. Pressione Ctrl+C para sair."
	vagrant ssh -c "cd /vagrant && docker compose logs -f suricata"

## AJUDA
help: ## Mostra esta mensagem de ajuda com todos os comandos disponíveis.
	@echo "Comandos disponíveis para o ambiente AutoSOC+:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

.PHONY: up down destroy ssh status logs logs-wazuh logs-suricata help
