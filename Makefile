# Makefile para gerenciar o ambiente AutoSOC+

# Declara alvos que não correspondem a nomes de ficheiros.
.PHONY: up iniciar down destroy ssh status logs

# Inicia a VM e todas as stacks Docker.
up:
	@echo "Iniciando a VM e os serviços..."
	vagrant up --provision
	# Pausa para a VM estabilizar, essencial para Windows.
	@powershell -Command "Start-Sleep -Seconds 30"

	@echo "Preparando arquivos de configuração do Wazuh na VM..."
	vagrant ssh -c "rm -f /vagrant/wazuh-docker/single-node/docker-compose.yml"
	vagrant ssh -c "cp /vagrant/ficheiro/docker-compose.yml /vagrant/wazuh-docker/single-node/docker-compose.yml"
	vagrant ssh -c "mkdir -p /vagrant/wazuh-docker/certs && chmod 777 /vagrant/wazuh-docker/certs"

	@echo "Gerando certificados do Wazuh Indexer..."
	vagrant ssh -c "cd /vagrant/wazuh-docker/single-node && docker compose -f generate-indexer-certs.yml run --rm generator"

	@echo "Iniciando a stack do Wazuh..."
	vagrant ssh -c "cd /vagrant/wazuh-docker/single-node && docker compose up -d"

	@echo "Iniciando a stack adicional (Prometheus, Grafana, Suricata, Flask UI)..."
	vagrant ssh -c "cd /vagrant && docker compose up -d"

	@echo "✅ Ambiente AutoSOC+ iniciado com sucesso."

# Inicia apenas a stack adicional (Prometheus, Grafana, Suricata, Flask UI).
iniciar:
	@echo "Continuando a iniciar o restante da stack (Prometheus, Grafana, Suricata, Flask UI)..."
	vagrant ssh -c "cd /vagrant && docker compose up -d"
	@echo ""
	@echo "[✔] AutoSOC+ configurado e iniciado!"
	@echo "[i] Acesse os serviços via navegador:"
	@echo "   - https://localhost:5601 (Wazuh Dashboard - use a password que anotou!)"
	@echo "   - http://localhost:9090 (Prometheus)"
	@echo "   - http://localhost:3000 (Grafana - user: admin, pass: admin)"
	@echo "   - http://localhost:5000 (Flask UI)"

# Para todos os serviços Docker e desliga a VM.
desligar:
	@echo "Parando todos os serviços Docker na VM..."
	vagrant ssh -c "cd /vagrant && docker compose down || true"
	vagrant ssh -c "cd /vagrant/wazuh-docker/single-node && docker compose down || true"
	@echo "Parando a VM..."
	vagrant halt

# Destrói a VM completamente, removendo todos os dados.
destruir:
	@echo "Destruindo a VM! Todos os dados serão perdidos."
	vagrant destroy -f

# Conecta-se à VM via SSH.
ssh:
	vagrant ssh

# Mostra o estado de todos os contêineres Docker.
status:
	@echo "Verificando o estado dos contêineres..."
	vagrant ssh -c "cd /vagrant/wazuh-docker/single-node && docker compose ps || true"
	vagrant ssh -c "cd /vagrant && docker compose ps || true"

# Mostra os logs em tempo real de todos os serviços.
logs:
	@echo "Mostrando logs da stack Wazuh..."
	vagrant ssh -c "cd /vagrant/wazuh-docker/single-node && docker compose logs -f"
	@echo "Mostrando logs da stack adicional..."
	vagrant ssh -c "cd /vagrant && docker compose logs -f"
