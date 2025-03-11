# Use a Debian-based image with Java pre-installed
FROM openjdk:11-jre-slim

# Install Python and Pip
RUN apt-get update && apt-get install -y wget python3 python3-pip && apt-get clean

# Install PyFlink and MongoDB Python driver
RUN pip3 install --no-cache-dir apache-flink pymongo

# Set environment variables for Flink
ENV FLINK_HOME=/opt/flink
ENV PATH="$FLINK_HOME/bin:$PATH"
ENV JAVA_HOME=/usr/local/openjdk-11

# Download and install Flink
RUN wget -qO- https://archive.apache.org/dist/flink/flink-1.15.2/flink-1.15.2-bin-scala_2.12.tgz | tar -xz -C /opt && \
    ln -s /opt/flink-1.15.2 /opt/flink

# Copy the Python script for Flink job
COPY flink.py /opt/flink/

# Set Flink execution command
CMD ["python3", "/opt/flink/flink.py"]
