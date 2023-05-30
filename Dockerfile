FROM golang:1.20-bullseye AS BACK
WORKDIR /app
COPY ./test-app .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ./main .

ENTRYPOINT [ "/app/main", "80"]