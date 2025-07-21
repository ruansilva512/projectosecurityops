# SimpleSOC | Ambiente de Segurança Automatizado

Bem-vindo ao SimpleSOC, uma plataforma de cibersegurança *open source* e totalmente automatizada, concebida para democratizar o acesso a ferramentas de segurança de nível profissional. Este projeto utiliza uma interface web moderna servida por um *backend* Flask e integra Inteligência Artificial para análise de alertas.

-----

## 🚀 Pré-requisitos

Antes de começar, garanta que tem o seguinte software instalado no seu sistema. Todos os links são para as páginas oficiais de download.

  * **Python (versão 3.8 ou superior)**

      * Necessário para executar o servidor web Flask.
      * [Transferir Python](https://www.python.org/downloads/)

  * **Git**

      * Necessário para clonar este repositório.
      * [Transferir Git](https://git-scm.com/downloads)

  * **Vagrant**

      * Ferramenta para criar e gerir os ambientes de máquinas virtuais.
      * [Transferir Vagrant](https://developer.hashicorp.com/vagrant/downloads)

  * **VirtualBox**

      * O *software* de virtualização que irá executar as máquinas virtuais geridas pelo Vagrant.
      * [Transferir VirtualBox](https://www.virtualbox.org/wiki/Downloads)

  * **Make**
    Ferramenta de automação utilizada para orquestrar a construção e gestão do ambiente.

    *Já vem pré-instalada na maioria dos sistemas Linux e macOS.*

    **Para utilizadores Windows:**
    A forma mais simples e recomendada de instalar o `make` é através do gestor de pacotes **Chocolatey**, que evita problemas de compatibilidade de ambientes.

    1.  **Instalar o Chocolatey:** Se ainda não o tiver, abra o **PowerShell como Administrador** e execute o seguinte comando oficial para uma instalação segura:

        ```powershell
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        ```

        Este comando permite a execução do script de forma segura apenas na janela atual (`Bypass -Scope Process`), garante uma ligação de rede moderna (TLS 1.2) e, por fim, descarrega e executa o instalador do site oficial.

    2.  **Instalar o `make`:** Após instalar o Chocolatey, feche e reabra o seu terminal (PowerShell ou `cmd`) **como Administrador** e execute o seguinte comando:

        ```bash
        choco install make
        ```

    Isto irá instalar uma versão do `make` que é totalmente compatível com o ambiente Windows e será automaticamente adicionada ao seu PATH.

-----

## ⚙️ Instalação e Configuração

Siga estes passos para configurar o projeto no seu ambiente local.

### 1\. Clonar o Repositório

Abra um terminal e execute o seguinte comando:

```bash
git clone https://github.com/ruansilva512/projectosecurityops.git
cd projectosecurityops
```

### 2\. Configurar a Chave de API (para funcionalidades de IA)

Para que as funcionalidades de IA funcionem, precisa de fornecer a sua chave de API do Gemini.

  * Edite o ficheiro chamado `.env` na Pasta ./flask\_app/
  * Dentro desse ficheiro, modifique a seguinte linha, substituindo `A_SUA_CHAVE_DE_API_SECRETA_VAI_AQUI` pelo seu valor real:
    ```
    GEMINI_API_KEY="A_SUA_CHAVE_DE_API_SECRETA_VAI_AQUI"
    ```

-----

## ▶️ Execução do Ambiente Completo (Docker & VM)

O ambiente SimpleSOC é gerido através de comandos `make`, que automatizam a inicialização de todas as ferramentas de segurança em contêineres Docker dentro de uma Máquina Virtual Vagrant.

**Nota:** As dependências Python para a interface Flask UI (passos 2 e 3 da seção "Instalação e Configuração" original) são agora tratadas **automaticamente pelo Dockerfile da aplicação Flask**, não sendo necessário criar e ativar um ambiente virtual Python separado no seu host para a execução da aplicação web. No entanto, o Python e Git são ainda pré-requisitos para o `Vagrantfile` e para a clonagem do repositório.

### 1\. Iniciar o Ambiente Completo

Este comando irá iniciar a VM, provisioná-la com Docker, gerar certificados para o Wazuh e subir todas as stacks de serviços (Wazuh, Prometheus, Grafana, Suricata, Flask UI).

```bash
make up
```

Este processo pode demorar alguns minutos na primeira execução, pois o Vagrant irá descarregar a imagem da VM e o Docker irá descarregar as imagens dos contêineres.

### 2\. Aceder aos Serviços

Assim que o comando `make up` for concluído com sucesso, os seguintes serviços estarão acessíveis no seu navegador:

  * **Wazuh Dashboard (Kibana/OpenSearch Dashboards):**

      * **URL:** `https://localhost:5601`
      * **Credenciais:** `admin` / `SecretPassword` (ou a password que configurou para o Wazuh)
      * *(Pode aparecer um aviso de segurança no navegador devido ao certificado autoassinado; aceite-o para continuar.)*

  * **Prometheus:**

      * **URL:** `http://localhost:9090`
      * **Credenciais:** Não exige autenticação por padrão.

  * **Grafana:**

      * **URL:** `http://localhost:3000`
      * **Credenciais:** `admin` / `admin` (será solicitado a alterá-la no primeiro login)

  * **Flask UI (Sua Aplicação Web):**

      * **URL:** `http://localhost:5000`
      * **Credenciais:** Não exige autenticação por padrão.

### 3\. Gerir o Ambiente com `make`

Pode usar os seguintes comandos `make` para controlar o seu ambiente:

  * **`make iniciar`**: Inicia apenas a stack adicional (Prometheus, Grafana, Suricata, Flask UI). Útil se a VM e o Wazuh já estiverem a correr e precisar de reiniciar só esta parte.
  * **`make desligar`**: Para todos os serviços Docker em execução na VM e, em seguida, desliga a VM. Os dados persistentes nos volumes serão mantidos.
  * **`make destruir`**: Destrói a VM completamente, removendo-a do VirtualBox e apagando todos os seus dados e contêineres. **Use com cautela, pois os dados serão perdidos\!**
  * **`make ssh`**: Conecta-se à Máquina Virtual via SSH, permitindo-lhe executar comandos diretamente dentro do ambiente Linux.
  * **`make status`**: Mostra o estado atual de todos os contêineres Docker em ambas as stacks (Wazuh e Adicional).
  * **`make logs`**: Exibe os logs em tempo real de todos os serviços Docker, útil para depuração.
