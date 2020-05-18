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
from functools import reduce
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

from db.user import User
from db.device import Device
from db.user_event import UserEvent

#import requests_toolbelt.adapters.appengine

# Use the App Engine Requests adapter. This makes sure that Requests uses
# URLFetch.
# requests_toolbelt.adapters.appengine.monkeypatch()
HTTP_REQUEST = google.auth.transport.requests.Request()
PROJECT_ID = 'household-iot-277519'
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
        name='projects/-/serviceAccounts/' + service_account_email,body={}
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

def set_pubsub_subscription_policy(project, subscription_name, subscription_account):
    """Sets the IAM policy for a subscription."""
    client = pubsub_v1.SubscriberClient()
    subscription_path = client.subscription_path(project, subscription_name)
    policy = client.get_iam_policy(subscription_path)
    # Add the service account policy for the topic.
    subscription_account_member = "serviceAccount:%s" % subscription_account
    policy.bindings.add(
        role='roles/pubsub.viewer',
        members=[subscription_account_member])
    policy.bindings.add(
        role='roles/pubsub.subscriber',
        members=[subscription_account_member])
    # Set the policy
    policy = client.set_iam_policy(subscription_path, policy)

def setup_new_device(user, app_id, device_id, device_name):
    in_topic_name = "g-in-topic-%s-%s" % (user.id, device_id)
    out_topic_name = "g-out-topic-%s-%s" % (user.id, device_id)
    service_account_name = "g-svc-%s" % device_id
    app_account_name = "g-app-%s" % app_id
    out_sub = "out-sub-%s" % device_id
    in_sub = "in-sub-%s" % device_id
    # Create service account, topic and in/out subscriptions
    service_account = create_service_account(PROJECT_ID, service_account_name, "Garage Opener %s" % device_id)
    app_account = create_service_account(PROJECT_ID, app_account_name, "Garage App %s" % user.email)
    service_account_handle = service_account['email']
    app_account_handle = app_account['email']
    service_key = create_service_key(service_account_handle)
    app_key = create_service_key(app_account_handle)

    create_topic(PROJECT_ID, in_topic_name)
    create_topic(PROJECT_ID, out_topic_name)
 
    set_pubsub_topic_policy(PROJECT_ID, in_topic_name, publisher_account=app_account_handle, subscriber_account=service_account_handle)
    set_pubsub_topic_policy(PROJECT_ID, out_topic_name, publisher_account=service_account_handle, subscriber_account=app_account_handle)
 
    create_subscription(PROJECT_ID, in_topic_name, in_sub)
    create_subscription(PROJECT_ID, out_topic_name, out_sub)
    set_pubsub_subscription_policy(PROJECT_ID, in_sub, service_account_handle)
    set_pubsub_subscription_policy(PROJECT_ID, out_sub, app_account_handle)

    # Store device info
    device = user.create_device(device_id, service_account_handle,
        out_topic_name, in_topic_name, out_sub, in_sub,
        json.dumps(service_key), json.dumps(app_key), app_id)
    device.save(db)
    return device

def send_open_command_to_device(device):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, device.in_topic)
    data = u'{}'.format(json.dumps({'command': COMMAND_OPEN}))
    # Data must be a bytestring
    data = data.encode('utf-8')
    future = publisher.publish(topic_path, data = data)
    # future.result(PUBSUB_TIMEOUT)
    future.result(PUBSUB_TIMEOUT)
    
def get_or_create_user(claims):
    user_email = claims.get('email')
    user = User.load(db, user_email)

    if user is None:
        user_id = claims['sub']
        user_name = claims.get('name')
        user =  User(id = user_id,
                    email = user_email,
                    name = user_name)
        user.save(db)
    return user


def check_authorization(request):
    # Verify Firebase auth.
    if 'Authorization' in request.headers:
        id_token = request.headers['Authorization'].split(' ').pop()
        claims = google.oauth2.id_token.verify_firebase_token(
            id_token, HTTP_REQUEST)
        return claims

    return None


@app.route('/hello', methods=['GET'])
def hello():
    """Returns a list of notes added by the current Firebase user."""

    return jsonify({
            "hello": 'world!'
        })

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
    claims = check_authorization(request)
    if claims is None:
        return 'Unauthorized', 401

    user = get_or_create_user(claims)
 
    data = request.get_json()
    device_id = data['device_id']
    device = user.get_device(db, device_id)
    if device is not None:
        return "Device already exists", 409

    device = setup_new_device(user, data['app_id'], device_id,  data['device_name'])
    return jsonify(device.to_dict()), 200


@app.route('/devices', methods=['GET'])
def list_devices():
    """Returns a list of notes added by the current Firebase user."""

    # Verify Firebase auth.
    claims = check_authorization(request)
    if claims is None:
        return 'Unauthorized', 401

    user = get_or_create_user(claims)
    devices = user.get_devices(db)
    return jsonify(reduce(lambda p, x: p+[x], (device.to_dict() for device in devices), []))


@app.route('/shared_device/<device_id>/share', methods=['POST', 'PUT'])
def share_device(device_id):
    """
    Creates a record of a new shared device:
        {
            "shared_user_email": "device name"
        }
    """

    # Verify Firebase auth.
    claims = check_authorization(request)
    if claims is None:
        return 'Unauthorized', 401

    user = get_or_create_user(claims)
    device = user.get_device(db, device_id)
    if device is None:
        return "Device does not exist", 404

    data = request.get_json()
    device.create_sharing_invitation(data['shared_user_email'])
    return "OK", 200

@app.route('/device/<device_id>/run', methods=['POST', 'PUT'])
def open_device(device_id):
    """
    Opens garage on specific device:

        {
            "command": "device command.",
        }
    """

    # Verify Firebase auth.
    claims = check_authorization(request)
    if claims is None:
        return 'Unauthorized', 401

    data = request.get_json()

    command = data['command']
    if command != COMMAND_OPEN :
        return 'Unknown command', 400

    user = get_or_create_user(claims)
    device = user.get_device(db, device_id)
    if device is None:
        return "Device does not exists", 404

    send_open_command_to_device(device)
    device.record_activation(db)
    return jsonify(device.to_dict()), 200


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
