### 1. 개요

Nginx Access Log를 수집하여 AWS Kenesis Stream에 전송을 목적으로 합니다.

비용 및 운영 관점에서 관련 Log 데이터를 Json형식화하여 S3에 저장합니다.
<br/><br/>


### 2. 기능

(1) Nginx

   - Web Server

   - Event-Driven 구조

   - 가볍고 동시접속 처리에 특화된 성능
<br/>


(2) Kinesis Data Stream

   - 대량의 스트림 데이터를 실시간으로 "수집 및 처리" 하는 AWS의 관리형 서비스입니다.

   - 빠른 Put/Get의 처리. 데이터 인풋 파이프라인을 생성 및 운영하는 부담을 줄일 수 있습니다.

   - 스트림 데이터? 대량의 데이터 소스(mobile or web-app)에서 연속적으로 생성되는 데이터를 작은 단위(KB)로 전송하는 것을 말합니다.
<br/>


(3) Kinesis Data Firehose

   - Kinesis Data Stream의 데이터를 저장소 또는 분석 도구에 로드합니다.

     S3, Redshift, ES, Splunk 등의 서비스로 전송할 수 있습니다.

   - AWS의 관리형 서비스   
<br/>


(4) Kinesis Agent

   - Kinesis Data Stream에 서버(EC2)의 스트림 데이터를 쉽게 전송하기 위한 Agent입니다.
<br/>


(5) Lambda

   - 별도의 서버 셋업 없이 곧바로 코드를 실행해주는 AWS의 서버리스 서비스입니다.

   - 고정 비용 없이 사용 시간에 대해서만 비용이 발생합니다.
<br/>


(6) S3

   - AWS Object Storage 서비스입니다.

   - 높은 고가용성, 저렴한 비용.
<br/>


(7) LocalStack

   - LocalStack은 AWS 클라우드 리소스의 기능을 에뮬레이션하여 제공합니다.

   - 로컬 PC에서 단독으로 실행이 가능합니다. (Used Docker)
<br/>


(8) Terraform

   - 테라폼은 Infrstructure as Code를 지향하고 있는 도구로서, 필요한 리소스들을 선언적인 코드로 작성해 관리할 수 있습니다.
<br/><br/>


### 3. 설계

![kinesis-firehose-s3](/Users/a1101167/Desktop/draw.io/kinesis-firehose-s3.png)

(1) EC2에 설치된 Kinesis Agent에서 Nginx Access log를 Kinesis Stream으로 전송합니다.

(2) 전송된 스트림 데이터를 S3로 저장하기 위해 Kinesis Firehose를 이용합니다.

(3) Firehose는 스트림 데이터를 Lambda를 이용해 Json형태로 Parsing 합니다.

(4) 최종 스트림 데이터는 S3에 전송됩니다.
<br/><br/>


### 4. 환경 구성 / 설정

(0) MAC OSX 환경에서 테스트를 수행합니다.

   - Docker 설치를 먼저 해야합니다.

     https://hub.docker.com/editions/community/docker-ce-desktop-mac 링크에서 Docker를 설치합니다.
<br/>


(1) LocalStack 구동

   - 아래의 yaml 파일을 통해서 docker-compose로 구동할 예정입니다.

     localstack에서 테스트로 사용할 aws서비스를 구동 옵션에 포함해 줍니다.

     ex) run.sh : export SERVICES=s3,kinesis,lambda,ec2 환경 변수로 서비스 지정

```
vim docker-compose.yaml
```


```docker-compose.yaml
version: '3.3'

services:
  localstack:
    image: localstack/localstack
    ports:
      - "4566:4566"
      - "4567-4597:4567-4597"
      - "${PORT_WEB_UI-8080}:${PORT_WEB_UI-8080}"
    environment:
      - SERVICES=${SERVICES- }
      - DEBUG=${DEBUG- }
      - DATA_DIR=${DATA_DIR- }
      - PORT_WEB_UI=${PORT_WEB_UI- }
      - LAMBDA_EXECUTOR=${LAMBDA_EXECUTOR- }
      - KINESIS_ERROR_PROBABILITY=${KINESIS_ERROR_PROBABILITY- }
      - DOCKER_HOST=unix:///var/run/docker.sock
    volumes:
      - "${TMPDIR:-/tmp/localstack}:/tmp/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
```
<br/>


```
vim run.sh
```

```run.sh
#!/bin/bash

cd "$(dirname "$0")"

export SERVICES=s3,kinesis,firehose,dynamodb,lambda,ec2,iam,sts,cloudwatch
export TMPDIR=/private$TMPDIR
export PORT_WEB_UI=8080
export DEBUG=0

case $1 in
  down)
    docker-compose down
    ;;
  up)
    docker-compose up -d
    ;;
  *)
    echo "ex) ./run.sh down or up"
    ;;
esac
```
<br/>


   - 스크립트를 통해 실행한 후에 docker ps로 LocalStack 컨테이너가 잘 실행이 되었는지 확인을 합니다.

