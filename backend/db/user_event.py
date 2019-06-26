import datetime

from firebase_admin import firestore
from google.cloud import exceptions

class UserEvent(object):
    ACTIVATE = 'activate'
    
    def __init__(self, user_email, device_id, event_type, created = datetime.datetime.now()):
        self.user_email = user_email
        self.device_id = device_id
        self.event_type = event_type
        self.created = created

    def save(self, db):
        user_ref = db.collection(u'users')
        user_doc_ref = user_ref.document(self.user_email)
        events_ref = user_doc_ref.collection(u'events')
        events_ref.add(self.to_dict())

    @staticmethod
    def from_dict(source):
        return UserEvent(source["user_email"],
                         source["device_id"],
                         source["event_type"],
                         source["created"])

    def to_dict(self):
        return {
            "user_email": self.user_email,
            "device_id": self.device_id,
            "event_type": self.event_type,
            "created": self.created
        }

    def __repr__(self):
        return(
            u'UserEvent(user_email={}, device_id={}, event_type={}, created={})'
            .format(self.user_email, self.device_id, self.event_type, self.created))
