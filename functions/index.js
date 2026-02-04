const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const crypto = require("crypto");
const {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

admin.initializeApp();

// ================= SECRETS =================
const PAYMOB_API_KEY = defineSecret("PAYMOB_API_KEY");
const PAYMOB_HMAC = defineSecret("PAYMOB_HMAC");
const PAYMOB_CARD_INTEGRATION_ID = defineSecret("PAYMOB_CARD_INTEGRATION_ID");
const PAYMOB_IFRAME_ID = defineSecret("PAYMOB_IFRAME_ID");

const R2_ACCESS_KEY_ID = defineSecret("R2_ACCESS_KEY_ID");
const R2_SECRET_ACCESS_KEY = defineSecret("R2_SECRET_ACCESS_KEY");
const R2_ENDPOINT = defineSecret("R2_ENDPOINT");
const R2_BUCKET = defineSecret("R2_BUCKET");
const R2_PUBLIC_BASE_URL = defineSecret("R2_PUBLIC_BASE_URL");

// ================= HELPERS =================

function requireAuth(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
}

async function getPaymobAuthToken(apiKey) {
  const res = await axios.post("https://accept.paymob.com/api/auth/tokens", {
    api_key: apiKey
  });
  return res.data.token;
}

async function createPaymobOrder(authToken, amountCents, currency, merchantOrderId, items) {
  try {
    const res = await axios.post("https://accept.paymob.com/api/ecommerce/orders", {
      auth_token: authToken,
      delivery_needed: false,
      amount_cents: amountCents.toString(),
      currency,
      merchant_order_id: merchantOrderId,
      items
    });

    return res.data.id;
  } catch (e) {
    console.error("🔥 PAYMOB ORDER ERROR:", e.response?.data);
    throw new HttpsError("internal", JSON.stringify(e.response?.data));
  }
}

async function getPaymentKey(authToken, orderId, amountCents, currency, integrationId, billingData) {
  try {
    const res = await axios.post("https://accept.paymob.com/api/acceptance/payment_keys", {
      auth_token: authToken,
      amount_cents: amountCents.toString(),
      expiration: 3600,
      order_id: orderId,
      billing_data: billingData,
      currency,
      integration_id: Number(integrationId)
    });

    return res.data.token;
  } catch (e) {
    console.error("🔥 PAYMOB KEY ERROR:", e.response?.data);
    throw new HttpsError("internal", JSON.stringify(e.response?.data));
  }
}

// ================= R2 =================

exports.deleteR2File = onCall(
  {
    region: "us-central1",
    secrets: [R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ENDPOINT, R2_BUCKET, R2_PUBLIC_BASE_URL],
  },
  async (request) => {
    requireAuth(request);

    const publicUrl = request.data?.publicUrl;
    if (!publicUrl) throw new HttpsError("invalid-argument", "publicUrl required");

    const bucket = R2_BUCKET.value();
    const baseUrl = R2_PUBLIC_BASE_URL.value();

    const key = publicUrl.substring(baseUrl.length + 1);

    const s3 = new S3Client({
      region: "auto",
      endpoint: R2_ENDPOINT.value(),
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID.value(),
        secretAccessKey: R2_SECRET_ACCESS_KEY.value(),
      },
    });

    await s3.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
    return { success: true };
  }
);

exports.getR2UploadUrl = onCall(
  {
    region: "us-central1",
    secrets: [R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ENDPOINT, R2_BUCKET, R2_PUBLIC_BASE_URL],
  },
  async (request) => {
    requireAuth(request);

    const { fileName, contentType, propertyId } = request.data;
    if (!fileName || !contentType) throw new HttpsError("invalid-argument", "fileName/contentType");

    const s3 = new S3Client({
      region: "auto",
      endpoint: R2_ENDPOINT.value(),
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID.value(),
        secretAccessKey: R2_SECRET_ACCESS_KEY.value(),
      }
    });

    const uuid = crypto.randomUUID();
    const folder = propertyId ? `properties/${propertyId}` : "properties";
    const key = `${folder}/${uuid}_${fileName}`;

    const cmd = new PutObjectCommand({
      Bucket: R2_BUCKET.value(),
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3, cmd, { expiresIn: 300 });
    const publicUrl = `${R2_PUBLIC_BASE_URL.value()}/${key}`;

    return { uploadUrl, publicUrl, key };
  }
);

// ================= CREATE DEPOSIT =================

