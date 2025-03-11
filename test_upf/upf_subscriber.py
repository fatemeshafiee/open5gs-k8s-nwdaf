import http.server
import threading
import requests
import json
import os
import socket

# Configuration
SUBSCRIPTION_URL = os.getenv("SUBSCRIPTION_URL", "http://upf2-service.open5gs.svc.cluster.local:4355/nupf-ee/v1/ee-subscriptions")
SERVICE_NAME = os.getenv("SERVICE_NAME", "subscriber-service")  # K8s service name
NAMESPACE = os.getenv("NAMESPACE", "open5gs")  # K8s namespace
LISTEN_PORT = int(os.getenv("LISTEN_PORT", "5000"))

def get_pod_ip():
    """Get the pod's internal IP address."""
    return socket.gethostbyname(socket.gethostname())

class NotificationHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        """Handles incoming notifications."""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        print(f"Received Notification: {post_data.decode('utf-8')}")
        self.send_response(200)
        self.end_headers()

def start_http_server():
    """Starts an HTTP server to listen for incoming notifications."""
    server_address = ("", LISTEN_PORT)
    httpd = http.server.HTTPServer(server_address, NotificationHandler)
    print(f"Listening for notifications on port {LISTEN_PORT}...")
    httpd.serve_forever()

def subscribe():
    
    pod_ip = get_pod_ip()  
    callback_url = f"http://{SERVICE_NAME}.{NAMESPACE}.svc.cluster.local:{LISTEN_PORT}/notify"

    request_string =     request_string = '{\
  "subscription": {\
    "eventList": [\
      {\
        "type": "USER_DATA_USAGE_MEASURES",\
        "immediateFlag": false,\
        "measurementTypes": [\
          "VOLUME_MEASUREMENT"\
        ],\
        "appIds": null,\
        "trafficFilters": null,\
        "granularityOfMeasurement": "PER_FLOW",\
        "reportingSuggestionInfo": {\
          "reportingUrgency": "",\
          "reportingTimeInfo": 0\
        }\
      }\
    ],\
    "eventNotifyUri": "http://nwdaf-sbi:5000/",\
    "notifyCorrelationId": "string",\
    "eventReportingMode": {\
      "trigger": "PERIODIC",\
      "maxReports": 0,\
      "expiry": "",\
      "repPeriod": 3,\
      "sampRatio": 0,\
      "partitioningCriteria": null,\
      "notifFlag": "",\
      "mutingExcInstructions": {\
        "subscription": "",\
        "bufferedNotifs": ""\
      }\
    },\
    "nfId": "3",\
    "ueIpAddressVersion": "",\
    "ueIpAddress": {\
      "ipv4Addr": "",\
      "ipv6Addr": "",\
      "ipv6Prefix": ""\
    },\
    "supi": "",\
    "gpsi": "",\
    "pei": "",\
    "anyUe": true,\
    "dnn": "",\
    "snssai": {\
      "sst": 0,\
      "sd": ""\
    }\
  },\
  "supportedFeatures": ""\
}'



    request_data = json.loads(request_string)

    try:
        response = requests.post(SUBSCRIPTION_URL, json=request_data)
        print(f"Subscription Response: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Failed to subscribe: {e}")

if __name__ == "__main__":
    server_thread = threading.Thread(target=start_http_server, daemon=True)
    server_thread.start()

    subscribe()
    
    input("Press Enter to exit...\n")
