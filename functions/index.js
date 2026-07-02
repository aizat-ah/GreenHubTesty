// functions/index.js
//
// GreenHub — Stripe PaymentIntent creation.
//
// This is a "callable" Cloud Function: your Flutter app calls it directly
// via the Firebase SDK (no need to manage your own HTTP endpoint/CORS).
// It runs server-side, uses the secret key (safe here, never in the app),
// and returns a `client_secret` that the Flutter app uses to show Stripe's
// built-in Payment Sheet.
//
// Deploy with:
//   firebase deploy --only functions

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

exports.createPaymentIntent = onCall(
  { secrets: [STRIPE_SECRET_KEY] , maxInstances: 10 },
  async (request) => {
    // 1. Require the caller to be logged in (basic abuse prevention).
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to make a payment."
      );
    }

    const stripe = require("stripe")(STRIPE_SECRET_KEY.value());

    // 2. Validate the input the app sends.
    const { amount, orderId } = request.data;

    if (typeof amount !== "number" || amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "A valid positive `amount` (in sen/cents) is required."
      );
    }
    if (!orderId || typeof orderId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "`orderId` is required so we can trace this payment to an order."
      );
    }

    try {
      // 3. Create the PaymentIntent.
      //    NOTE: `amount` must be in the smallest currency unit —
      //    for MYR that's sen, so RM 25.50 => amount: 2550.
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount),
        currency: "myr",
        metadata: {
          orderId,
          buyerUid: request.auth.uid,
        },
        automatic_payment_methods: { enabled: true },
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (err) {
      logger.error("Stripe PaymentIntent creation failed", err);
      throw new HttpsError("internal", "Could not start payment. Please try again.");
    }
  }
);