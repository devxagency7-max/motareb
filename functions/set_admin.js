const admin = require('firebase-admin');

// 1. Download service account key from:
//    Firebase Console -> Project Settings -> Service Accounts -> Generate New Private Key
//    Save it as "service-account.json" in this directory.

const serviceAccount = require('./service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const setAdmin = async (uid) => {
    try {
        await admin.auth().setCustomUserClaims(uid, { admin: true });
        console.log(`Successfully set admin claim for user: ${uid}`);
        process.exit(0);
    } catch (error) {
        console.error('Error setting admin claim:', error);
        process.exit(1);
    }
};

// Replace with the actual UID of the user you want to make admin
// You can find the UID in the Authentication tab of Firebase Console.
const TARGET_UID = 'YOUR_USER_UID_HERE';

if (TARGET_UID === 'YOUR_USER_UID_HERE') {
    console.error('Please edit the script to set the correct TARGET_UID.');
} else {
    setAdmin(TARGET_UID);
}
