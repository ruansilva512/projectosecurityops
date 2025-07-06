# setup-environment-v3.ps1
#
# Versão 3.2 - Implementa configuração manual do Wazuh dentro do fluxo de trabalho.
# Este script cria todos os ficheiros necessários com o conteúdo completo.
#
# USO:
# 1. Crie uma pasta vazia. Salve este script lá dentro.
# 2. Abra o PowerShell como Administrador, navegue para a pasta.
# 3. Execute: Set-ExecutionPolicy Bypass -Scope Process -Force
# 4. Execute: .\setup-environment-v3.ps1

# --- Funções e Pré-requisitos ---
function Test-CommandExists {
    param($command)
    $exists = $false
    try {
        Get-Command $command -ErrorAction SilentlyContinue | Out-Null
        $exists = $true
    } catch { }
    return $exists
}

Write-Host "Iniciando a configuração do ambiente AutoSOC+ v3.2 (Unificado)..." -ForegroundColor Yellow

# 1. Instalar Pré-requisitos
$packages = @("git", "virtualbox", "vagrant", "make")
if (-not (Test-CommandExists 'choco')) {
    Write-Host "Chocolatey não encontrado. Instalando..." -ForegroundColor Green
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch {
        Write-Host "Erro ao instalar Chocolatey." -ForegroundColor Red; exit 1
    }
}
foreach ($pkg in $packages) {
    if (-not (Test-CommandExists $pkg)) {
        Write-Host "Instalando $pkg..." -ForegroundColor Green
        choco install $pkg -y --force
    } else {
        Write-Host "$pkg já está instalado." -ForegroundColor Green
    }
}
Write-Host "Pré-requisitos instalados." -ForegroundColor Cyan

# 2. Criar Estrutura de Pastas Completa
$baseDir = "$PSScriptRoot\autosoc-plus"
Write-Host "Criando estrutura do projeto em: $baseDir" -ForegroundColor Green
if (-not (Test-Path $baseDir)) { New-Item -ItemType Directory -Path $baseDir | Out-Null }
if (-not (Test-Path "$baseDir\config")) { New-Item -ItemType Directory -Path "$baseDir\config" | Out-Null }
if (-not (Test-Path "$baseDir\config\wazuh_cluster")) { New-Item -ItemType Directory -Path "$baseDir\config\wazuh_cluster" | Out-Null }
if (-not (Test-Path "$baseDir\flask_app")) { New-Item -ItemType Directory -Path "$baseDir\flask_app" | Out-Null }
if (-not (Test-Path "$baseDir\flask_app\templates")) { New-Item -ItemType Directory -Path "$baseDir\flask_app\templates" | Out-Null }
if (-not (Test-Path "$baseDir\suricata_logs")) { New-Item -ItemType Directory -Path "$baseDir\suricata_logs" | Out-Null }
if (-not (Test-Path "$baseDir\grafana\provisioning\datasources")) { New-Item -ItemType Directory -Path "$baseDir\grafana\provisioning\datasources" | Out-Null }
if (-not (Test-Path "$baseDir\grafana\provisioning\dashboards")) { New-Item -ItemType Directory -Path "$baseDir\grafana\provisioning\dashboards" | Out-Null }
if (-not (Test-Path "$baseDir\grafana\provisioning\dashboards\json")) { New-Item -ItemType Directory -Path "$baseDir\grafana\provisioning\dashboards\json" | Out-Null }

# --- DEFINIÇÃO DO CONTEÚDO DOS FICHEIROS ---

