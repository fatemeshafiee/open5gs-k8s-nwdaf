from flask import Flask

app = Flask(__name__)

@app.route('/heartbeat', methods=['POST'])
def heartbeat():
    return "Heartbeat acknowledged\n", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
