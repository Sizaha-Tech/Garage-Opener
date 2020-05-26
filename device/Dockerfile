# See read.me file for build and run instructions.
#

FROM arm32v7/python:3

WORKDIR /garage_app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV GOOGLE_APPLICATION_CREDENTIALS=/garage_settings/service_account.json
ENV SERVICE_ACCOUNT_FILE=/garage_settings/settings.json
ENV BOOTSTRAP_PORT=8080

CMD ["/bin/bash", "./start_device.sh"]

# CMD [ "python", "./garage_daemon.py" ]