# Vagrantfile (Versão 3.2) - Usa aspas simples para evitar erro de parsing
$vagrantfileContent = @'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Usar a versão mais recente e estável do Ubuntu (22.04 LTS)
  config.vm.box = "ubuntu/jammy64"
  config.vm.boot_timeout = 900 # Aumentado o timeout para dar mais tempo para o boot da VM

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "10240" # Aumentado para 10GB para a stack completa do Wazuh
    vb.cpus = "4"
    vb.customize ["modifyvm", :id, "--nictype1", "82540EM"]
  end

  # Mapeamento de Portas
  config.vm.network "forwarded_port", guest: 443, host: 5601      # Wazuh/Kibana Dashboard
  config.vm.network "forwarded_port", guest: 9200, host: 9200    # Wazuh Indexer
  config.vm.network "forwarded_port", guest: 1514, host: 1514, protocol: "udp" # Wazuh Agent communication (UDP)
  config.vm.network "forwarded_port", guest: 1515, host: 1515    # Wazuh Agent communication (TCP)
  config.vm.network "forwarded_port", guest: 9090, host: 9090    # Prometheus
  config.vm.network "forwarded_port", guest: 3000, host: 3000    # Grafana
  config.vm.network "forwarded_port", guest: 5000, host: 5000    # Flask UI

  # Provisionador para instalar Docker e Git, e clonar o repositório Wazuh-Docker
  config.vm.provision "shell", inline: <<-SHELL
    #!/bin/bash
    echo "--- Instalando pré-requisitos na VM ---"
    apt-get update
    apt-get install -y git curl ca-certificates lsb-release

    if ! command -v docker &> /dev/null; then
        echo "--- Instalando Docker e Docker Compose ---"
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        usermod -aG docker vagrant
        echo "Docker instalado. Reiniciando o daemon Docker (se necessário)..."
        systemctl restart docker
    else
        echo "Docker já está instalado."
    fi

    echo "--- Clonando repositório wazuh-docker ---"
    cd /vagrant
    if [ ! -d "wazuh-docker" ]; then
      git clone https://github.com/wazuh/wazuh-docker.git
    else
      echo "Repositório wazuh-docker já existe."
    fi

    echo "--- Provisionamento básico da VM concluído. Configuração do Wazuh será manual. ---"
  SHELL
end
'@

# Docker-Compose (Versão 3.2) - Unificado e com versão Wazuh estável
# NOTA: Os volumes para a configuração do Wazuh (indexer.yml, wazuh.yml)
# e os certificados serão configurados manualmente dentro da VM.
$dockercomposeContent = @"
version: '3.8'

