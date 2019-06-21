# Copyright 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import logging
import datetime

from flask import Flask, json, jsonify, request
import flask_cors
# from google.appengine.ext import ndb

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

from google.cloud import pubsub_v1

from google.oauth2 import service_account, id_token
import googleapiclient.discovery
import google.auth.transport.requests

#import requests_toolbelt.adapters.appengine

# Use the App Engine Requests adapter. This makes sure that Requests uses
# URLFetch.
# requests_toolbelt.adapters.appengine.monkeypatch()
HTTP_REQUEST = google.auth.transport.requests.Request()
PROJECT_ID = 'trusty-splice-230419'
PUBSUB_TIMEOUT = 60     # seconds

# Device commands
COMMAND_OPEN = 'OPEN'

app = Flask(__name__)
flask_cors.CORS(app)

# Use a service account
service_cred = service_account.Credentials.from_service_account_file(
    filename='accounts/backendServiceAccount.json',
    scopes=['https://www.googleapis.com/auth/cloud-platform'])
service_api = googleapiclient.discovery.build(
    'iam', 'v1', credentials=service_cred)


cred = credentials.Certificate('accounts/backendServiceAccount.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

class Note(object):
    def __init__(self, friendly_id, message, created = datetime.datetime.now()):
        self.friendly_id = friendly_id
        self.message = message
        self.created = created
    
    @staticmethod
    def from_dict(source):
        return Note(source['friendly_id'],
                    source['message'],
                    source['created'])

    def to_dict(self):
        return {
            "friendly_id": self.friendly_id,
            "message": self.message,
            "created": self.created
        }

    def __repr__(self):
        return(
            u'Note(friendly_id={}, message={}, created={})'
            .format(self.friendly_id, self.message, self.created))

class User(object):
    def __init__(self, name, email, created = datetime.datetime.now()):
        self.name = name
        self.email = email
        self.created = created
    
    @staticmethod
    def from_dict(source):
        return User(source["name"],
                    source["email"],
                    source["created"])

    def to_dict(self):
        return {
            "name": self.name,
            "email": self.email,
            "created": self.created
        }

    def __repr__(self):
        return(
            u'User(name={}, email={}, created={})'
            .format(self.name, self.email, self.created))

class Device(object):
    ACTIVATE = 'activate'
    
    def __init__(self, device_id, account, out_topic, in_topic,
                 out_sub, in_sub, device_key, app_key, app_id,
                 created = datetime.datetime.now()):
        self.device_id = device_id
        self.account = account
        self.out_topic = out_topic
        self.in_topic = in_topic
        self.out_sub = out_sub
        self.in_sub = in_sub
        self.device_key = device_key
        self.app_key = app_key
        self.app_id = app_id
        self.created = created

    @staticmethod
    def from_dict(source):
        return Device(source["device_id"],
                      source['account'],
                      source["out_topic"],
                      source["in_topic"],
                      source["out_sub"],
                      source["in_sub"],
                      source["device_key"],
                      source["app_key"],
                      source["app_id"],
                      source["created"])

    def to_dict(self):
        return {
            "device_id": self.device_id,
            "account": self.account,
            "out_topic": self.out_topic,
            "in_topic": self.in_topic,
            "out_sub": self.out_sub,
            "in_sub": self.in_sub,
            "device_key": self.device_key,
            "app_key": self.app_key,
            "app_id": self.app_id,
            "created": self.created
        }

    def __repr__(self):
        return(
            u'Device(device_id={}, account={}, out_topic={}, in_topic={}, out_sub={}, in_sub={}, app_id={}, created={})'
            .format(self.device_id, self.account, self.out_topic, self.in_topic, self.out_sub, self.in_sub, self.app_id, self.created))

class UserEvent(object):
    ACTIVATE = 'activate'
    
    def __init__(self, user_id, device_id, event_type, created = datetime.datetime.now()):
        self.user_id = user_id
        self.device_id = device_id
        self.event_type = event_type
        self.created = created

    @staticmethod
    def from_dict(source):
        return UserEvent(source["user_id"],
                         source["device_id"],
                         source["event_type"],
                         source["created"])

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "device_id": self.device_id,
            "event_type": self.event_type,
            "created": self.created
        }

    def __repr__(self):
        return(
            u'User(user_id={}, device_id={}, event_type={}, created={})'
            .format(self.user_id, self.device_id, self.event_type, self.created))

