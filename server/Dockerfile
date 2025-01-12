FROM python:3.8-slim
WORKDIR /app
COPY . /app
RUN apt-get update && apt-get install -y iputils-ping && apt-get install -y iproute2
RUN apt install git -y
RUN apt install python3 -y
RUN apt install python3-pip -y
RUN apt install vim -y 
RUN apt install hping3 -y
RUN pip install scapy
RUN pip install netifaces

# RUN ip route add 12.1.1.0/24 via 192.168.73.201 dev eth0
# RUN git clone -b master https://github.com/fatemeshafiee/Replay_Traffic.git
# RUN git clone https://gitlab.com/fatemeshafiee/ddos-data-sets-2022.git
# Run git clone https://github.com/doriguzzi/lucid-ddos.git

EXPOSE 8080
# CMD ["start.sh"]
CMD ["python3", "server.py"]
