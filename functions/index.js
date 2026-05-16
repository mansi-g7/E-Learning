const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

admin.initializeApp();

// Read SendGrid API key and from address from functions config
const SENDGRID_KEY = functions.config().sendgrid?.key;
const FROM_EMAIL = functions.config().sendgrid?.from || 'support@e-learning.com';

if (SENDGRID_KEY) {
  sgMail.setApiKey(SENDGRID_KEY);
} else {
  console.warn('SendGrid key not set in functions config. Emails will not be sent.');
}

// Triggered when an admin response is added to a message
exports.sendAdminResponseEmail = functions.firestore
  .document('contact_us_messages/{messageId}/responses/{responseId}')
  .onCreate(async (snap, context) => {
    const response = snap.data();
    if (!response) return null;

    const messageId = context.params.messageId;

    try {
      const messageDoc = await admin.firestore().collection('contact_us_messages').doc(messageId).get();
      if (!messageDoc.exists) {
        console.log('Parent message not found:', messageId);
        return null;
      }

      const messageData = messageDoc.data();
      const userEmail = messageData.email;
      const userName = messageData.userName || 'User';
      const originalSubject = messageData.subject || 'Support';
      const adminResponse = response.response || '';

      // If SendGrid is not configured, just log and return
      if (!SENDGRID_KEY) {
        console.log('SendGrid not configured. Skipping email to', userEmail);
        return null;
      }

      const mail = {
        to: userEmail,
        from: FROM_EMAIL,
        subject: `[E-Learning] Response to: ${originalSubject}`,
        text: `Hello ${userName},\n\n${adminResponse}\n\nRegards,\nE-Learning Support`,
        html: `<p>Hello ${userName},</p><p>${adminResponse}</p><p>Regards,<br/>E-Learning Support</p>`,
      };

      await sgMail.send(mail);
      console.log('Email sent to', userEmail);
    } catch (err) {
      console.error('Error sending admin response email:', err);
    }

    return null;
  });
