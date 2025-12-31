importScripts('https://www.gstatic.com/firebasejs/10.3.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.3.1/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyAki4mV6tpqScdhrpQDBpHOv01bNViUnUQ",
  authDomain: "foodapp-d2100.firebaseapp.com",
  projectId: "foodapp-d2100",
  storageBucket: "foodapp-d2100.firebasestorage.app",
  messagingSenderId: "880964926822",
  appId: "1:880964926822:web:ec89d2911df801e1569ca7",
  measurementId: "G-WJK8GHCFQN"
};
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});