FROM ubuntu:latest

LABEL Maintainer="admin" Email="admin123@gmail.com"

# Install necessary packages
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    curl \
    && apt-get clean

# Verify Java installation
RUN java -version

# Set working directory
WORKDIR /opt

# Download and extract Tomcat 9.0.93
RUN curl -L -O https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.93/bin/apache-tomcat-9.0.93.tar.gz \
    && tar xzvf apache-tomcat-9.0.93.tar.gz -C /opt/ \
    && mv /opt/apache-tomcat-9.0.93 /opt/tomcat

# Copy the WAR file to the webapps directory
WORKDIR /opt/tomcat/webapps
COPY target/*.war /opt/tomcat/webapps/webapp.war

# Expose port 8080
EXPOSE 8080

# Start Tomcat
ENTRYPOINT ["/opt/tomcat/bin/catalina.sh", "run"]
