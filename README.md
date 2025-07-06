# projectosecurityops
Criado como projeto de estagio
Resumo do Projeto: 
1. Objetivo
O objetivo deste projeto foi implementar um Centro de Operações de Segurança (SOC) open-source, totalmente funcional, para fins de estudo, laboratório e desenvolvimento. A stack permite a recolha, análise e visualização de eventos de segurança e métricas de performance, tudo num ambiente automatizado e fácil de gerir.

2. Arquitetura Final
Após várias iterações para garantir a estabilidade, chegámos a uma arquitetura híbrida que combina a fiabilidade de uma instalação nativa com a flexibilidade dos contentores Docker.

Host: O seu PC com Windows, que gere a máquina virtual.

Guest (VM): Uma máquina virtual com Ubuntu 22.04 LTS é criada e gerida pelo Vagrant e VirtualBox.

Base de Dados (Nativa): O OpenSearch (o motor por trás do Wazuh Indexer) é instalado diretamente no Ubuntu da VM. Esta abordagem contornou os bugs de inicialização que encontrámos com a versão em contentor.

Serviços (Dockerizados): Todos os outros componentes da stack correm como contentores Docker, geridos por um único ficheiro docker-compose.yml. Isto inclui:

Wazuh Manager

Wazuh Dashboard

Prometheus

Grafana

Diagrama da Arquitetura:

Fragmento do código

graph TD
    subgraph "Seu PC (Windows)"
        A[Utilizador] -->|Portas 5601, 3000, 9090| B(Vagrant + VirtualBox)
    end

    subgraph "Máquina Virtual (Ubuntu 22.04)"
        B --cria e gere--> C{VM}
        subgraph C
            D[OpenSearch - Nativo]
            subgraph "Docker"
                E[Wazuh Manager] --> D
                F[Wazuh Dashboard] --> D
                G[Prometheus]
                H[Grafana] --> G
            end
        end
    end

    style D fill:#cde,stroke:#333,stroke-width:2px
3. Requisitos
3.1. Requisitos de Máquina (PC Host - Windows)

Sistema Operativo: Windows 10 ou 11 (64-bit).

Processador (CPU): Um processador moderno com 4 ou mais núcleos. (Recomendado: 6+ núcleos, como o seu i7).

Memória (RAM): Mínimo absoluto de 16 GB. A nossa configuração final aloca 8 GB para a máquina virtual, deixando 8 GB para o Windows.

Disco: SSD (altamente recomendado) para uma performance de arranque aceitável.

Espaço em Disco: Pelo menos 50-60 GB de espaço livre.

3.2. Requisitos de Software (Instalados pelo script)

O script de setup (setup-autosoc-final-v2.ps1) foi desenhado para verificar e instalar automaticamente todas as seguintes ferramentas no Windows usando o gestor de pacotes Chocolatey:

Git: Para controlo de versões e usado pelo Git Bash.

VirtualBox: O software que cria e corre a máquina virtual.

Vagrant: A ferramenta que automatiza a criação e configuração da máquina virtual.

Make: Uma ferramenta de automação que nos dá os comandos simples (make up, make down, etc.).

4. Processo de Instalação (Totalmente Automatizado)
O fluxo de trabalho final é extremamente simples:

Executar o Script de Setup: Executar o ficheiro setup-autosoc-final-v2.ps1 uma única vez numa pasta vazia para criar toda a estrutura do projeto com os ficheiros já preenchidos.

Iniciar o Ambiente: Navegar para a pasta autosoc-plus criada e executar um único comando: make up.

Aguardar: O processo é totalmente automático e pode demorar entre 15 a 30 minutos na primeira vez. Ele cria a VM, instala o OpenSearch, gera uma password segura, inicializa a segurança e depois inicia todos os contentores Docker.

5. Gestão do Ambiente
A gestão do dia-a-dia é feita através de comandos simples no terminal Git Bash, dentro da pasta do projeto:

make up: Liga e provisiona o ambiente.

make down: Desliga a VM de forma segura (os dados são guardados).

make status: Mostra o estado dos serviços.

make logs: Mostra os logs de todos os serviços em tempo real.

make credentials: Mostra a password de admin que foi gerada automaticamente.

make destroy: Apaga completamente a máquina virtual.

6. Credenciais de Acesso Finais
Wazuh Dashboard:

URL: https://localhost:5601

Utilizador: admin

Password: Gerada aleatoriamente e guardada no ficheiro credentials.txt (pode ser vista com make credentials).

Grafana:

URL: http://localhost:3000

Utilizador: admin

Password: admin (será pedido para alterar no primeiro login).

Prometheus:

URL: http://localhost:9090
