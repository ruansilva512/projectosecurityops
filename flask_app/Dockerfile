FROM python:3.9-slim

# Define o diretório de trabalho
WORKDIR /app

# Copia o ficheiro de dependências e instala-as
# Isto é feito primeiro para aproveitar o cache do Docker
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copia o resto dos ficheiros da aplicação
COPY . .

# Expõe a porta que a aplicação vai usar
EXPOSE 5000

# Comando para correr a aplicação
CMD ["python", "app.py"]
