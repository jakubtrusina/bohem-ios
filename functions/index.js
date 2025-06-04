const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret, {
  apiVersion: '2023-10-16',
});

admin.initializeApp();

exports.createCheckoutSessionV1_fixed = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in to call this function.");
  }

  const uid = context.auth.uid;
  console.log("✅ Function called by UID:", uid);

  const items = data.items;
  if (!Array.isArray(items)) {
    throw new functions.https.HttpsError("invalid-argument", "Items must be an array.");
  }

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      mode: "payment",
      line_items: items.map(item => ({
        price_data: {
          currency: "czk",
          product_data: {
            name: `Product: ${item.productId}, Size: ${item.size}`
          },
          unit_amount: item.price * 100
        },
        quantity: item.quantity
      })),
      success_url: "https://bohem.store/success",
      cancel_url: "https://bohem.store/cancel"
    });

    console.log("✅ Stripe session created:", session.id);
    return { url: session.url };
  } catch (error) {
    console.error("❌ Stripe error:", error.message);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in to create a payment intent.");
  }

  console.log("📥 Incoming data:", data);

  const amount = data.amount;
  const shipping = data.shipping || {};
  const name = shipping.name;
  const phone = shipping.phone;
  const address = shipping.address || {};

  // ✅ Validate required fields
  if (!amount || typeof amount !== "number") {
    console.error("❌ Missing or invalid amount:", amount);
    throw new functions.https.HttpsError("invalid-argument", "Missing or invalid amount");
  }

  if (!name || !address.line1 || !address.city || !address.postal_code) {
    console.error("❌ Missing or incomplete shipping info");
    throw new functions.https.HttpsError("invalid-argument", "Missing or incomplete shipping address");
  }

  try {
    // ✅ 1. Create customer
    const customer = await stripe.customers.create({
      name,
      phone,
      address: {
        line1: address.line1,
        city: address.city,
        postal_code: address.postal_code,
        country: address.country || 'CZ',
        state: address.state || ''
      },
      metadata: {
        firebaseUID: context.auth.uid
      }
    });

    // ✅ 2. Create ephemeral key
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: '2023-10-16' } // Use your Stripe dashboard's API version
    );

    // ✅ 3. Create PaymentIntent with the customer
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: 'czk',
      customer: customer.id,
      automatic_payment_methods: { enabled: true },
      shipping: {
        name,
        phone,
        address: {
          line1: address.line1,
          city: address.city,
          postal_code: address.postal_code,
          country: address.country || 'CZ',
          state: address.state || ''
        }
      },
      metadata: {
        firebaseUID: context.auth.uid
      }
    });

    console.log("✅ PaymentIntent created:", paymentIntent.id);

    return {
      clientSecret: paymentIntent.client_secret,
      customer: customer.id,
      ephemeralKey: ephemeralKey.secret
    };
  } catch (error) {
    console.error("❌ Stripe error:", error.message);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
