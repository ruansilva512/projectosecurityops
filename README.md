# AutoSOC+ | Ambiente de Segurança Automatizado

Bem-vindo ao AutoSOC+, uma plataforma de cibersegurança *open source* e totalmente automatizada, concebida para democratizar o acesso a ferramentas de segurança de nível profissional. Este projeto utiliza uma interface web moderna servida por um *backend* Flask e integra Inteligência Artificial para análise de alertas.

## Pré-requisitos

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

## Instalação e Configuração

Siga estes passos para configurar o projeto no seu ambiente local.

**1. Clonar o Repositório**
Abra um terminal e execute o seguinte comando:
```bash
git clone https://github.com/ruansilva512/projectosecurityops.git
cd projectosecurityops
```

**2. Criar e Ativar o Ambiente Virtual**
É uma boa prática isolar as dependências do projeto.
```bash
# Criar o ambiente virtual
python -m venv venv

# Ativar no Windows
venv\Scripts\activate

# Ativar no macOS / Linux
source venv/bin/activate
```

**3. Instalar as Dependências Python**
Com o ambiente virtual ativo, instale todas as bibliotecas necessárias com um único comando:
```bash
pip install -r requirements.txt
```

**4. Configurar a Chave de API**
Para que as funcionalidades de IA funcionem, precisa de fornecer a sua chave de API do Gemini.

* Crie um ficheiro chamado `.env` na raiz do projeto.
* Dentro desse ficheiro, adicione a seguinte linha, substituindo pelo seu valor:
    ```
    GEMINI_API_KEY="A_SUA_CHAVE_DE_API_SECRETA_VAI_AQUI"
    ```

**Importante:** O ficheiro `.env` contém informação sensível e não deve ser enviado para o GitHub. Para garantir isso, crie um ficheiro chamado `.gitignore` e adicione a seguinte linha:
```
# .gitignore
venv/
.env
__pycache__/
```

## Execução

Com tudo configurado, inicie o servidor Flask:

1.  Certifique-se de que o seu ambiente virtual está ativo.
2.  Execute o seguinte comando no terminal:
    ```bash
    python app.py
    ```
3.  Abra o seu navegador e aceda a: **http://127.0.0.1:5000**

O seu site AutoSOC+ deverá agora estar a funcionar localmente.

---
