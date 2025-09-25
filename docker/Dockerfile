FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git

WORKDIR /k6-build

RUN go install go.k6.io/xk6/cmd/xk6@latest

RUN /go/bin/xk6 build --output /k6-build/k6 \
    --with github.com/grafana/xk6-output-influxdb@latest \
    --with github.com/grafana/xk6-faker@latest


FROM grafana/k6:master-with-browser

COPY --from=builder /k6-build/k6 /usr/bin/k6

USER root
RUN apk update && apk upgrade && apk add bash && apk add jq && apk add curl

ENV K6_OUT=xk6-influxdb=http://influxdb:8086 \
        K6_BASE_URL= \
        K6_INFLUXDB_ORGANIZATION=k6org \
        K6_INFLUXDB_BUCKET=k6 \
        K6_INFLUXDB_INSECURE=true \ 
        K6_INFLUXDB_TOKEN=dAhRok872bfaM-zBz7C0XAeNQHfDkHO2rVYyqPReiXfOoPVVpHWvWmQzQppANCmMBVwu3JEqE1JH_DG799NJYA== \
        K6_INFLUXDB_PUSH_INTERVAL=1s \
        K6_INFLUXDB_CONCURRENT_WRITES=10000 \
        K6_INFLUXDB_PRECISION=250ms \
        K6_SYSTEM_TAGS="proto,subproto,status,method,url,name,group,check,error,error_code,tls_version,scenario,service,expected_response,vu,iter"
    

WORKDIR /tests

ENTRYPOINT ["k6"]
# ENTRYPOINT ["k6", "run", "/scripts/default_script.js"] 