services:
  # Wazuh Stack - Usando a versão estável 4.8.0
  wazuh-indexer:
    image: wazuh/wazuh-indexer:4.8.0
    container_name: wazuh-indexer
    ports:
      - "9200:9200"
    volumes:
      # Os certificados serão gerados em /vagrant/wazuh-docker/certs e montados aqui
      - ./wazuh-docker/certs/certs.zip:/tmp/certs.zip:ro # Temporário para certs gerados
      - ./wazuh-docker/certs/ca.pem:/usr/share/wazuh-indexer/config/certs/ca.pem:ro
      - ./wazuh-docker/certs/admin.pem:/usr/share/wazuh-indexer/config/certs/admin.pem:ro
      - ./wazuh-docker/certs/admin-key.pem:/usr/share/wazuh-indexer/config/certs/admin-key.pem:ro
      - ./wazuh-docker/certs/indexer.pem:/usr/share/wazuh-indexer/config/certs/indexer.pem:ro
      - ./wazuh-docker/certs/indexer-key.pem:/usr/share/wazuh-indexer/config/certs/indexer-key.pem:ro
      - indexer_data:/usr/share/wazuh-indexer/data # Volume para dados persistentes
      # Configuração do Indexer (pode ser ajustada para incluir segurança se não for automático)
      - ./config/wazuh_cluster/wazuh-indexer.yml:/usr/share/wazuh-indexer/config/wazuh-indexer.yml:ro
    environment:
      # Aumentado a memória para o Indexer (deve ser ajustado conforme a RAM da VM)
      - "OPENSEARCH_JAVA_OPTS=-Xms4g -Xmx4g" 
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test: ["CMD-SHELL", "curl -s --max-time 3 -k https://localhost:9200 || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 50

  wazuh-manager:
    image: wazuh/wazuh-manager:4.8.0
    container_name: wazuh-manager
    depends_on:
      wazuh-indexer:
        condition: service_healthy # Espera o Indexer estar saudável
    ports:
      - "1514:1514/udp" # Agentes
      - "1515:1515/tcp" # Agentes (registration)
    volumes:
      - ./config/wazuh_cluster/wazuh.yml:/usr/share/wazuh-manager/etc/ossec.conf:ro # Configuração do manager
      - manager_data:/var/ossec # Volume para dados persistentes
      - ./wazuh-docker/certs/ca.pem:/var/ossec/etc/certs/ca.pem:ro
      - ./wazuh-docker/certs/manager.pem:/var/ossec/etc/certs/manager.pem:ro
      - ./wazuh-docker/certs/manager-key.pem:/var/ossec/etc/certs/manager-key.pem:ro
    healthcheck:
      test: ["CMD-SHELL", "/var/ossec/bin/wazuh-control status > /dev/null || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 50

  wazuh-dashboard:
    image: wazuh/wazuh-dashboard:4.8.0
    container_name: wazuh-dashboard
    depends_on:
      wazuh-indexer:
        condition: service_healthy # Espera o Indexer estar saudável
    ports:
      - "443:5601" # Acesso HTTPS ao Dashboard
    volumes:
      - ./config/wazuh_cluster/wazuh-dashboard.yml:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml:ro # Configuração do dashboard
      - ./wazuh-docker/certs/ca.pem:/usr/share/wazuh-dashboard/config/certs/ca.pem:ro
      - ./wazuh-docker/certs/dashboard.pem:/usr/share/wazuh-dashboard/config/certs/dashboard.pem:ro
      - ./wazuh-docker/certs/dashboard-key.pem:/usr/share/wazuh-dashboard/config/certs/dashboard-key.pem:ro
    environment:
      OPENSEARCH_HOSTS: '["https://wazuh-indexer:9200"]' # Acesso ao Indexer via nome de serviço Docker
      SERVER_HOST: '0.0.0.0' # Permite acesso externo
      # As credenciais admin/password são definidas durante a geração de certificados
    healthcheck:
      test: ["CMD-SHELL", "curl -s --max-time 3 -k https://localhost:5601 || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 50

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9090/-/healthy"]
      interval: 10s
      timeout: 5s
      retries: 5

  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    depends_on:
      - prometheus
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning # Para dashboards e datasources
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 10s
      timeout: 5s
      retries: 5
      
  # Security Tools
  suricata:
    image: jasonish/suricata:latest
    container_name: suricata
    network_mode: host # Apenas funciona em Linux hosts ou se a VM estiver em modo bridged
    cap_add:
      - NET_ADMIN
      - SYS_NICE
    volumes:
      - ./suricata_logs:/var/log/suricata # Para logs de saída
      # Exemplo de montagem de configuração Suricata (precisa de ser criada)
      # - ./config/suricata.yaml:/etc/suricata/suricata.yaml:ro
    # Comando de execução do Suricata (descomentar e configurar se necessário)
    # command: ["suricata", "-c", "/etc/suricata/suricata.yaml", "-i", "eth0"] # Exemplo: -i eth0 para monitorizar a interface eth0
    healthcheck:
      test: ["CMD-SHELL", "pgrep suricata > /dev/null || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3


  # UI Flask
  flask_ui:
    build: ./flask_app
    container_name: flask_ui
    ports:
      - "5000:5000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  indexer_data: # Volume para persistir os dados do OpenSearch
  manager_data: # Volume para persistir os dados do Wazuh Manager
"@

# Makefile - Facilitador de Comandos
$makefileContent = @"
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
	@echo "   (Altere 'image: wazuh/wazuh-indexer:${WAZUH_VERSION:-5.0.0}' para 'wazuh/wazuh-indexer:4.8.0')"
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
"@

# Prometheus Config
$prometheusContent = @"
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  alerting:
    alertmanagers:
      - static_configs:
          - targets: ['localhost:9093'] # Default Alertmanager port if configured
rule_files:
  - "alert.rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter' # Assume you might add a node_exporter later
    static_configs:
      - targets: ['localhost:9100'] # Default node_exporter port
  - job_name: 'cadvisor' # Assume you might add cadvisor for Docker metrics
    static_configs:
      - targets: ['localhost:8080'] # Default cAdvisor port
  - job_name: 'suricata_exporter' # If a Suricata Prometheus exporter is used
    static_configs:
      - targets: ['localhost:9175']
"@

# Prometheus Alert Rules
$alertRulesContent = @"
groups:
  - name: system-alerts
    rules:
      - alert: HighCPUUsage
        expr: rate(node_cpu_seconds_total{mode="system"}[1m]) > 0.8 # Adjusted threshold for typical VM usage
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Uso de CPU alto detectado na VM"
          description: "O uso do CPU do sistema excedeu 80% nos últimos 60 segundos."
      - alert: LowDiskSpace
        expr: node_filesystem_avail_bytes{fstype="ext4",mountpoint="/"} / node_filesystem_size_bytes{fstype="ext4",mountpoint="/"} < 0.10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pouco espaço em disco na VM"
          description: "Espaço em disco disponível em {{ $labels.mountpoint }} está abaixo de 10%."
      - alert: OutOfMemory
        expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.15
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Memória RAM baixa na VM"
          description: "Memória RAM disponível na VM está abaixo de 15%."
"@

# Grafana Provisioning (Datasource e Dashboard vazio por padrão)
$grafanaDatasourceContent = @"
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090 # 'prometheus' é o nome do serviço no docker-compose
    isDefault: true
    version: 1
    editable: true
"@

$grafanaDashboardsContent = @"
apiVersion: 1
providers:
  - name: 'Default' # Nome do provedor
    orgId: 1
    folder: '' # Pasta raiz para os dashboards
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards/json # Onde os arquivos JSON dos dashboards serão colocados
"@

# Flask App
$flaskAppContent = @"
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    services = {
        "Wazuh Dashboard": "https://localhost:5601",
        "Prometheus": "http://localhost:9090",
        "Grafana": "http://localhost:3000",
        "Flask UI (this page)": "http://localhost:5000"
    }
    return render_template('index.html', services=services)

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
"@

$flaskTemplateContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>AutoSOC+ Dashboard</title>
    <style>
        body { font-family: sans-serif; background-color: #f4f4f9; color: #333; }
        .container { max-width: 800px; margin: 40px auto; padding: 20px; background: #fff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #444; }
        ul { list-style-type: none; padding: 0; }
        li { margin-bottom: 10px; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>AutoSOC+ v3 Dashboard</h1>
        <p>Links de acesso rápido aos serviços:</p>
        <ul>
            {% for service, url in services.items() %}
                <li><strong>{{ service }}:</strong> <a href="{{ url }}" target="_blank">{{ url }}</a></li>
            {% endfor %}
        </ul>
    </div>
</body>
</html>
"@

$flaskDockerfileContent = @"
FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install Flask requests
EXPOSE 5000
CMD ["python", "app.py"]
"@

# Wazuh Indexer Config - Ficheiros de configuração vazios, mas necessários para os volumes.
# Estes ficheiros deverão ser preenchidos ou substituídos com as configurações corretas
# após a geração manual dos certificados Wazuh.
$wazuhIndexerContent = @"
# Este ficheiro é um placeholder.
# As configurações reais para o wazuh-indexer (Opensearch)
# incluem configurações de segurança, rede e caminhos para os certificados.
# Estas são geralmente geradas pelo script oficial de geração de certificados
# do Wazuh-Docker ou devem ser adicionadas manualmente após a geração dos mesmos.
# Exemplo de conteúdo (NÃO USE SEM PREENCHER COM OS CAMINHOS CORRETOS DOS CERTIFICADOS):
#
# plugins.security.ssl.http.enabled: true
# plugins.security.ssl.http.pemtrustedcas_filepath: certs/ca.pem
# plugins.security.ssl.http.pemcert_filepath: certs/indexer.pem
# plugins.security.ssl.http.pemkey_filepath: certs/indexer-key.pem
#
# cluster.name: opensearch
# node.name: wazuh-indexer
# network.host: 0.0.0.0
# discovery.seed_hosts: ["wazuh-indexer"] # Self-discovery for single node
# cluster.initial_master_nodes: ["wazuh-indexer"]
"@

$wazuhManagerContent = @"
# Este ficheiro é um placeholder.
# As configurações reais para o wazuh-manager (ossec.conf)
# devem ser preenchidas para integrar com o Wazuh Indexer e outros componentes.
# Exemplo de conteúdo (NÃO USE SEM PREENCHER COM AS CONFIGURAÇÕES CORRETAS):
#
# <ossec_config>
#   <output>
#     <server>
#       <address>wazuh-indexer</address> # Nome do serviço do Indexer no Docker Compose
#       <port>55000</port>
#       <protocol>tcp</protocol>
#     </server>
#   </output>
#   ...
# </ossec_config>
"@

$wazuhDashboardContent = @"
# Este ficheiro é um placeholder.
# As configurações reais para o wazuh-dashboard (opensearch_dashboards.yml)
# devem ser preenchidas para configurar o acesso ao Indexer e a segurança.
# Exemplo de conteúdo (NÃO USE SEM PREENCHER COM AS CONFIGURAÇÕES CORRETAS):
#
# server.host: "0.0.0.0"
# opensearch.hosts: ["https://wazuh-indexer:9200"]
# opensearch.ssl.verificationMode: certificate
# opensearch.ssl.certificateAuthorities: ["/usr/share/wazuh-dashboard/config/certs/ca.pem"]
# opensearch.ssl.key: /usr/share/wazuh-dashboard/config/certs/dashboard-key.pem
# opensearch.ssl.certificate: /usr/share/wazuh-dashboard/config/certs/dashboard.pem
# opensearch.username: kibanaserver # ou "admin" se usar o utilizador padrão
# opensearch.password: your_generated_password # A password gerada
#
# wazuh.security.enabled: true
# wazuh.security.api.base_url: "https://wazuh-manager:55000"
# wazuh.security.api.username: wazuh-wui
# wazuh.security.api.password: your_api_password # Password da API do Wazuh Manager
#
"@


# --- Criação dos Ficheiros ---
Write-Host "Criando e populando todos os ficheiros do projeto..." -ForegroundColor Green
Set-Content -Path "$baseDir\Vagrantfile" -Value $vagrantfileContent -Encoding UTF8
Set-Content -Path "$baseDir\docker-compose.yml" -Value $dockercomposeContent -Encoding UTF8
Set-Content -Path "$baseDir\Makefile" -Value $makefileContent -Encoding UTF8
Set-Content -Path "$baseDir\config\prometheus.yml" -Value $prometheusContent -Encoding UTF8
Set-Content -Path "$baseDir\config\alert.rules.yml" -Value $alertRulesContent -Encoding UTF8
Set-Content -Path "$baseDir\grafana\provisioning\datasources\datasource.yml" -Value $grafanaDatasourceContent -Encoding UTF8
Set-Content -Path "$baseDir\grafana\provisioning\dashboards\dashboards.yml" -Value $grafanaDashboardsContent -Encoding UTF8
Set-Content -Path "$baseDir\config\wazuh_cluster\wazuh-indexer.yml" -Value $wazuhIndexerContent -Encoding UTF8
Set-Content -Path "$baseDir\config\wazuh_cluster\wazuh.yml" -Value $wazuhManagerContent -Encoding UTF8
Set-Content -Path "$baseDir\config\wazuh_cluster\wazuh-dashboard.yml" -Value $wazuhDashboardContent -Encoding UTF8 # Novo ficheiro para o Dashboard
Set-Content -Path "$baseDir\flask_app\app.py" -Value $flaskAppContent -Encoding UTF8
Set-Content -Path "$baseDir\flask_app\templates\index.html" -Value $flaskTemplateContent -Encoding UTF8
Set-Content -Path "$baseDir\flask_app\Dockerfile" -Value $flaskDockerfileContent -Encoding UTF8

Write-Host "`nConfiguração do projeto v3.2 concluída!" -ForegroundColor Yellow
Write-Host "Todos os ficheiros foram criados com o conteúdo necessário."
Write-Host "Próximos passos IMPORTANTES:"
Write-Host "1. Abra um terminal Git Bash na nova pasta '$baseDir'."
Write-Host "2. Execute 'make up' para construir e iniciar o básico do ambiente."
Write-Host "3. SIGA AS INSTRUÇÕES DETALHADAS NA CONSOLA DO 'make up' para configurar o Wazuh manualmente (certificados e passwords)."
Write-Host "4. Após a configuração manual do Wazuh, execute 'make continue-stack' para iniciar o resto dos serviços."
Write-Host "5. Use outros comandos como 'make status', 'make logs', 'make down' conforme necessário."