FROM golang:1.25-alpine AS builder

WORKDIR /src

# Instalamos git y clonamos para tener acceso a los archivos del repositorio (incluyendo go.mod y go.sum)
RUN apk add --no-cache git && git clone https://github.com/Gentleman-Programming/engram.git .

RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/engram ./cmd/engram

FROM alpine:3.21
RUN adduser -D -u 10001 engram
USER engram
WORKDIR /home/engram
COPY --from=builder /out/engram /usr/local/bin/engram

EXPOSE 18080
ENTRYPOINT ["engram"]
