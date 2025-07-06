# -*- mode: ruby -*-
# vi: set ft=ruby :

# Versão do Vagrantfile: 2.0 (100% Automático)

Vagrant.configure("2") do |config|
  # --- Configuração da Máquina Virtual (VM) ---
  # Define a imagem base do sistema operativo. "ubuntu/jammy64" é o Ubuntu 22.04 LTS.
  config.vm.box = "ubuntu/jammy64"
  # Aumenta o tempo limite de boot para dar tempo à VM de iniciar em máquinas mais lentas.
  config.vm.boot_timeout = 900

  # Configurações do provedor VirtualBox.
  config.vm.provider "virtualbox" do |vb|
    # Aloca 10GB de RAM e 4 CPUs para a VM. Essencial para a stack do Wazuh e Elasticsearch.
    vb.memory = "10240"
    vb.cpus = "4"
    # Altera o tipo de placa de rede para um modelo mais comum, evitando problemas de conectividade.
    vb.customize ["modifyvm", :id, "--nictype1", "82540EM"]
  end

  # --- Mapeamento de Portas (Host -> VM) ---
  # Permite aceder aos serviços da VM a partir do seu PC.
  # Ex: Aceder a localhost:5601 no seu browser irá ligar-se à porta 443 da VM.
  config.vm.network "forwarded_port", guest: 443, host: 5601      # Wazuh Dashboard (acedido via HTTPS)
  config.vm.network "forwarded_port", guest: 9200, host: 9200    # Wazuh Indexer (API do Elasticsearch/OpenSearch)
  config.vm.network "forwarded_port", guest: 1514, host: 1514, protocol: "udp" # Comunicação de Agentes Wazuh (syslog)
  config.vm.network "forwarded_port", guest: 1515, host: 1515    # Registo de Agentes Wazuh
  config.vm.network "forwarded_port", guest: 9090, host: 9090    # Prometheus
  config.vm.network "forwarded_port", guest: 3000, host: 3000    # Grafana
  config.vm.network "forwarded_port", guest: 5000, host: 5000    # Flask UI

  # --- Provisionamento Automático com Shell Script ---
  # Este bloco é executado automaticamente na primeira vez que executa 'vagrant up'.
  config.vm.provision "shell", inline: <<-SHELL
    #!/bin/bash
    # 'set -e' garante que o script para imediatamente se algum comando falhar.
    set -e

    echo "--- [PASSO 1/4] Instalando pré-requisitos na VM (Git, Docker)... ---"
    # Atualiza a lista de pacotes e instala as ferramentas base.
    apt-get update > /dev/null
    apt-get install -y git curl ca-certificates lsb-release > /dev/null

    # Verifica se o Docker já está instalado para não o reinstalar desnecessariamente.
    if ! command -v docker &> /dev/null; then
        echo "Docker não encontrado. A instalar..."
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update > /dev/null
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
        # Adiciona o utilizador 'vagrant' ao grupo do docker para poder executar comandos docker sem 'sudo'.
        usermod -aG docker vagrant
    else
        echo "Docker já está instalado."
    fi

    echo "--- [PASSO 2/4] Gerando certificados do Wazuh (se necessário)... ---"
    WAZUH_REPO_PATH="/vagrant/wazuh-docker"

    # Clona o repositório oficial do wazuh-docker se ele não existir.
    if [ ! -d "$WAZUH_REPO_PATH" ]; then
      git clone https://github.com/wazuh/wazuh-docker.git "$WAZUH_REPO_PATH"
    fi

    # Gera os certificados SSL apenas se eles ainda não tiverem sido criados.
    if [ ! -f "$WAZUH_REPO_PATH/single-node/certs/ca/ca.pem" ]; then
      echo "Certificados não encontrados. A gerar novos certificados (isto pode demorar)..."
      # Usa o script oficial do Wazuh para gerar os certificados.
      cd "$WAZUH_REPO_PATH/single-node"
      docker compose -f generate-certs.yml run --rm generator
      # Guarda a password de admin num ficheiro de fácil acesso na pasta do projeto.
      grep "ADMIN_PASSWORD" .env | cut -d'=' -f2 > /vagrant/wazuh_admin_password.txt
      echo "PASSWORD DO WAZUH GUARDADA EM: /vagrant/wazuh_admin_password.txt"
    else
      echo "Certificados já existem. A saltar a geração."
    fi

    echo "--- [PASSO 3/4] Iniciando a stack de contentores do AutoSOC+... ---"
    # Navega para a pasta principal do projeto (partilhada com o seu PC).
    cd /vagrant
    # Inicia todos os serviços definidos no docker-compose.yml em background.
    docker compose up -d

    echo "--- [PASSO 4/4] Provisionamento concluído! Ambiente AutoSOC+ está pronto! ---"
  SHELL
end
