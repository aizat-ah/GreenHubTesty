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
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

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

// -----------------------------------------------------------------------
// Shared transaction helpers
//
// Both the Stripe path (confirmOrderPayment) and the Cash-on-Delivery
// path (confirmCodOrder) need to do the exact same "check every item has
// enough stock, then decrement all of them" work — so it lives here once
// instead of being copy-pasted into both functions. Same for the restock
// step shared by cancelOrder and cancelPlacedOrder.
//
// Why a transaction: two buyers could check out the same low-stock
// product at nearly the same instant. A transaction re-reads every
// product's stock at the moment it commits (not from whatever the app
// read earlier) and Firestore automatically retries it if another
// transaction changed the same documents first. That guarantees we never
// sell more units than are actually in stock, and that a multi-item
// order either fully succeeds or fully fails (no partial decrements).
// -----------------------------------------------------------------------

// Checks + decrements stock for every item in `items`, inside transaction
// `tx`. Throws `failed-precondition` (aborting the whole transaction,
// writing nothing) if ANY item doesn't have enough stock.
async function checkAndDecrementStock(tx, items) {
  const productRefs = items.map((item) =>
    db.collection("products").doc(item.productId)
  );
  const productSnaps = await Promise.all(productRefs.map((ref) => tx.get(ref)));

  // 1. Check ALL items before writing ANY of them.
  for (let i = 0; i < items.length; i++) {
    const snap = productSnaps[i];
    const item = items[i];
    if (!snap.exists) {
      throw new HttpsError(
        "failed-precondition",
        `${item.productName} is no longer available.`
      );
    }
    const currentStock = snap.data().stock || 0;
    if (currentStock < item.quantity) {
      throw new HttpsError(
        "failed-precondition",
        `${item.productName} is no longer available in that quantity.`
      );
    }
  }

  // 2. Stock is sufficient for every item — perform all the decrements.
  //    Firestore only commits a transaction if none of the documents it
  //    read were changed by someone else in the meantime, so this whole
  //    batch of writes is atomic: either every write lands, or none does.
  for (let i = 0; i < items.length; i++) {
    const snap = productSnaps[i];
    const item = items[i];
    const newStock = (snap.data().stock || 0) - item.quantity;

    tx.update(productRefs[i], {
      stock: newStock,
      // Flip the "Out" badge on once stock hits zero.
      isAvailable: newStock > 0,
    });
  }
}

// Reverses checkAndDecrementStock: adds each item's quantity back to its
// product's stock, inside transaction `tx`.
async function restockItems(tx, items) {
  const productRefs = items.map((item) =>
    db.collection("products").doc(item.productId)
  );
  const productSnaps = await Promise.all(productRefs.map((ref) => tx.get(ref)));

  for (let i = 0; i < items.length; i++) {
    const snap = productSnaps[i];
    if (!snap.exists) continue; // product deleted since — skip it.
    const item = items[i];
    const newStock = (snap.data().stock || 0) + item.quantity;

    tx.update(productRefs[i], {
      stock: newStock,
      // Flip "Out" back off now that stock is available again.
      isAvailable: newStock > 0 ? true : snap.data().isAvailable,
    });
  }
}

// True if `uid` is a supplier or admin, per the `role` field on their
// `users` doc — mirrors `hasSupplierAccess()` in firestore.rules.
async function hasSupplierAccess(uid) {
  const userSnap = await db.collection("users").doc(uid).get();
  const role = userSnap.exists ? userSnap.data().role : null;
  return role === "supplier" || role === "admin";
}

// -----------------------------------------------------------------------
// confirmOrderPayment
//
// Called by the Flutter app right after Stripe's Payment Sheet reports
// success. This is one of two places (the other is confirmCodOrder) that
// is allowed to decrement product stock — both run with the Admin SDK,
// so they can write to `products` even though the Firestore security
// rules forbid buyers from writing to that collection directly.
// -----------------------------------------------------------------------
exports.confirmOrderPayment = onCall(
  { maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const { orderId } = request.data;
    if (!orderId || typeof orderId !== "string") {
      throw new HttpsError("invalid-argument", "`orderId` is required.");
    }

    const orderRef = db.collection("orders").doc(orderId);

    await db.runTransaction(async (tx) => {
      const orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) {
        throw new HttpsError("not-found", "Order not found.");
      }
      const order = orderSnap.data();

      // Only the buyer who placed the order may confirm its payment.
      if (order.customerId !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "You are not the owner of this order."
        );
      }
      if (order.isPaid) {
        // Already confirmed (e.g. retried call) — nothing further to do.
        return;
      }

      await checkAndDecrementStock(tx, order.items || []);

      tx.update(orderRef, {
        isPaid: true,
        status: "confirmed",
        // Marks that stock has been taken for this order, so cancellation
        // knows whether it needs to restock. Kept separate from `isPaid`
        // because COD orders decrement stock but are never "paid" until
        // cash changes hands on delivery.
        stockDecremented: true,
      });
    });

    return { success: true };
  }
);

