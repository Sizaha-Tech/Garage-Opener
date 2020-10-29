# **Smart Garage Door Opener**
### a **Sizaha LLC** Product
#### by Ivan Hornung

![Sizaha Smart Garage Door Opener product: Front View](https://i.imgur.com/zwA3dkd.png)

-----

## **Sizaha Design**
![Sizaha overview diagram](https://i.imgur.com/J9fERli.png)

The Sizaha IoT (Internet of Things) platform is composed of **three** fundamental moving pieces:

- **Raspberry Pi device**
- **Cloud**
- **Mobile Application**
  
---

### **Raspberry Pi device**
There are many different daemons and scripts on the **Raspberry Pi Zero W** device that run based on the state of the device. There are 3 different possible states of the device:

- Factory
- Test Config
- Configured

When the device is in its configured state (meaning that it successfully completed its bootstrapping), GarageDaemon controls the Raspberry Pi Zero's GPIO output on pin 23.

When given the proper instruction, GarageDaemon signals to the optical coupling relay switch to close the circuit, which is what triggers the garage into either opening, closing, or stopping (same as if you pressed the physical garage door button).

Scripts are written in `Shell` and `Python` (using `Flask`).

---

### **Cloud**

The Google Cloud + Firebase component of the Sizaha platform is composed of **four** different services:

- **API Server**
- **Firestore (database)**
- **PubSub**
- **Firebase authentication**


#### **API Server**
The **API server** is a business-specific service that I created and serves the purpose of registering devices, getting the list of a user's devices, making sure the user gets the proper device and not others, and to send the command to open the garage. The API server (api.sizaha.com) runs in the cloud, and tells the PubSub or the Firestore what to do. The mobile application sends HTTP messages to the API server that either retrieve or send a chunk of JSON data. The API server is written in `Python` using `Flask`.

#### **Firestore**
The **Firestore** is the database where the data is saved. This is where a track record of 'who owns what' is kept. It stores all the data related to the Sizaha business.

#### **PubSub**
**PubSub** is a message queue service between the website/mobile application, and the Raspberry Pi device. The app/website delivers a message to the API server, which sends the message to the PubSub, which pushes the message to the device. Instead of having the device asking for HTTP GET requests constantly all the time, the PubSub pushes messages to the respectice device. Based on the topic and the subscription of the message, it figures out which device to route the message to.

#### **Firebase Authentication**
**Firebase Authentication** is a service Sizaha uses as an identity provider. This means that a user must log in with either their *Google*, *Twitter*, or *Facebook* accounts in order to use the application. The Firebase authentication service is used so that I didn't have to invent my own user management system.


---

### **Mobile Application**

The mobile application is the client-side of the of the platform. It allows the user to activate the garage door, connect to the Raspberry Pi device during the bootstrapping process, and other user actions.

![Sizaha App Screens: Login, Auth, and Confirmation](https://i.imgur.com/cf3KusT.png)
![Sizaha App Screens: Start bootstrapping, activation, Boostrapping (coming soon)](https://i.imgur.com/16OfENn.png)

---
## **Hardware**

### **Exterior**
![Exterior images of Garage Door Opener product](https://i.imgur.com/9XNOII9.png)


### **3D Design**
![3D Design of case](https://i.imgur.com/f1StImG.png)

### **Interior**
![Interior of case](https://i.imgur.com/YN6AgMh.png)

![Interior of case (annotated)](https://i.imgur.com/2jtwNqD.png)
