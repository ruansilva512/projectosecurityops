# app.py

import os
from flask import Flask, render_template, request, jsonify
import google.generativeai as genai
from dotenv import load_dotenv

# Carrega as variáveis do ficheiro .env (a nossa chave de API)
load_dotenv()

# Cria a aplicação Flask
app = Flask(__name__)

# Configura a API do Gemini com a chave segura
try:
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    print("API Key do Gemini configurada com sucesso.")
except Exception as e:
    print(f"Erro ao configurar a API Key do Gemini: {e}")

# Rota principal que serve o site
@app.route('/')
def home():
    return render_template('index.html')

# --- NOVA ROTA PARA SERVIR DE INTERMEDIÁRIO SEGURO ---
@app.route('/api/gemini', methods=['POST'])
def gemini_proxy():
    # Verifica se o pedido tem o formato correto (JSON)
    if not request.is_json:
        return jsonify({"error": "Pedido inválido, JSON esperado."}), 400

    data = request.get_json()
    prompt = data.get('prompt')

    if not prompt:
        return jsonify({"error": "Prompt em falta no pedido."}), 400

    try:
        # Inicializa o modelo da IA
        model = genai.GenerativeModel('gemini-1.5-flash-latest')
        # Faz o pedido à API do Gemini a partir do servidor
        response = model.generate_content(prompt)
        
        # Envia a resposta da IA de volta para o frontend
        return jsonify({"text": response.text})

    except Exception as e:
        # Em caso de erro na API, envia uma mensagem de erro
        print(f"Erro na chamada à API do Gemini: {e}")
        return jsonify({"error": f"Erro ao comunicar com a API da IA: {e}"}), 500

# Permite executar o servidor com 'python app.py'
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
