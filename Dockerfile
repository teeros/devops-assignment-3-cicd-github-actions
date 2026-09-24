# Lightweight Linux base image
FROM alpine:3.19

# Install only the packages required by the application scripts
RUN apk add --no-cache \
        bash \
        coreutils \
        procps \
        iproute2 \
        iputils \
        bind-tools

# Copy the application into the image
COPY app/ /app/

# Set executable permissions
RUN chmod +x /app/app.sh

WORKDIR /app

ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
