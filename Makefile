# Makefile para facilitar a gestão do ambiente AutoSOC+

# Inicia a VM e todos os serviços Docker.
up:
	@echo "Iniciando a VM e a stack de serviços..."
	vagrant up --provision
	@echo "Aguardando 30 segundos para a VM estabilizar..."
	@powershell -Command "Start-Sleep -Seconds 30"
	
	@echo ""
	@echo "=================================================================="
	@echo "=== PASSO CRÍTICO: CONFIGURAÇÃO MANUAL DO WAZUH (CERTIFICADOS) ==="
	@echo "=================================================================="
	@echo "O Wazuh Indexer/Dashboard precisa de certificados SSL/TLS para funcionar."
	@echo "Estes precisam ser gerados e configurados MANUALMENTE AGORA."
	@echo ""
	@echo "1. Conecte-se à VM via SSH:"
	@echo "   make ssh"
	@echo ""
	@echo "2. Dentro da VM, navegue para a pasta 'wazuh-docker/single-node':"
	@echo "   cd /vagrant/wazuh-docker/single-node"
	@echo "   (NOTA: Se 'single-node' não existir, tente 'cd /vagrant/wazuh-docker/deployments/single-node' ou verifique o 'ls -F /vagrant/wazuh-docker'.)"
	@echo ""
	@echo "3. Edite o 'docker-compose.yml' para forçar as versões 4.8.0:"
	@echo "   nano docker-compose.yml"
	@echo "   (Altere 'image: wazuh/wazuh-indexer:' para 'wazuh/wazuh-indexer:4.8.0')"
	@echo "   (Faça o mesmo para 'wazuh-manager' e 'wazuh-dashboard')"
	@echo "   (Guarde e saia: Ctrl + X, Y, Enter)"
	@echo ""
	@echo "4. Gere os certificados e ANOTE A PASSWORD que aparecerá na consola:"
	@echo "   docker compose -f generate-indexer-certs.yml run --rm generator"
	@echo "   (A password também será guardada em /vagrant/wazuh_admin_password.txt na VM, acessível no seu host)"
	@echo ""
	@echo "5. Inicie APENAS a stack do Wazuh (nesta mesma pasta 'single-node'):"
	@echo "   docker compose up -d"
	@echo ""
	@echo "6. Saia do SSH:"
	@echo "   exit"
	@echo ""
	@echo "=================================================================="
	@echo "=== DEPOIS DE COMPLETAR OS PASSOS ACIMA, CONTINUE NO HOST COM: ==="
	@echo "=================================================================="
	@echo "make continue-stack"
	@echo ""
	@exit 1 # Força o make up a falhar aqui, para que o utilizador execute os passos manuais

continue-stack:
	@echo "Continuando a iniciar o restante da stack (Prometheus, Grafana, Suricata, Flask UI)..."
	vagrant ssh -c "cd /vagrant && docker compose up -d"
	@echo ""
	@echo "[✔] AutoSOC+ configurado e iniciado!"
	@echo "[i] Acesse os serviços via navegador:"
	@echo "   - https://localhost:5601 (Wazuh Dashboard - use a password que anotou!)"
	@echo "   - http://localhost:9090 (Prometheus)"
	@echo "   - http://localhost:3000 (Grafana - user: admin, pass: admin)"
	@echo "   - http://localhost:5000 (Flask UI)"

# Para a VM e todos os serviços.
down:
	@echo "Parando todos os serviços Docker na VM..."
	vagrant ssh -c "cd /vagrant && docker compose down"
	@echo "Parando a VM..."
	vagrant halt

# Destrói a VM completamente.
destroy:
	@echo "Destruindo a VM! Todos os dados serão perdidos."
	vagrant destroy -f

# Conecta-se à VM via SSH.
ssh:
	vagrant ssh

# Mostra o estado dos contentores Docker.
status:
	@echo "Verificando o estado dos contentores..."
	vagrant ssh -c "cd /vagrant && docker compose ps"

# Mostra os logs de todos os serviços.
logs:
	vagrant ssh -c "cd /vagrant && docker compose logs -f"