def create_service_account(project_id, service_name, display_name):
    """Creates a service account."""
    service_account = service_api.projects().serviceAccounts().create(
        name='projects/' + project_id,
        body={
            'accountId': service_name,
            'serviceAccount': {
                'displayName': display_name
            }
        }).execute()
    logging.info('Created service account: ' + service_account['email'])
    return service_account

def create_service_key(service_account_email):
    """Creates a key for a service account."""
    # pylint: disable=no-member
    key = service_api.projects().serviceAccounts().keys().create(
        name='projects/-/serviceAccounts/' + service_account_email, body={}
        ).execute()
    return key

def create_topic(project_id, topic_name):
    """Create a new Pub/Sub topic."""
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_name)
    topic = publisher.create_topic(topic_path)

def create_subscription(project_id, topic_name, subscription_name):
    """Create a new pull subscription on the given topic."""
    subscriber = pubsub_v1.SubscriberClient()
    topic_path = subscriber.topic_path(project_id, topic_name)
    subscription_path = subscriber.subscription_path(
        project_id, subscription_name)
    subscription = subscriber.create_subscription(
        subscription_path, topic_path)

def set_pubsub_topic_policy(project, topic_name, publisher_account, subscriber_account):
    """Sets the IAM policy for a topic."""
    client = pubsub_v1.PublisherClient()
    topic_path = client.topic_path(project, topic_name)
    policy = client.get_iam_policy(topic_path)
    # Add the service account policy for the topic.
    publisher_account_member = "serviceAccount:%s" % publisher_account
    subscriber_account_member = "serviceAccount:%s" % subscriber_account
    policy.bindings.add(
        role='roles/pubsub.viewer',
        members=[publisher_account_member, subscriber_account_member])
    policy.bindings.add(
        role='roles/pubsub.admin',
        members=[publisher_account_member])
    policy.bindings.add(
        role='roles/pubsub.editor',
        members=[publisher_account_member])
    policy.bindings.add(
        role='roles/pubsub.subscriber',
        members=[subscriber_account_member])
    # Set the policy
    policy = client.set_iam_policy(topic_path, policy)


def get_device(user_id, device_id):
    """Checks if user_id owns this device_id
    """
    user_ref = db.collection(u'users')
    user_doc_ref = user_ref.document(user_id)
    device_doc_ref = user_doc_ref.collection(u'devices').document(device_id)
    device_doc = None
    try:
        device_doc = device_doc_ref.get()
    except google.cloud.exceptions.NotFound:
        return None

    if device_doc is None or not device_doc.exists:
        return None

    return Device.from_dict(device_doc.to_dict())

def perform_activation(user_id, device):
    activate_device(user_id, device)
    record_activation(user_id, device)
    return

def activate_device(user_id, device):
    #TODO: Add PubSub
    return


def record_activation(user_id, device):
    event = UserEvent(user_id, device.device_id, UserEvent.ACTIVATE)
    user_ref = db.collection(u'users')
    user_doc_ref = user_ref.document(user_id)
    events_ref = user_doc_ref.collection(u'events')
    events_ref.add(event.to_dict())

def setup_device(user_id, app_id, device_id, device_name):
    in_topic_name = "g-in-topic-%s-%s" % (user_id, device_id)
    out_topic_name = "g-out-topic-%s-%s" % (user_id, device_id)
    service_account_name = "g-svc-%s" % device_id
    app_account_name = "g-app-%s" % app_id
    out_sub = "out-sub-%s" % device_id
    in_sub = "in-sub-%s" % device_id
    # Create service account, topic and in/out subscriptions
    service_account = create_service_account(PROJECT_ID, service_account_name, "Garage Opener %s" % device_id)
    app_account = create_service_account(PROJECT_ID, app_account_name, "Garage App %s" % user_id)
    service_account_handle = service_account['email']
    app_account_handle = app_account['email']
    service_key = create_service_key(service_account_handle)
    app_key = create_service_key(app_account_handle)

    create_topic(PROJECT_ID, in_topic_name)
    create_topic(PROJECT_ID, out_topic_name)
 
    service_policy_member = "serviceAccount:%s" % service_account_handle
    app_policy_member = "serviceAccount:%s" % app_account_handle
    set_pubsub_topic_policy(PROJECT_ID, in_topic_name, publisher_account=app_account_handle, subscriber_account=service_account_handle)
    set_pubsub_topic_policy(PROJECT_ID, out_topic_name, publisher_account=service_account_handle, subscriber_account=app_account_handle)
 
    create_subscription(PROJECT_ID, in_topic_name, in_sub)
    create_subscription(PROJECT_ID, out_topic_name, out_sub)

    # Store device info
    user_ref = db.collection(u'users')
    user_doc_ref = user_ref.document(user_id)
    device = Device(device_id, service_account_handle,
        out_topic_name, in_topic_name, out_sub, in_sub,
        json.dumps(service_key), json.dumps(app_key), app_id)
    device_ref = user_doc_ref.collection(u'devices').document(device_id)
    device_dict = device.to_dict()
    device_ref.set(device_dict)
    return device_dict

