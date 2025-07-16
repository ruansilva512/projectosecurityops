# app.py

from flask import Flask, render_template

# Cria a aplicação Flask
app = Flask(__name__)

# Define a rota principal (a página inicial)
@app.route('/')
def home():
    # Pede ao Flask para encontrar 'index.html' na pasta 'templates' e mostrá-lo
    return render_template('index.html')

# Permite executar o servidor diretamente com 'python app.py'
if __name__ == '__main__':
    app.run(debug=True) # debug=True ajuda no desenvolvimento
