from flask import Flask, render_template, url_for

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