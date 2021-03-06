import json
from google.cloud import pubsub_v1
import time
import os
import RPi.GPIO as GPIO


SETTINGS_FILE = os.environ.get('SETTINGS_FILE')
PROJECT_ID = "household-iot-277519"

def open_garage():
    print('Opening garage door...')
    GPIO.output(23, False)
    GPIO.output(23, True)
    time.sleep(1)
    GPIO.output(23, False)

def receive_messages(project_id, subscription_name):
    """Receives messages from a pull subscription."""
    subscriber = pubsub_v1.SubscriberClient()
    # The `subscription_path` method creates a fully qualified identifier
    # in the form `projects/{project_id}/subscriptions/{subscription_name}`
    subscription_path = subscriber.subscription_path(
        project_id, subscription_name)

    def callback(message):
        print('Received message: {}'.format(message))
        message.ack()
        open_garage()

    subscriber.subscribe(subscription_path, callback=callback)
    # The subscriber is non-blocking. We must keep the main thread from
    # exiting to allow it to process messages asynchronously in the background.
    print('Listening for messages on {}'.format(subscription_path))
    while True:
        time.sleep(60)

if __name__ == '__main__':
    print('Initializing GPIO...')
    GPIO.setwarnings(False)
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(23,GPIO.OUT)

    fp = open(SETTINGS_FILE)
    settings = json.load(fp)
    receive_messages(PROJECT_ID, settings['in_subscription'])