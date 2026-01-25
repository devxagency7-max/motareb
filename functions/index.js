const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");

const {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} = require("@aws-sdk/client-s3");

const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

// ✅ secrets اللي انت خزنتهم
const R2_ACCESS_KEY_ID = defineSecret("R2_ACCESS_KEY_ID");
const R2_SECRET_ACCESS_KEY = defineSecret("R2_SECRET_ACCESS_KEY");
const R2_ENDPOINT = defineSecret("R2_ENDPOINT");
const R2_BUCKET = defineSecret("R2_BUCKET");
const R2_PUBLIC_BASE_URL = defineSecret("R2_PUBLIC_BASE_URL");

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }
}

// لو انت لسه معملتش admin claims.. خليه auth فقط مؤقتًا
function requireAdmin(request) {
  const isAdmin = request.auth?.token?.admin === true;
  if (!isAdmin) {
    throw new HttpsError("permission-denied", "Admin only.");
  }
}

// ... (existing code) ...

exports.deleteR2File = onCall(
  {
    region: "us-central1",
    secrets: [
      R2_ACCESS_KEY_ID,
      R2_SECRET_ACCESS_KEY,
      R2_ENDPOINT,
      R2_BUCKET,
      R2_PUBLIC_BASE_URL,
    ],
  },
  async (request) => {
    requireAuth(request);
    // requireAdmin(request); // ⚠️ Temporarily disabled for testing

    const publicUrl = request.data?.publicUrl;

    if (!publicUrl) {
      throw new HttpsError("invalid-argument", "publicUrl is required.");
    }

    const bucket = R2_BUCKET.value();
    const baseUrl = R2_PUBLIC_BASE_URL.value();

    if (!publicUrl.startsWith(baseUrl)) {
      throw new HttpsError(
        "invalid-argument",
        "URL does not belong to this bucket."
      );
    }

    // Extract Key: "https://.../key" -> "key"
    // baseUrl usually does not have trailing slash, so we take length + 1
    const key = publicUrl.substring(baseUrl.length + 1);

    const s3 = new S3Client({
      region: "auto",
      endpoint: R2_ENDPOINT.value(),
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID.value(),
        secretAccessKey: R2_SECRET_ACCESS_KEY.value(),
      },
    });

    const command = new DeleteObjectCommand({
      Bucket: bucket,
      Key: key,
    });

    await s3.send(command);

    return { success: true };
  }
);

exports.getR2UploadUrl = onCall(
  {
    region: "us-central1",
    secrets: [
      R2_ACCESS_KEY_ID,
      R2_SECRET_ACCESS_KEY,
      R2_ENDPOINT,
      R2_BUCKET,
      R2_PUBLIC_BASE_URL,
    ],
  },
  async (request) => {
    requireAuth(request);
    // requireAdmin(request); // ⚠️ Temporarily disabled for testing // ✅ Admin only

    const fileName = request.data?.fileName;
    const contentType = request.data?.contentType;
    const propertyId = request.data?.propertyId; // Optional: good for organization

    if (!fileName || !contentType) {
      throw new HttpsError(
        "invalid-argument",
        "fileName and contentType are required."
      );
    }

    const bucket = R2_BUCKET.value();

    const s3 = new S3Client({
      region: "auto",
      endpoint: R2_ENDPOINT.value(),
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID.value(),
        secretAccessKey: R2_SECRET_ACCESS_KEY.value(),
      },
    });

    const uuid = crypto.randomUUID();

    // Organize by propertyId if available, otherwise just use a properties folder
    const folder = propertyId ? `properties/${propertyId}` : "properties";
    const key = `${folder}/${uuid}_${fileName}`;

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: contentType,
    });

    // 5 minutes expiration
    const uploadUrl = await getSignedUrl(s3, command, {
      expiresIn: 60 * 5,
    });

    const publicUrl = `${R2_PUBLIC_BASE_URL.value()}/${key}`;

    return { uploadUrl, publicUrl, key };
  }
);



const admin = require("firebase-admin");
admin.initializeApp();

exports.makeUserAdmin = onCall(
  { region: "us-central1" },
  async (request) => {
    // لازم الشخص اللي بيشغلها يكون Admin أصلاً
    requireAuth(request);
    requireAdmin(request);

    const uid = request.data?.uid;
    if (!uid) {
      throw new HttpsError("invalid-argument", "uid is required.");
    }

    await admin.auth().setCustomUserClaims(uid, { admin: true });

    return { success: true, uid };
  }
);