def send_open_command_to_device(device):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, device.in_topic)
    data = {'command': COMMAND_OPEN}
    future = publisher.publish(topic_path, data = json.dumps(data))
    res = future.result(PUBSUB_TIMEOUT)
    
# [START gae_python_query_database]
def query_database(user_id):
    """Fetches all notes associated with user_id.

    Notes are ordered them by date created, with most recent note added
    first.
    """
    user_ref = db.collection(u'users')
    user_doc_ref = user_ref.document(user_id)
    note_messages = []
    try:
        for note_doc in user_doc_ref.collection(u'notes').get():
            note = note_doc.to_dict()
            note_messages.append({
                'friendly_id': note['friendly_id'],
                'message': note['message'],
                'created': note['created']
            })

    except google.cloud.exceptions.NotFound:
        return note_messages

    return note_messages
# [END gae_python_query_database]


@app.route('/notes', methods=['GET'])
def list_notes():
    """Returns a list of notes added by the current Firebase user."""

    # Verify Firebase auth.
    # [START gae_python_verify_token]
    id_token = request.headers['Authorization'].split(' ').pop()
    claims = google.oauth2.id_token.verify_firebase_token(
        id_token, HTTP_REQUEST)
    if not claims:
        return 'Unauthorized', 401
    # [END gae_python_verify_token]

    notes = query_database(claims['sub'])

    return jsonify(notes)


@app.route('/activate', methods=['POST', 'PUT'])
def activate():
    """
    Activated the garage opener of a given device:

        {
            "device_id": "device identifier."
        }
    """

    # Verify Firebase auth.
    id_token = request.headers['Authorization'].split(' ').pop()
    claims = google.oauth2.id_token.verify_firebase_token(
        id_token, HTTP_REQUEST)
    if not claims:
        return 'Unauthorized', 401

    # [START gae_python_create_entity]
    data = request.get_json()

    user_id = claims['sub']
    device_id = data['device_id']
    device = get_device(user_id, device_id)
    if device is None:
        return "Device not found", 404

    perform_activation(user_id, device)

    return 'OK', 200

@app.route('/device', methods=['POST', 'PUT'])
def create_device():
    """
    Creates a new device:

        {
            "app_id": "app install instance identifier.",
            "device_id": "device identifier.",
            "device_name": "device name."
        }
    """

    # Verify Firebase auth.
    id_token = request.headers['Authorization'].split(' ').pop()
    claims = google.oauth2.id_token.verify_firebase_token(
        id_token, HTTP_REQUEST)
    if not claims:
        return 'Unauthorized', 401

    user_id = claims['sub']

    data = request.get_json()
    device_id = data['device_id']
    device_name = data['device_name']
    device = get_device(user_id, device_id)
    if device is not None:
        return "Device already exists", 409

    device_dict = setup_device(user_id, data['app_id'], device_id, device_name)
    return jsonify(device_dict), 200

@app.route('/device/<device_id>/run', methods=['POST', 'PUT'])
def open_device(device_id):
    """
    Opens garage on specific device:

        {
            "command": "device command.",
        }
    """

    # Verify Firebase auth.
    id_token = request.headers['Authorization'].split(' ').pop()
    claims = google.oauth2.id_token.verify_firebase_token(
        id_token, HTTP_REQUEST)
    if not claims:
        return 'Unauthorized', 401

    data = request.get_json()

    command = data['command']
    if command != COMMAND_OPEN :
        return 'Unknown command', 400

    user_id = claims['sub']
    device = get_device(user_id, device_id)
    if device is None:
        return "Device does not exists", 404

    send_open_command_to_device(device)
    return jsonify(device_dict), 200


@app.errorhandler(500)
def server_error(e):
    # Log the error and stacktrace.
    logging.exception('An error occurred during a request.')
    return 'An internal error occurred.', 500

if __name__ == '__main__':
    for v in ['PORT']:
        if os.environ.get(v) is None:
            print("error: {} environment variable not set".format(v))
            exit(1)

    # start Flask server
    # Flask's debug mode is unrelated to ptvsd debugger used by Cloud Code
    app.run(debug=False, port=int(os.environ.get('PORT')), host='0.0.0.0')
