document.addEventListener('DOMContentLoaded', () => {
    
    // --- LÓGICA DE NAVEGAÇÃO DA APLICAÇÃO ---
    const sidebarLinks = document.querySelectorAll('.sidebar-link, a[data-view]');
    const contentViews = document.querySelectorAll('.content-view');
    const mainContentArea = document.getElementById('main-content-area');
    const sidebar = document.getElementById('app-sidebar');
    const mobileMenuToggle = document.getElementById('mobile-menu-toggle');
    const sidebarOverlay = document.getElementById('sidebar-overlay');

    function switchView(viewId) {
        if (!viewId) return;
        contentViews.forEach(v => v.classList.remove('active'));
        sidebarLinks.forEach(l => l.classList.remove('active'));
        
        const activeView = document.getElementById(viewId);
        if (activeView) activeView.classList.add('active');
        
        const activeLink = document.querySelector(`.sidebar-link[data-view="${viewId}"]`);
        if (activeLink) activeLink.classList.add('active');
        
        mainContentArea.scrollTop = 0;
        
        if (window.innerWidth <= 1024) {
            sidebar.classList.remove('is-open');
            sidebarOverlay.style.display = 'none';
        }

        // Atualiza o hash da URL sem causar um salto na página
        if (history.pushState) {
            history.pushState(null, null, '#' + viewId.replace('-view', ''));
        } else {
            window.location.hash = '#' + viewId.replace('-view', '');
        }
    }

    sidebarLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            switchView(link.getAttribute('data-view'));
        });
    });

    mobileMenuToggle.addEventListener('click', () => {
        sidebar.classList.toggle('is-open');
        sidebarOverlay.style.display = sidebar.classList.contains('is-open') ? 'block' : 'none';
    });

    sidebarOverlay.addEventListener('click', () => {
        sidebar.classList.remove('is-open');
        sidebarOverlay.style.display = 'none';
    });

    // --- CONTEÚDO E LÓGICA FUNCIONAL ---
    const toolsData = [
        { id: 'wazuh', name: 'Wazuh', category: 'SIEM / XDR', icon: 'fas fa-shield-alt', desc: 'A plataforma central de SIEM e XDR. Agrega e correlaciona dados de toda a sua infraestrutura para uma deteção de ameaças unificada.', features: 'Deteção de intrusão, monitorização de integridade de ficheiros, análise de logs, avaliação de vulnerabilidades.', use_case: 'Identificar um ataque de força bruta num servidor web através da análise de logs de autenticação e alertar a equipa de segurança em tempo real.', images: [ { src: '/static/img/wazuh_dashboard.png', alt: 'Dashboard Wazuh', alert_context: 'O dashboard mostra um pico em "Alertas de Autenticação Falhada", com várias tentativas de login a partir de um único endereço IP.' }, { src: '/static/img/wazuh_evento.png', alt: 'Interface Wazuh com análise de eventos', alert_context: 'Um evento de segurança específico, regra ID 5712, "sshd: brute-force attack", foi acionado para o agente "server-01".' }, { src: '/static/img/wazuh_conformidade.png', alt: 'Painel Wazuh de conformidade NIST', alert_context: 'A visualização de conformidade mostra falhas no controlo AC-7 (Unsuccessful Logon Attempts) do framework NIST 800-53.' } ] },
        { id: 'opnsense', name: 'OPNsense', category: 'Firewall NGFW', icon: 'fas fa-fire-alt', desc: 'A primeira linha de defesa da sua rede. Um firewall de próxima geração que oferece controlo de tráfego robusto, VPN e prevenção de intrusão.', features: 'Stateful packet filtering, Intrusion Detection and Prevention (com Suricata), VPN (IPsec, OpenVPN), Web filtering.', use_case: 'Bloquear o acesso de uma lista de IPs maliciosos conhecidos (obtidos do MISP) a toda a rede interna, na borda da rede.', images: [ { src: '/static/img/opnsense_regras.png', alt: 'Interface OPNsense com regras de firewall', alert_context: 'Uma regra de firewall foi criada para bloquear todo o tráfego de entrada na interface WAN proveniente de um alias de IP chamado "Threat_Actors_IP_List".' }, { src: '/static/img/opnsense_trafego.png', alt: 'Monitor de tráfego OPNsense' }, { src: '/static/img/opnsense_vpn.png', alt: 'Configuração VPN no OPNsense' } ] },
        { id: 'suricata', name: 'Suricata', category: 'IDS / NSM', icon: 'fas fa-eye', desc: 'O guarda de trânsito da sua rede. Analisa o tráfego em tempo real para detetar assinaturas de ataques, anomalias e atividades maliciosas.', features: 'Deteção baseada em assinaturas, análise de protocolos, extração de ficheiros, logging de transações de rede (NSM).', use_case: 'Detetar o download de um ficheiro malicioso conhecido numa estação de trabalho e gerar um alerta com metadados da transação para o Wazuh.', images: [ { src: '/static/img/suricata_alertas.png', alt: 'Dashboard Suricata com alertas', alert_context: 'Um alerta de alta prioridade (Priority 1) "ET MALWARE Likely Evil EXE Download" foi detetado. O tráfego foi originado do IP 192.168.1.105 para um IP externo.' }, { src: '/static/img/suricata_regras.png', alt: 'Interface de gestão de regras Suricata' }, { src: '/static/img/suricata_protocolos.png', alt: 'Análise detalhada de protocolos' } ] },
        { id: 'thehive', name: 'TheHive', category: 'Resposta a Incidentes', icon: 'fas fa-shield-virus', desc: 'A sua plataforma colaborativa de resposta a incidentes. Centraliza a investigação de casos, tarefas e observáveis.', features: 'Gestão de casos, templates de tarefas, integração com Cortex para análise automatizada, cronologia de incidentes.', use_case: 'Criar um novo caso a partir de um alerta do Wazuh, atribuir tarefas a analistas e executar analisadores do Cortex num IP suspeito.', images: [ { src: '/static/img/thehive_casos.png', alt: 'Gestão de casos no TheHive' }, { src: '/static/img/thehive_observaveis.png', alt: 'Análise de observáveis' }, { src: '/static/img/thehive_metricas.png', alt: 'Dashboard de métricas' } ] },
        { id: 'misp', name: 'MISP', category: 'Threat Intelligence', icon: 'fas fa-brain', desc: 'Plataforma de partilha de inteligência de ameaças. Agrega, correlaciona e partilha Indicadores de Compromisso (IoCs).', features: 'Partilha de IoCs, correlação de eventos, visualização de grafos de ameaças, integração com outras ferramentas.', use_case: 'Importar um novo feed de IoCs sobre um grupo de ransomware e correlacioná-lo com alertas existentes para identificar novas infeções.', images: [ { src: '/static/img/misp_grafo.png', alt: 'Grafo visual MISP' }, { src: '/static/img/misp_galaxy.png', alt: 'Interface MISP Galaxy' }, { src: '/static/img/misp_correlacoes.png', alt: 'Correlações automatizadas MISP' } ] },
        { id: 'openvas', name: 'OpenVAS', category: 'Vulnerability Management', icon: 'fas fa-search', desc: 'Scanner de vulnerabilidades completo que identifica falhas de segurança na sua rede antes que sejam exploradas.', features: 'Scans de rede e web, base de dados de vulnerabilidades (NVTs) atualizada diariamente, relatórios detalhados.', use_case: 'Agendar um scan semanal a todos os servidores e receber um relatório detalhado com as vulnerabilidades encontradas.', images: [ { src: '/static/img/openvas_resultados.png', alt: 'Resultados de scan OpenVAS' }, { src: '/static/img/openvas_detalhes.png', alt: 'Detalhes técnicos de vulnerabilidade' }, { src: '/static/img/openvas_tarefas.png', alt: 'Configuração de tarefas de scan' } ] },
        { id: 'cowrie', name: 'Cowrie', category: 'Honeypot', icon: 'fas fa-bug', desc: 'Um honeypot de média interação que emula serviços SSH e Telnet para atrair, registar e analisar as táticas de atacantes.', features: 'Registo de sessões interativas, download de malware, emulação de sistema de ficheiros virtual, output para JSON.', use_case: 'Analisar uma sessão de um atacante para descobrir novas credenciais e ferramentas que estão a ser utilizadas em ataques.', images: [ { src: '/static/img/cowrie_sessao.png', alt: 'Sessão terminal Cowrie' }, { src: '/static/img/cowrie_logs.png', alt: 'Logs estruturados Cowrie' }, { src: '/static/img/cowrie_dashboard_ataques.png', alt: 'Dashboard de análise de ataques' } ] },
        { id: 'grafana', name: 'Grafana', category: 'Monitorização', icon: 'fas fa-chart-bar', desc: 'Visualize o estado da sua infraestrutura. Cria dashboards dinâmicos a partir de métricas do Prometheus para uma monitorização clara.', features: 'Dashboards personalizáveis, suporte a múltiplas fontes de dados, sistema de alerta, anotações em gráficos.', use_case: 'Monitorizar a utilização de CPU e memória do servidor Wazuh e criar um alerta para notificar a equipa quando os limites forem excedidos.', images: [ { src: '/static/img/grafana_performance.png', alt: 'Dashboard Grafana de performance' }, { src: '/static/img/grafana_rede.png', alt: 'Visualização Grafana de rede' }, { src: '/static/img/grafana_alertas.png', alt: 'Dashboard Grafana de segurança' } ] },
        { id: 'osquery', name: 'osquery', category: 'Endpoint Visibility', icon: 'fas fa-terminal', desc: 'Permite consultar o seu sistema operativo como se fosse uma base de dados. Visibilidade total sobre processos, conexões e configurações.', features: 'Consultas SQL para estado do sistema, monitorização de eventos de baixo nível, agendamento de queries, gestão via FleetDM.', use_case: 'Utilizar uma query agendada para detetar processos a correr a partir de locais invulgares (ex: /tmp) em todos os endpoints.', images: [ { src: '/static/img/osquery_terminal.png', alt: 'Terminal osquery' }, { src: '/static/img/osquery_fleetdm.png', alt: 'Interface FleetDM' }, { src: '/static/img/osquery_editor_fleetdm.png', alt: 'Editor FleetDM para queries' } ] }
    ];

    async function callGeminiAPI(prompt) {
        // IMPORTANTE: Substitua 'SUA_API_KEY_GEMINI_AQUI' pela sua chave de API real.
        const apiKey = 'AIzaSyAKouzJ_LWl7mmV7yeKYSTdsrabA-81HHo';
        
        if (!apiKey || apiKey === 'SUA_API_KEY_GEMINI_AQUI') {
            throw new Error("A funcionalidade de IA está desativada. Para ativá-la, por favor insira uma chave de API válida no ficheiro main.js.");
        }
        
        const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${apiKey}`;
        
        try {
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
            });
            
            if (!response.ok) {
                throw new Error(`Erro na API: ${response.status} ${await response.text()}`);
            }
            
            const result = await response.json();
            
            if (result.candidates && result.candidates.length > 0 && result.candidates[0].content.parts[0].text) {
                return result.candidates[0].content.parts[0].text;
            } else {
                throw new Error("Resposta da API inválida ou sem conteúdo.");
            }
        } catch (error) {
            console.error("Erro ao chamar a API Gemini:", error);
            throw error; // Propaga o erro para ser tratado pela função que chamou
        }
    }

    const aiExplainerModal = document.getElementById('ai-explainer-modal');
    const aiExplainerCloseBtn = document.getElementById('ai-modal-close-btn');
    const aiModalResult = aiExplainerModal?.querySelector('#ai-modal-result');
    const aiModalSpinner = aiExplainerModal?.querySelector('#ai-modal-spinner');

    aiExplainerCloseBtn?.addEventListener('click', () => aiExplainerModal.classList.add('hidden'));

    async function openAiExplainer(toolId) {
        const tool = toolsData.find(t => t.id === toolId);
        if (!tool || !aiExplainerModal) return;

        aiExplainerModal.classList.remove('hidden');
        aiModalResult.innerHTML = '';
        aiModalSpinner.style.display = 'flex';

        const aiModalContent = aiExplainerModal.querySelector('#ai-modal-content');
        let contentHtml = `<h3 class="text-2xl font-bold mb-6">${tool.name} - Análise de Alertas</h3><div class="grid grid-cols-1 md:grid-cols-2 gap-6">`;
        let combinedAlertContext = "";
        tool.images.forEach(img => {
            if (img.alert_context) {
                contentHtml += `<div><img src="${img.src}" class="rounded-lg shadow-md mb-3" alt="${img.alt}"><p class="text-sm text-gray-600">${img.alt}</p></div>`;
                combinedAlertContext += `- ${img.alt}: ${img.alert_context}\n`;
            }
        });
        contentHtml += '</div>';
        aiModalContent.innerHTML = contentHtml;
        
        const prompt = `Como um analista de cibersegurança sénior, por favor, analise os seguintes alertas detetados: ${combinedAlertContext}. Forneça: 1. Uma **Explicação Simples**. 2. Uma **Análise de Risco**. 3. **Próximos Passos Recomendados**. Formate em Markdown.`;
        
        try {
            const responseText = await callGeminiAPI(prompt);
            aiModalResult.innerHTML = responseText.replace(/\n/g, '<br>').replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        } catch (error) {
            aiModalResult.innerHTML = `<div class="p-4 bg-red-100 border-l-4 border-red-500 text-red-700"><h4 class="font-bold">Erro de Comunicação</h4><p>${error.message}</p></div>`;
        } finally {
            aiModalSpinner.style.display = 'none';
        }
    }

    function setupInteractiveTools() {
        const grid = document.getElementById('tools-grid');
        const modal = document.getElementById('tool-details-modal');
        const closeBtn = modal?.querySelector('.modal-close-btn');
        if (!grid || !modal || !closeBtn) return;

        const cardTemplate = document.getElementById('tool-card-template');
        toolsData.forEach(tool => {
            const cardClone = cardTemplate.content.cloneNode(true);
            const cardElement = cardClone.querySelector('.tool-card');
            cardElement.dataset.toolId = tool.id;
            cardClone.querySelector('.tool-card-icon').className = `${tool.icon || 'fas fa-cube'} tool-card-icon`;
            cardClone.querySelector('.tool-card-category').textContent = tool.category;
            cardClone.querySelector('.tool-card-name').textContent = tool.name;
            grid.appendChild(cardClone);
        });

        grid.addEventListener('click', (e) => {
            const card = e.target.closest('.tool-card');
            if (card) {
                const tool = toolsData.find(t => t.id === card.dataset.toolId);
                if (tool) populateAndShowModal(tool);
            }
        });

        function populateAndShowModal(tool) {
            modal.querySelector('#modal-tool-category').textContent = tool.category;
            modal.querySelector('#modal-tool-name').textContent = tool.name;
            modal.querySelector('#modal-tool-desc').textContent = tool.desc;
            modal.querySelector('#modal-tool-features').textContent = tool.features;
            modal.querySelector('#modal-tool-usecase').textContent = tool.use_case;

            const mainGallery = modal.querySelector('#modal-gallery-main');
            const thumbGallery = modal.querySelector('#modal-gallery-thumbnails');
            mainGallery.innerHTML = `<img src="${tool.images[0].src}" alt="${tool.images[0].alt}">`;
            thumbGallery.innerHTML = tool.images.map((img, index) => `<img src="${img.src}" alt="Thumbnail ${index + 1}" class="${index === 0 ? 'active' : ''}" data-full-src="${img.src}" data-full-alt="${img.alt}">`).join('');
            
            const aiButtonContainer = modal.querySelector('#modal-ai-button-container');
            if (tool.id === 'wazuh' || tool.id === 'suricata' || tool.id === 'opnsense') {
                aiButtonContainer.innerHTML = `<button class="btn-gemini mt-8 px-6 py-3 text-base font-bold rounded-lg shadow-md open-ai-explainer-modal" data-tool-id="${tool.id}"><i class="fas fa-magic mr-2"></i>Explicar Alertas com IA</button>`;
            } else {
                aiButtonContainer.innerHTML = '';
            }
            modal.showModal();
        }

        modal.addEventListener('click', (e) => {
            if (e.target.matches('.modal-gallery-thumbnails img')) {
                const mainImg = modal.querySelector('#modal-gallery-main img');
                mainImg.src = e.target.dataset.fullSrc;
                mainImg.alt = e.target.dataset.fullAlt;
                modal.querySelectorAll('.modal-gallery-thumbnails img').forEach(thumb => thumb.classList.remove('active'));
                e.target.classList.add('active');
            }
            if (e.target.matches('.open-ai-explainer-modal')) {
                openAiExplainer(e.target.dataset.toolId);
                modal.close();
            }
        });
        closeBtn.addEventListener('click', () => modal.close());
        modal.addEventListener('click', (e) => { if (e.target === modal) modal.close(); });
    }

    function setupScrollAnimations() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('is-visible');
                    observer.unobserve(entry.target);
                }
            });
        }, { threshold: 0.1 });
        document.querySelectorAll('.animate-on-scroll').forEach(el => observer.observe(el));
    }

    function setupCharts() {
        const chartConfigs = {
            securityChart: { type: 'line', data: { labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'], datasets: [{ label: 'Alertas Críticos', data: [2, 1, 3, 8, 12, 6], borderColor: 'rgb(239, 68, 68)', tension: 0.4, fill: true, backgroundColor: 'rgba(239, 68, 68, 0.1)' }, { label: 'Alertas Médios', data: [5, 8, 12, 15, 18, 14], borderColor: 'rgb(245, 158, 11)', tension: 0.4, fill: true, backgroundColor: 'rgba(245, 158, 11, 0.1)' }] }, options: { responsive: true, maintainAspectRatio: false } },
            networkChart: { type: 'doughnut', data: { labels: ['HTTP', 'HTTPS', 'DNS', 'SSH', 'Outros'], datasets: [{ data: [35, 45, 10, 5, 5], backgroundColor: ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#9CA3AF'] }] }, options: { responsive: true, maintainAspectRatio: false } },
            threatsChart: { type: 'bar', data: { labels: ['Brute Force', 'Malware', 'Port Scan', 'Web Attack'], datasets: [{ label: 'Ocorrências', data: [23, 15, 8, 12], backgroundColor: ['#EF4444', '#F59E0B', '#3B82F6', '#10B981'] }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } } },
            benefitsChart: { type: 'bar', data: { labels: ['Abordagem Manual', 'AutoSOC+'], datasets: [{ label: 'Tempo (Horas)', data: [160, 2], backgroundColor: ['rgba(211, 84, 0, 0.8)', 'rgba(44, 122, 123, 0.8)'] }] }, options: { responsive: true, maintainAspectRatio: false, indexAxis: 'y' } }
        };
        for (const chartId in chartConfigs) { const ctx = document.getElementById(chartId); if (ctx) new Chart(ctx, chartConfigs[chartId]); }
    }

    function setupScenarioGenerator() {
        const selectorContainer = document.getElementById('ai-tool-selector');
        const generateBtn = document.getElementById('generate-scenario-btn');
        if (!selectorContainer || !generateBtn) return;
        const selectableTools = [...new Set(toolsData.map(t => t.name))];
        selectorContainer.innerHTML = selectableTools.map(toolName => `<label class="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 cursor-pointer"><input type="checkbox" name="ai-tool" value="${toolName}" class="h-5 w-5 rounded border-gray-300 text-primary-color" aria-label="${toolName}"><span class="text-gray-700 font-medium">${toolName}</span></label>`).join('');
        generateBtn.addEventListener('click', async () => {
            const selectedTools = Array.from(document.querySelectorAll('input[name="ai-tool"]:checked')).map(cb => cb.value);
            if (selectedTools.length === 0) { alert('Selecione pelo menos uma ferramenta.'); return; }
            const resultContainer = document.getElementById('scenario-result-container');
            const spinner = document.getElementById('scenario-spinner');
            const resultDiv = document.getElementById('scenario-result');
            resultContainer.style.display = 'block'; spinner.style.display = 'flex'; resultDiv.innerHTML = '';
            const userContext = document.getElementById('ai-context').value || "um ataque padrão";
            const prompt = `Crie um cenário de ataque de cibersegurança detalhado, detetável pelas seguintes ferramentas: ${selectedTools.join(', ')}. Contexto: "${userContext}". Descreva: 1. Ator da Ameaça e motivações. 2. Vetor de Ataque. 3. Passos do Ataque (Cronologia). 4. Deteção e Resposta por cada ferramenta selecionada. Formate em Markdown.`;
            try {
                const responseText = await callGeminiAPI(prompt);
                resultDiv.innerHTML = responseText.replace(/\n/g, '<br>').replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
            } catch (error) {
                resultDiv.innerHTML = `<div class="p-4 bg-red-100 border-l-4 border-red-500 text-red-700"><h4 class="font-bold">Erro de Comunicação</h4><p>${error.message}</p></div>`;
            } finally {
                spinner.style.display = 'none';
            }
        });
    }

    document.querySelectorAll('.tab-button').forEach(button => {
        button.addEventListener('click', () => {
            const tabContainer = button.closest('.tab-container');
            const tabId = button.dataset.tab;
            tabContainer.querySelectorAll('.tab-button').forEach(btn => btn.classList.remove('active'));
            tabContainer.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
            button.classList.add('active');
            tabContainer.querySelector(`#${tabId}`)?.classList.add('active');
        });
    });

    document.getElementById('floatingAction')?.addEventListener('click', () => {
        const notification = document.getElementById('notification');
        notification.classList.add('show');
        setTimeout(() => notification.classList.remove('show'), 3000);
    });

    // Inicialização de todas as funções
    setupScrollAnimations();
    setupInteractiveTools();
    setupCharts();
    setupScenarioGenerator();

    const initialHash = window.location.hash.substring(1);
    if (initialHash && document.getElementById(initialHash + '-view')) {
        switchView(initialHash + '-view');
    } else {
        switchView('hero-view');
    }
});