exports.createDepositBooking = onCall(
  {
    region: "us-central1",
    secrets: [PAYMOB_API_KEY, PAYMOB_CARD_INTEGRATION_ID, PAYMOB_IFRAME_ID]
  },
  async (request) => {

    requireAuth(request);

    const { propertyId, userInfo } = request.data;
    if (!userInfo || !userInfo.email) {
      throw new HttpsError("invalid-argument", "Invalid user info");
    }

    const db = admin.firestore();
    const propSnap = await db.collection("properties").doc(propertyId).get();
    if (!propSnap.exists) throw new HttpsError("not-found", "Property not found");

    const data = propSnap.data();
    const finalPrice = (data.discountPrice && data.discountPrice > 0) ? data.discountPrice : data.price;
    const deposit = data.requiredDeposit || data.deposit || 0;

    const totalCommission = finalPrice / 2;
    const remainingAmount = totalCommission - deposit;

    if (!deposit || isNaN(deposit)) {
      throw new HttpsError("invalid-argument", "Invalid deposit value in property");
    }

    // Check for existing booking
    const existingBookings = await db.collection("bookings")
      .where("userId", "==", request.auth.uid)
      .where("propertyId", "==", propertyId)
      .get();

    let existingPendingBooking = null;
    for (const doc of existingBookings.docs) {
      const bData = doc.data();
      if (bData.status === "reserved" || bData.status === "completed") {
        throw new HttpsError("already-exists", "You already have an active or completed booking for this property.");
      }
      if (bData.status === "pending_deposit") {
        existingPendingBooking = doc;
      }
    }

    const bookingId = existingPendingBooking ? existingPendingBooking.id : db.collection("bookings").doc().id;
    const bookingRef = db.collection("bookings").doc(bookingId);
    const paymentRef = db.collection("payments").doc();
    const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000));

    // Use Transaction for Soft Lock & Sync
    await db.runTransaction(async (t) => {
      const propRef = db.collection("properties").doc(propertyId);
      const propSnap = await t.get(propRef);

      if (!propSnap.exists) {
        throw new HttpsError("not-found", "Property not found.");
      }

      const property = propSnap.data();
      // Property must be approved (available) to start a new payment process
      if (property.status !== "approved") {
        throw new HttpsError("failed-precondition", "Property is currently unavailable or already reserved by someone else.");
      }

      // Create or Update Booking (Upsert)
      t.set(bookingRef, {
        userId: request.auth.uid,
        propertyId,
        totalCommission,
        remainingAmount,
        depositPaid: 0,
        status: "pending_deposit",
        userInfo,
        expiresAt: expiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Create Payment
      t.set(paymentRef, {
        bookingId: bookingRef.id,
        type: "deposit",
        amount: deposit,
        status: "pending",
        userId: request.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    const amountCents = Math.round(deposit * 100);

    let phone = userInfo.phone || "01000000000";
    if (!phone.startsWith("+")) phone = "+2" + phone;

    const billingData = {
      apartment: "NA",
      email: userInfo.email,
      floor: "NA",
      first_name: userInfo.name?.split(" ")[0] || "Customer",
      street: "NA",
      building: "NA",
      phone_number: phone,
      shipping_method: "NA",
      postal_code: "NA",
      city: "NA",
      country: "EG",
      last_name: "User",
      state: "NA"
    };

    const authToken = await getPaymobAuthToken(PAYMOB_API_KEY.value());

    const items = [{
      name: "Booking Deposit",
      amount_cents: amountCents.toString(),
      description: "Property booking",
      quantity: 1
    }];

    const orderId = await createPaymobOrder(authToken, amountCents, "EGP", paymentRef.id, items);

    const paymentToken = await getPaymentKey(
      authToken,
      orderId,
      amountCents,
      "EGP",
      PAYMOB_CARD_INTEGRATION_ID.value(),
      billingData
    );

    return {
      bookingId: bookingRef.id,
      paymentId: paymentRef.id,
      paymentToken,
      iframeId: PAYMOB_IFRAME_ID.value()
    };

  });

// ================= WEBHOOK =================

exports.paymobWebhook = onRequest(
  { region: "us-central1", secrets: [PAYMOB_HMAC] },
  async (req, res) => {
    try {
      const data = req.body.obj || req.body;
      const hmacSecret = PAYMOB_HMAC.value();
      const receivedHmac = req.query.hmac || data.hmac;

      console.log("WEBHOOK HIT");

      if (!data || !receivedHmac) {
        console.error("Missing data or hmac");
        return res.status(400).send("No data");
      }

      const str =
        (data.amount_cents || "") +
        (data.created_at || "") +
        (data.currency || "") +
        (data.error_occured || "") +
        (data.has_parent_transaction || "") +
        (data.id || "") +
        (data.integration_id || "") +
        (data.is_3d_secure || "") +
        (data.is_auth || "") +
        (data.is_capture || "") +
        (data.is_refunded || "") +
        (data.is_standalone_payment || "") +
        (data.is_voided || "") +
        (data.order?.id || "") +
        (data.owner || "") +
        (data.pending || "") +
        (data.source_data?.pan || "") +
        (data.source_data?.sub_type || "") +
        (data.source_data?.type || "") +
        (data.success || "");

      const calculatedHmac = crypto
        .createHmac("sha512", hmacSecret)
        .update(str)
        .digest("hex");

      if (calculatedHmac !== receivedHmac) {
        console.error("🔥 HMAC FAILED");
        return res.status(401).send("Invalid HMAC");
      }

      const paymentId = data.order?.merchant_order_id;
      const success = data.success === true;

      if (!paymentId) return res.status(200).send("No ID");

      const db = admin.firestore();
      const paymentRef = db.collection("payments").doc(paymentId);

      await db.runTransaction(async (t) => {
        const paymentSnap = await t.get(paymentRef);
        if (!paymentSnap.exists) throw new Error("Payment not found");

        const payment = paymentSnap.data();
        if (payment.status === "paid") return;

        t.update(paymentRef, {
          status: success ? "paid" : "failed",
          externalId: data.id.toString(),
          paidAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (!success) return;

        const bookingRef = db.collection("bookings").doc(payment.bookingId);
        const bookingSnap = await t.get(bookingRef);
        if (!bookingSnap.exists) return;

        const booking = bookingSnap.data();
        const propRef = db.collection("properties").doc(booking.propertyId);

        if (payment.type === "deposit") {
          const exp = new Date();
          exp.setDate(exp.getDate() + 7);

          t.update(bookingRef, {
            status: "reserved",
            firstPaid: true,
            secondPaid: false,
            depositPaid: payment.amount,
            expiresAt: admin.firestore.Timestamp.fromDate(exp)
          });

          t.update(propRef, { status: "reserved" });

        } else if (payment.type === "remaining") {
          t.update(bookingRef, {
            status: "completed",
            secondPaid: true
          });

          t.update(propRef, { status: "sold" });
        }
      });

      return res.status(200).send("OK");

    } catch (e) {
      console.error("Webhook Error:", e);
      return res.status(500).send("Error");
    }
  }
);

// ================= REMAINING =================

exports.createRemainingPayment = onCall(
  {
    region: "us-central1",
    secrets: [PAYMOB_API_KEY, PAYMOB_CARD_INTEGRATION_ID, PAYMOB_IFRAME_ID]
  },
  async (request) => {
    requireAuth(request);

    const { bookingId } = request.data;
    const paymentRef = db.collection("payments").doc();
    const paymentId = paymentRef.id;

    await db.runTransaction(async (t) => {
      const snap = await t.get(db.collection("bookings").doc(bookingId));
      if (!snap.exists) throw new HttpsError("not-found", "Booking not found");

      const booking = snap.data();

      // Permissions & Validations
      if (booking.userId !== request.auth.uid) throw new HttpsError("permission-denied", "Not yours");
      if (booking.status !== "reserved") {
        throw new HttpsError("failed-precondition", "Booking is not in a payable state (must be reserved).");
      }
      if (booking.expiresAt && booking.expiresAt.toMillis() < Date.now()) {
        throw new HttpsError("failed-precondition", "Booking has expired.");
      }

      // Soft Lock: Set status to 'paying_remaining' to prevent double payment attempts
      t.update(snap.ref, { status: "paying_remaining" });

      // Create Payment
      t.set(paymentRef, {
        bookingId,
        type: "remaining",
        amount: booking.remainingAmount,
        status: "pending",
        userId: request.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    const amountCents = Math.round(booking.remainingAmount * 100);

    let phone = booking.userInfo?.phone || "01000000000";
    if (!phone.startsWith("+")) phone = "+2" + phone;

    const billingData = {
      apartment: "NA",
      email: booking.userInfo?.email || "customer@example.com",
      floor: "NA",
      first_name: booking.userInfo?.name?.split(" ")[0] || "Customer",
      street: "NA",
      building: "NA",
      phone_number: phone,
      shipping_method: "NA",
      postal_code: "NA",
      city: "NA",
      country: "EG",
      last_name: "User",
      state: "NA"
    };

    const authToken = await getPaymobAuthToken(PAYMOB_API_KEY.value());

    const items = [{
      name: "Remaining Payment",
      amount_cents: amountCents.toString(),
      description: `Remaining ${bookingId}`,
      quantity: 1
    }];

    const orderId = await createPaymobOrder(authToken, amountCents, "EGP", paymentId, items);
    const paymentToken = await getPaymentKey(authToken, orderId, amountCents, "EGP", PAYMOB_CARD_INTEGRATION_ID.value(), billingData);

    return {
      paymentId,
      amount: booking.remainingAmount,
      paymentToken,
      iframeId: PAYMOB_IFRAME_ID.value()
    };

  });

// ================= ADMIN =================

exports.makeUserAdmin = onCall({ region: "us-central1" }, async () => {
  throw new HttpsError("unimplemented", "Disabled");
});

// ================= EXPIRE =================

exports.expireBookings = onSchedule(
  { schedule: "every 1 hours", timeZone: "Africa/Cairo" },
  async () => {
    const db = admin.firestore();
    const snap = await db.collection("bookings")
      .where("status", "==", "reserved")
      .where("expiresAt", "<", admin.firestore.Timestamp.now())
      .get();

    const batch = db.batch();
    snap.docs.forEach(d => batch.update(d.ref, { status: "expired" }));
    await batch.commit();
  });



