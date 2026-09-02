importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAG-FBmhWF8rsC_hY1fxIbPR2PCsJKcXlw',
  appId: '1:670792864283:web:42fc135b29332a33671ebe',
  messagingSenderId: '670792864283',
  projectId: 'tablebid-4e1f4',
  authDomain: 'tablebid-4e1f4.firebaseapp.com',
  storageBucket: 'tablebid-4e1f4.firebasestorage.app',
  measurementId: 'G-039MXZT6GL',
});

firebase.messaging();
