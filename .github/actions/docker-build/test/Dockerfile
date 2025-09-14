FROM alpine:3.20
LABEL org.opencontainers.image.title="docker-build-test"
LABEL org.opencontainers.image.description="Minimal test image for reusable docker build pipeline"
RUN echo "hello from docker-build test" > /hello.txt
CMD ["sh","-c","cat /hello.txt && sleep 1"]

