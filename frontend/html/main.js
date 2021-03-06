// Copyright 2020, Sizaha LLC
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
var g_devices = null;
var g_project_name = 'household-iot-277519';

$(function(){
  // This is the host for the backend.
  // TODO: When running Firenotes locally, set to http://localhost:8081. Before
  // deploying the application to a live production environment, change to
  // https://backend-dot-<PROJECT_ID>.appspot.com as specified in the
  // backend's app.yaml file.
  var backendHostUrl = 'http://dev_api.sizaha.com:8080';

  // [START gae_python_firenotes_config]
  // Obtain the following from the "Add Firebase to your web app" dialogue
  // Initialize Firebase
  var firebaseConfig = {
    apiKey: "AIzaSyAM50XFC-Qg6EmPayq28_uU9QVW4M8PLh8",
    authDomain: g_project_name+".firebaseapp.com",
    databaseURL: "https://" + g_project_name + ".firebaseio.com",
    projectId: g_project_name,
    storageBucket: g_project_name+".appspot.com",
    messagingSenderId: "217032520272",
    appId: "1:217032520272:web:f843a0a671a37791e89755",
    measurementId: "G-PRPEQHD10R"
  };

  // [END gae_python_firenotes_config]

  // This is passed into the backend to authenticate the user.
  var userIdToken = null;
  // Firebase log-in
  function configureFirebaseLogin() {

    firebase.initializeApp(firebaseConfig);
    firebase.analytics();

    // [START gae_python_state_change]
    firebase.auth().onAuthStateChanged(function(user) {
      if (user) {
        $('#logged-out').hide();
        var name = user.displayName;

        /* If the provider gives a display name, use the name for the
        personal welcome message. Otherwise, use the user's email. */
        var welcomeName = name ? name : user.email;

        user.getIdToken().then(function(idToken) {
          userIdToken = idToken;

          /* Now that the user is authenicated, fetch the notes. */
          fetchDevices();

          $('#user').text(welcomeName);
          $('#logged-in').show();

        });

      } else {
        $('#logged-in').hide();
        $('#logged-out').show();

      }
    // [END gae_python_state_change]

    });

  }

  // [START configureFirebaseLoginWidget]
  // Firebase log-in widget
  function configureFirebaseLoginWidget() {
    var uiConfig = {
      'signInSuccessUrl': '/',
      'signInOptions': [
        // Leave the lines as is for the providers you want to offer your users.
        firebase.auth.GoogleAuthProvider.PROVIDER_ID,
//        firebase.auth.FacebookAuthProvider.PROVIDER_ID,
//        firebase.auth.TwitterAuthProvider.PROVIDER_ID,
//        firebase.auth.GithubAuthProvider.PROVIDER_ID,
        firebase.auth.EmailAuthProvider.PROVIDER_ID
      ],
      // Terms of service url
      'tosUrl': '<your-tos-url>',
    };

    var ui = new firebaseui.auth.AuthUI(firebase.auth());
    ui.start('#firebaseui-auth-container', uiConfig);
  }
  // [END gae_python_firebase_login]

  // [START gae_python_fetch_notes]
  // Fetch notes from the backend.
  function fetchDevices() {
    $.ajax(backendHostUrl + '/devices', {
      /* Set header for the XMLHttpRequest to get data from the web server
      associated with userIdToken */
      headers: {
        'Authorization': 'Bearer ' + userIdToken
      }
    }).then(function(data){
      $('#devices-container').empty();
      g_devices = data;
      // Iterate over user data to display user's notes from database.
      data.forEach(function(device){
        $('#devices-container').append($('<p>').text(device.device_id+'/'+device.out_topic));
      });
    });
  }
  // [END gae_python_fetch_notes]

  // Sign out a user
  var signOutBtn =$('#sign-out');
  signOutBtn.click(function(event) {
    event.preventDefault();

    firebase.auth().signOut().then(function() {
      console.log("Sign out successful");
    }, function(error) {
      console.log(error);
    });
  });

  // Save a note to the backend
  var createBtn = $('#create-device');
  createBtn.click(function(event) {
    event.preventDefault();

    var deviceIdField = $('#device-id');
    var device_id = deviceIdField.val();
    deviceIdField.val("");

    var deviceNameField = $('#device-name');
    var device_name = deviceNameField.val();
    deviceNameField.val("");

    var appIdField = $('#app-id');
    var app_id = appIdField.val();
    appIdField.val("");

    /* Send note data to backend, storing in database with existing data
    associated with userIdToken */
    $.ajax(backendHostUrl + '/device', {
      headers: {
        'Authorization': 'Bearer ' + userIdToken
      },
      method: 'POST',
      data: JSON.stringify({
        'app_id': app_id,
        'device_id': device_id,
        'device_name': device_name
      }),
      contentType : 'application/json'
    }).then(function(){
      // Refresh notebook display.
      fetchDevices();
    });

  });

  // Save a note to the backend
  var openBtn = $('#open-device');
  openBtn.click(function(event) {
    event.preventDefault();

    var deviceIdField = $('#device-id');
    var device_id = deviceIdField.val();
    deviceIdField.val("");

    /* Send note data to backend, storing in database with existing data
    associated with userIdToken */
    $.ajax(backendHostUrl + '/device/'+device_id+'/run', {
      headers: {
        'Authorization': 'Bearer ' + userIdToken
      },
      method: 'POST',
      data: JSON.stringify({
        'command': 'OPEN'
      }),
      contentType : 'application/json'
    }).then(function(){
      // Refresh notebook display.
      fetchDevices();
    });

  });

  configureFirebaseLogin();
  configureFirebaseLoginWidget();

});
