import datetime
import random
import string

from firebase_admin import firestore
from google.cloud import exceptions

from .user_event import UserEvent

class Device(object):
    ACTIVATE = 'activate'
    
    def __init__(self, parent, device_id, account, out_topic, in_topic,
                 out_sub, in_sub, device_key, app_key, app_id,
                 created = datetime.datetime.now()):
        self.parent = parent
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

    def save(self, db):
        user_ref = db.collection(u'users')
        user_doc_ref = user_ref.document(self.parent.email)
        device_ref = user_doc_ref.collection(u'devices').document(self.device_id)
        device_ref.set(self.to_dict())
 
    @staticmethod
    def load(user, db, device_id):
        user_ref = db.collection(u'users')
        user_doc_ref = user_ref.document(user.email)
        device_doc_ref = user_doc_ref.collection(u'devices').document(device_id)
        device_doc = None
        try:
            device_doc = device_doc_ref.get()
        except google.cloud.exceptions.NotFound:
            return None

        if device_doc is None or not device_doc.exists:
            return None

        device = Device.from_dict(device_doc.to_dict())
        device.parent = user
        return device


    @staticmethod
    def from_dict(source):
        return Device(parent = None,
                      device_id = source["device_id"],
                      account = source['account'],
                      out_topic = source["out_topic"],
                      in_topic = source["in_topic"],
                      out_sub = source["out_sub"],
                      in_sub = source["in_sub"],
                      device_key = source["device_key"],
                      app_key = source["app_key"],
                      app_id = source["app_id"],
                      created = source["created"])

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

    def create_sharing_invitation(self, db, shared_user_email):
        def randomString(stringLength=10):
            """Generate a random string of fixed length """
            letters = string.ascii_lowercase
            return ''.join(random.choice(letters) for i in range(stringLength))

        # Record invitation
        invite_token = randomString(20)
        invite_doc = db.collection(u'sharing_invites').document(invite_token)
        invite_doc.set({
            'token': invite_token,
            'owner_user_id': self.parent.id,
            'owner_user_email': self.parent.email,
            'device_id': self.device_id,
            'invited_user_email': shared_user_email,
            'created': datetime.datetime.now()
        })

    def record_activation(self, db):
        event = UserEvent(self.parent.email, self.device_id, UserEvent.ACTIVATE)
        event.save(db)

    def __repr__(self):
        return(
            u'Device(device_id={}, account={}, out_topic={}, in_topic={}, out_sub={}, in_sub={}, app_id={}, created={})'
            .format(self.device_id, self.account, self.out_topic, self.in_topic, self.out_sub, self.in_sub, self.app_id, self.created))
