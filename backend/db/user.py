from .device import Device 

import datetime

from firebase_admin import firestore
from google.cloud import exceptions

class User(object):
    def __init__(self, id, email, name, created = datetime.datetime.now()):
        self.id = id
        self.email = email
        self.name = name
        self.created = created
    
    def save(self, db):
        user_ref = db.collection(u'users')
        user_doc_ref = user_ref.document(self.email)
        user_doc_ref.set(self.to_dict())

    @staticmethod
    def load(db, user_email):
        user_doc_ref = db.collection(u'users').document(user_email)
        user_doc = None
        try:
            user_doc = user_doc_ref.get()
        except google.cloud.exceptions.NotFound:
            return None

        if user_doc is None or not user_doc.exists:
            return None

        return User.from_dict(user_doc.to_dict())
        
    @staticmethod
    def from_dict(source):
        return User(source["id"],
                    source["email"],
                    source["name"],
                    source["created"])

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "name": self.name,
            "created": self.created
        }

    def get_device(self, db, device_id):
        device = Device.load(self, db, device_id)
        return device

    def get_devices(self, db):
        """Fetches all devices associated with user_email.

        Devices are ordered them by date created, with most recent note added
        first.
        """
        user_ref = db.collection(u'users')
        user_doc_ref = user_ref.document(self.email)
        devices = []
        try:
            for device_doc in user_doc_ref.collection(u'devices').get():
                device = Device.from_dict(device_doc.to_dict())
                device.parent = self
                devices.append(device)

        except google.cloud.exceptions.NotFound:
            return devices

        return devices

    def create_device(self, device_id, account, out_topic, in_topic,
                 out_sub, in_sub, device_key, app_key, app_id,
                 created = datetime.datetime.now()):
        return Device(self, device_id, account,
            out_topic, in_topic, out_sub, in_sub,
            device_key, app_key, app_id)

    def share_device(self, db, owner_user_email, owner_device_id):
        # Record shared account under the owner device document. 
        user_doc_ref = db.collection(u'users').document(owner_user_email)
        device_doc_ref = user_doc_ref.collection(u'devices').document(owner_device_id)
        shared_account = device_doc_ref.collection(u'shared_accounts').document(user_email)
        shared_account.set({
            'user_email': self.email,
            'user_name': self.name
        })
        
        # Record shared device under the current user. 
        user_doc_ref = db.collection(u'users').document(self.email)
        device_doc_ref = user_doc_ref.collection(u'shared_devices').document(owner_user_email+'/'+owner_device_id)
        device_doc_ref.set({
            'user_email': owner_user_email,
            'device_id': owner_device_id
        })

    def __repr__(self):
        return(
            u'User(id={}, email={}, name={}, created={})'
            .format(self.id, self.name, self.email, self.created))
