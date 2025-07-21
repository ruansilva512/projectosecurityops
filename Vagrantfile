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
