# $ docker run -d \
#  -it \
#  --name garage \
#  -v "/garage/config:/app/config \
#
#

FROM arm32v7/python:3

WORKDIR /bootstrap_app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD [ "python", "./bootstrap_server.py" ]
