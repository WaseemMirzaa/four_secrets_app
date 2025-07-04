const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        
        try {
            const message = {
                token: notification.token,
                notification: {
                    title: notification.title,
                    body: notification.body,
                },
                data: notification.data || {},
                android: {
                    notification: {
                        channelId: 'collaboration_channel',
                        priority: 'high',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            const response = await admin.messaging().send(message);
            console.log('Successfully sent notification:', response);
            
            // Delete the notification document after sending
            // await snap.ref.delete();
            
            return null;
        } catch (error) {
            console.error('Error sending notification:', error);
            throw error;
        }
    }); 