// -----------------------------------------------------------------------
// confirmCodOrder
//
// Cash-on-Delivery has no separate "payment succeeded" webhook/callback
// the way Stripe does — the closest equivalent moment is order placement
// itself. So the Flutter app calls this immediately after creating a COD
// order (see order_provider.dart), and it does exactly what
// confirmOrderPayment does for Stripe: check + decrement stock for every
// item in one transaction, then mark the order confirmed. `isPaid` stays
// false — COD is only actually paid when cash is collected on delivery.
// -----------------------------------------------------------------------
exports.confirmCodOrder = onCall(
  { maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const { orderId } = request.data;
    if (!orderId || typeof orderId !== "string") {
      throw new HttpsError("invalid-argument", "`orderId` is required.");
    }

    const orderRef = db.collection("orders").doc(orderId);

    await db.runTransaction(async (tx) => {
      const orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) {
        throw new HttpsError("not-found", "Order not found.");
      }
      const order = orderSnap.data();

      if (order.customerId !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "You are not the owner of this order."
        );
      }
      if (order.paymentMethod !== "cashOnDelivery") {
        throw new HttpsError(
          "failed-precondition",
          "This order is not a Cash on Delivery order."
        );
      }
      if (order.stockDecremented) {
        // Already confirmed (e.g. retried call) — nothing further to do.
        return;
      }

      await checkAndDecrementStock(tx, order.items || []);

      tx.update(orderRef, {
        status: "confirmed",
        stockDecremented: true,
      });
    });

    return { success: true };
  }
);

// -----------------------------------------------------------------------
// cancelOrder
//
// For PRE-CONFIRMATION cleanup only: when a Stripe payment fails/is
// cancelled before confirmOrderPayment ever ran, the pending order doc
// that was created just to hold a place for the payment attempt is
// deleted outright (stock was never touched, so there's nothing to
// restock). This is called from order_provider.dart's catch block.
//
// This is intentionally NOT used for cancelling a real, already-confirmed
// order — see cancelPlacedOrder below for that.
// -----------------------------------------------------------------------
exports.cancelOrder = onCall(
  { maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const { orderId } = request.data;
    if (!orderId || typeof orderId !== "string") {
      throw new HttpsError("invalid-argument", "`orderId` is required.");
    }

    const orderRef = db.collection("orders").doc(orderId);

    await db.runTransaction(async (tx) => {
      const orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) return; // already gone — nothing to do.
      const order = orderSnap.data();

      if (order.customerId !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "You are not the owner of this order."
        );
      }

      // Only restock if stock was actually decremented for this order.
      if (order.stockDecremented) {
        await restockItems(tx, order.items || []);
      }

      tx.delete(orderRef);
    });

    return { success: true };
  }
);

// -----------------------------------------------------------------------
// cancelPlacedOrder
//
// The real "Cancel Order" action for an order that's already been placed
// (pending or confirmed, COD or Stripe) — used by both the buyer-facing
// Cancel button (my_orders_screen.dart) and the supplier's cancel action
// (supplier_orders_screen.dart). Unlike cancelOrder, this KEEPS the order
// document and simply flips its status to "cancelled", so it still shows
// up in order history. If stock was decremented for it, that stock is
// restored in the same transaction.
// -----------------------------------------------------------------------
exports.cancelPlacedOrder = onCall(
  { maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const { orderId } = request.data;
    if (!orderId || typeof orderId !== "string") {
      throw new HttpsError("invalid-argument", "`orderId` is required.");
    }

    const orderRef = db.collection("orders").doc(orderId);
    const uid = request.auth.uid;

    await db.runTransaction(async (tx) => {
      const orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) {
        throw new HttpsError("not-found", "Order not found.");
      }
      const order = orderSnap.data();

      // The buyer who placed the order, or a supplier/admin, may cancel it.
      const isOwner = order.customerId === uid;
      const isSupplier = !isOwner && (await hasSupplierAccess(uid));
      if (!isOwner && !isSupplier) {
        throw new HttpsError(
          "permission-denied",
          "You are not allowed to cancel this order."
        );
      }

      // Only pending/confirmed orders can be cancelled — once completed
      // there's nothing to undo, and cancelling twice would double-restock.
      if (order.status !== "pending" && order.status !== "confirmed") {
        throw new HttpsError(
          "failed-precondition",
          `This order is already ${order.status} and can't be cancelled.`
        );
      }

      if (order.stockDecremented) {
        await restockItems(tx, order.items || []);
      }

      tx.update(orderRef, { status: "cancelled" });
    });

    return { success: true };
  }
);