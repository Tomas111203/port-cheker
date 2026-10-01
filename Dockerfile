# Imagen base ligera de Linux
FROM ubuntu:22.04

LABEL maintainer="tu-email@example.com"
LABEL description="Contenedor para verificar si un puerto está abierto o cerrado"

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar netcat (necesario para el script)
RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Directorio de trabajo
WORKDIR /app

# Copiar el script al contenedor
COPY check_port.sh /app/check_port.sh

# Dar permisos de ejecución
RUN chmod +x /app/check_port.sh

# Punto de entrada: recibe los argumentos (puerto y host)
ENTRYPOINT ["/app/check_port.sh"]