```
mkdir ~/localstack
cd ~/localstack

vim docker-compose.yaml
vim run.sh

chmod 755 run.sh

./run.sh up

a1101167@11ST1101167MN001 localstack % docker ps -a       


CONTAINER ID  IMAGE             COMMAND         CREATED     STATUS     PORTS                                NAMES

8f9df69e81ae  localstack/localstack  "docker-entrypoint.sh"  10 minutes ago  Up 10 minutes  0.0.0.0:4567-4597->4567-4597/tcp, 4566/tcp, 0.0.0.0:8080->8080/tcp  localstack_localstack_1
```
<br/>


(2) Localstack을 위한 AWS credentials 설정

   - localstack은 실제 aws credential이 필요하지는 않습니다.

     아래처럼 간략하게 입력해 놓고 localstack이 aws api를 제대로 에뮬레이션해 주는지 확인합니다.

```
a1101167@11ST1101167MN001 localstack % aws configure                                                  
AWS Access Key ID [****************test]: test
AWS Secret Access Key [****************test]: test
Default region name [ap-northeast-2]: ap-northeeast-2
Default output format [json]: json

a1101167@11ST1101167MN001 localstack % aws --endpoint-url=http://localhost:4566 ec2 describe-instances

{

  "Reservations": []

}
```
<br/>


(3) Kinesis Agent 설정

   - EC2에 설치할 Kinesis Agent입니다.

     테스트를 위해 nginx도 설치합니다.



     Amazon Linux 2 기준으로 진행

```
sudo amazon-linux-extras install nginx1

systemctl start nginx

systemctl enable nginx

yum install -y aws-kinesis-agent

# Nginx Access Log 를 kinesis-agent 가 읽을 수 있게 처리합니다.
chmod 775  /var/log/nginx
```
<br/>


   - "kinesis.endpoint": Kinesis가 구성된 리전의 endpoint를 설정

     "filePattern": 스트림 전송할 로그 파일 경로 설정

     "kinesisStream": kinesis Stream Name 지정

     **maxBufferAgeMillis Default: 60,000ms (1Min) 전송 주기 기본 1분.**



```
vim /etc/aws-kinesis/agent.json
```

```/etc/aws-kinesis/agent.json
{
    "cloudwatch.emitMetrics": true,
    "kinesis.endpoint": "kinesis.ap-northeast-2.amazonaws.com",
    "firehose.endpoint": "",
    
    "flows": [
        {
        "filePattern": "/var/log/nginx/access.log",
        "kinesisStream": "nginx-access-logs"
        }
    ]
}
```
<br/>


   - EC2 IAM 을 설정합니다.

     kinesis agent가 데이터를 전송하기 위함입니다.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "kinesis:PutRecords"
            ],
            "Resource": "*"
        }
    ]
}
```
<br/>


(4) Terraform

   - Terraform Code로 선언하여 H3. 설계  항목의 AWS Resource를 구성합니다.

<br/>


     Terraform Provider - AWS -  기준 필요한 필수 모듈을 구성하고, (terraform init)

     배포 자원에 대해 변경 사항을 확인하고, (terraform plan)

     배포합니다. (terraform apply)

```
terraform init
terraform plan
terraform apply
```
<br/>


(5) Log 처리

   - Nginx Log는 kinesis agent를 통해 아래와 같은 형태로 kinesis stream에 저장됩니다.

     해당 검증에서는 kinesis agent 또는 nginx 에서 Log parsing 설정을 하지 않습니다.


   - Kinesis Agent에서 전송되는 Log

```
[{'ApproximateArrivalTimestamp': 1608640417.024, 'Data': '1.229.242.14 - - [22/Dec/2020:12:32:36 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36" "-"\n', 'PartitionKey': '110397.65176589867', 'SequenceNumber': '49613838875858910653213735508838664445347285229199425538'}]
```



   - Kinesis Firehose에서 Json 형태로 Log를 저장하기 위해 Python Code를 Lambda로 실행합니다.
<br/>


   **nginx log format**

| Parameter |                                                    |
| --------- | -------------------------------------------------- |
| host      | 클라이언트의 IP 주소                               |
| timestamp | 타임스탬프                                         |
| request   | 서버에 제출된 요청                                 |
| uri       | 요청에 포함된 uri 정보                             |
| status    | HTTP 응답코드                                      |
| size      | 서버가 클라이언트로 전송한 응답의 크기             |
| verb      | HTTP Method                                        |
| refferer  | 클라이언트를 이 서버로 오게 만든 이전 페이지의 URL |
| useragent | HTTP요청에 사용된 브라우저 타입                    |
<br/>


   - S3에 저장되는 Log 내용

```
{"host": "1.229.242.14", "timestamp": "2020-12-22T12:32:36", "request": "GET / HTTP/1.1", "uri": "/ ", "status": "304", "size": "0", "verb": "GET", "refferer": "-", "useragent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36\" \"-"}
```
<br/>


   - 추후 Athena Partioning을 위해 YYYY/HH/MM 형식으로 경로명 지정

```
s3://nginx-access-logs-s3/2020/12/22/12/
nginx-logs-to-s3-1-2020-12-22-12-20-28-7578adbc-da7c-4c3c-86a7-89c99057ee7d
```

