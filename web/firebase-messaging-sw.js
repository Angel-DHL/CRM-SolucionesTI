importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD-x-xxxxxxx", // Solo dummy, se inyecta desde web
  projectId: "crm-solucionesti",
  messagingSenderId: "221686128201",
  appId: "1:221686128201:web:ec5e1c1040d8263a7f6998"
});

const messaging = firebase.messaging();
