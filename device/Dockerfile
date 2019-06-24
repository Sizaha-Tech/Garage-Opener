# $ docker run -d \
#  -it \
#  --name garage \
#  -v "/garage/config:/app/config \
#
#

FROM arm32v7/python:3

WORKDIR /garage_app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt


COPY . .

ENV GOOGLE_APPLICATION_CREDENTIALS=/app/config/service_credentials.json

CMD [ "python", "./garage_daemon.py" ]
