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

from flask import Flask, jsonify, request
import flask_cors
# from google.appengine.ext import ndb

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import google.auth.transport.requests
import google.oauth2.id_token
#import requests_toolbelt.adapters.appengine

# Use the App Engine Requests adapter. This makes sure that Requests uses
# URLFetch.
# requests_toolbelt.adapters.appengine.monkeypatch()
HTTP_REQUEST = google.auth.transport.requests.Request()

app = Flask(__name__)
flask_cors.CORS(app)

# Use a service account
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
    
    def __init__(self, device_id, topic, out_sub, in_sub, created = datetime.datetime.now()):
        self.device_id = device_id
        self.topic = topic
        self.out_sub = out_sub
        self.in_sub = in_sub
        self.created = created

    @staticmethod
    def from_dict(source):
        return Device(source["device_id"],
                      source["topic"],
                      source["out_sub"],
                      source["in_sub"],
                      source["created"])

    def to_dict(self):
        return {
            "device_id": self.device_id,
            "topic": self.topic,
            "out_sub": self.out_sub,
            "in_sub": self.in_sub,
            "created": self.created
        }

    def __repr__(self):
        return(
            u'Device(device_id={}, topic={}, out_sub={}, in_sub={}, created={})'
            .format(self.device_id, self.topic, self.out_sub, self.in_sub, self.created))

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

    if device_doc is None:
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

def create_device(user_id, device_id, device_name):
    


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


@app.route('/notes', methods=['POST', 'PUT'])
def add_note():
    """
    Adds a note to the user's notebook. The request should be in this format:

        {
            "message": "note message."
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

    # Populates note properties according to the model,
    # with the user ID as the key name.
    note = Note(friendly_id = claims.get('name', claims.get('email', 'Unknown')),
                message=data['message'])

    user_id = claims['sub']
    user_ref = db.collection(u'users')
    user_doc_ref = user_ref.document(user_id)
    user_doc = user_doc_ref.set(
        User(name=claims.get('name'),
                email = claims.get('email')).to_dict())

    notes_ref = user_doc_ref.collection(u'notes')
    notes_ref.add(note.to_dict())

    return 'OK', 200

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
def activate():
    """
    Creates a new device:

        {
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

    # [START gae_python_create_entity]
    data = request.get_json()

    user_id = claims['sub']
    device_id = data['device_id']
    device_name = data['device_name']
    device = get_device(user_id, device_id)
    if device is not None:
        return "Device already exists", 409

    create_device(user_id, device_id, device_name)
    return 'OK', 200


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
