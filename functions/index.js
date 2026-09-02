const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Loads the acting user's profile, finds their accepted friends who are
 * allowed (per privacy settings) to see this activity type, writes a
 * notification doc for each, and pushes to their registered devices.
 *
 * @param {string} actorUid Uid of the user whose activity fired the trigger.
 * @param {"shareWeight"|"shareMeals"|"shareWorkouts"} privacyField Which
 *   privacy flag on the actor's profile gates this activity type.
 * @param {(actorName: string) => string} messageFor Builds the notification
 *   body from the actor's display name.
 */
async function notifyFriendsOfActivity(actorUid, privacyField, messageFor) {
  const actorSnap = await db.collection("users").doc(actorUid).get();
  if (!actorSnap.exists) return;
  const actor = actorSnap.data();

  // Matches firestore.rules' isAcceptedFriend() gate for the same
  // subcollection — a friend only gets notified about what they're also
  // allowed to read.
  if (actor.privacy && actor.privacy[privacyField] === false) return;

  const actorName = actor.displayName || "A friend";
  const message = messageFor(actorName);
  const route = "/social";

  const friendships = await db
      .collection("friendships")
      .where("uids", "array-contains", actorUid)
      .where("status", "==", "accepted")
      .get();
  if (friendships.empty) {
    logger.info(`notifyFriendsOfActivity: ${actorUid} has no accepted friends, skipping`);
    return;
  }

  const friendUids = friendships.docs.map(
      (doc) => doc.data().uids.find((uid) => uid !== actorUid),
  ).filter(Boolean);

  const batch = db.batch();
  for (const friendUid of friendUids) {
    const notifRef = db
        .collection("users")
        .doc(friendUid)
        .collection("notifications")
        .doc();
    batch.set(notifRef, {
      type: "friend_activity",
      actorUid,
      actorName,
      actorPhotoUrl: actor.photoUrl || null,
      message,
      route,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  const tokenSnaps = await Promise.all(
      friendUids.map((friendUid) =>
        db
            .collection("users")
            .doc(friendUid)
            .collection("fcmTokens")
            .get(),
      ),
  );
  const tokens = tokenSnaps.flatMap((snap) => snap.docs.map((d) => d.id));
  logger.info(
      `notifyFriendsOfActivity: ${actorUid} -> ${friendUids.length} friend(s), ${tokens.length} device token(s): "${message}"`,
  );
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {title: "Fitness Buddy", body: message},
    data: {route},
  });
  logger.info(
      `notifyFriendsOfActivity: sent ${response.successCount}/${tokens.length} pushes successfully`,
  );

  // Prune tokens the device has since invalidated (uninstalled app, etc.)
  // so the collection doesn't grow stale forever.
  const staleTokens = [];
  response.responses.forEach((result, i) => {
    const code = result.error && result.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      staleTokens.push(tokens[i]);
    }
  });
  if (staleTokens.length > 0) {
    await Promise.all(
        friendUids.map(async (friendUid) => {
          const col = db
              .collection("users")
              .doc(friendUid)
              .collection("fcmTokens");
          await Promise.all(
              staleTokens.map((token) =>
                col
                    .doc(token)
                    .delete()
                    .catch(() => {}),
              ),
          );
        }),
    );
  }
}

exports.onWeightLogged = onDocumentCreated(
    "users/{uid}/weightLogs/{logId}",
    async (event) => {
      const {uid} = event.params;
      try {
        await notifyFriendsOfActivity(
            uid,
            "shareWeight",
            (name) => `${name} logged a new weight check-in 📉`,
        );
      } catch (err) {
        logger.error("onWeightLogged notify failed", err);
      }
    },
);

exports.onMealLogged = onDocumentCreated(
    "users/{uid}/meals/{mealId}",
    async (event) => {
      const {uid} = event.params;
      try {
        await notifyFriendsOfActivity(
            uid,
            "shareMeals",
            (name) => `${name} logged a meal 🍽️`,
        );
      } catch (err) {
        logger.error("onMealLogged notify failed", err);
      }
    },
);

exports.onWorkoutLogged = onDocumentCreated(
    "users/{uid}/workouts/{workoutId}",
    async (event) => {
      const {uid} = event.params;
      try {
        await notifyFriendsOfActivity(
            uid,
            "shareWorkouts",
            (name) => `${name} just logged a workout 💪`,
        );
      } catch (err) {
        logger.error("onWorkoutLogged notify failed", err);
      }
    },
);

/**
 * Local hour (0-23) in `timeZone` at instant `date`, or null if `timeZone`
 * isn't a valid IANA name.
 *
 * @param {Date} date Instant to evaluate.
 * @param {string} timeZone IANA timezone name, e.g. "Asia/Kolkata".
 * @return {?number} Local hour, or null on an invalid timezone.
 */
function getLocalHour(date, timeZone) {
  try {
    const dtf = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour: "2-digit",
      hourCycle: "h23",
    });
    return parseInt(dtf.format(date), 10);
  } catch (err) {
    return null;
  }
}

/**
 * Offset of `timeZone` from UTC, in minutes, at instant `date` — computed by
 * formatting `date` in that zone and comparing to its UTC representation, so
 * DST is handled correctly for whichever moment `date` falls on.
 *
 * @param {Date} date Instant to evaluate the offset at.
 * @param {string} timeZone IANA timezone name.
 * @return {number} Offset in minutes (positive = ahead of UTC).
 */
function getTimezoneOffsetMinutes(date, timeZone) {
  const dtf = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
  const parts = {};
  for (const p of dtf.formatToParts(date)) parts[p.type] = p.value;
  const asUtc = Date.UTC(
      Number(parts.year), Number(parts.month) - 1, Number(parts.day),
      Number(parts.hour), Number(parts.minute), Number(parts.second),
  );
  return (asUtc - date.getTime()) / 60000;
}

/**
 * The UTC instants bounding "today" as of `date`, in `timeZone`'s wall-clock
 * calendar — used to query a user's local day of weightLogs/meals without
 * pulling in a date-math dependency.
 *
 * @param {Date} date Instant to evaluate "today" relative to.
 * @param {string} timeZone IANA timezone name.
 * @return {{startUtc: Date, endUtc: Date, dateKey: string}} Local-day bounds
 *   and a "YYYY-MM-DD" key for that local day.
 */
function localDayBoundsUtc(date, timeZone) {
  const offsetMin = getTimezoneOffsetMinutes(date, timeZone);
  const localNow = new Date(date.getTime() + offsetMin * 60000);
  const y = localNow.getUTCFullYear();
  const m = localNow.getUTCMonth();
  const d = localNow.getUTCDate();
  const localMidnightWall = Date.UTC(y, m, d, 0, 0, 0);
  const startUtc = new Date(localMidnightWall - offsetMin * 60000);
  const endUtc = new Date(startUtc.getTime() + 24 * 60 * 60 * 1000);
  const dateKey =
    `${y}-${String(m + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
  return {startUtc, endUtc, dateKey};
}

/**
 * Physically deletes every expired story doc across all users — the client
 * already hides them via `expiresAt` filters, this just reclaims storage.
 *
 * @param {Date} now Current instant.
 * @return {Promise<number>} Count of deleted docs.
 */
async function deleteExpiredStories(now) {
  const expired = await db.collectionGroup("stories")
      .where("expiresAt", "<=", Timestamp.fromDate(now))
      .get();
  if (expired.empty) return 0;

  for (let i = 0; i < expired.docs.length; i += 500) {
    const batch = db.batch();
    for (const doc of expired.docs.slice(i, i + 500)) batch.delete(doc.ref);
    await batch.commit();
  }
  return expired.docs.length;
}

/**
 * For every user whose local clock just hit 23:00 (hourly granularity, so
 * "just hit" means "currently reads 23:xx"), posts a dailySummary story
 * covering their local day — but only if they logged a weight and/or a meal
 * that day, and only once per local day (idempotent on `summaryDateKey`).
 *
 * @param {Date} now Current instant.
 * @return {Promise<number>} Count of summaries posted this run.
 */
async function postDailySummaries(now) {
  const usersSnap = await db.collection("users").get();
  let posted = 0;

  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data();
    const tz = user.timezone;
    if (!tz) continue;
    if (getLocalHour(now, tz) !== 23) continue;

    const uid = userDoc.id;
    const {startUtc, endUtc, dateKey} = localDayBoundsUtc(now, tz);
    const storiesCol = db.collection("users").doc(uid).collection("stories");

    const alreadyPosted = await storiesCol
        .where("type", "==", "dailySummary")
        .where("summaryDateKey", "==", dateKey)
        .limit(1)
        .get();
    if (!alreadyPosted.empty) continue;

    const [weightSnap, mealsSnap] = await Promise.all([
      db.collection("users").doc(uid).collection("weightLogs")
          .where("date", ">=", Timestamp.fromDate(startUtc))
          .where("date", "<", Timestamp.fromDate(endUtc))
          .orderBy("date", "desc")
          .limit(1)
          .get(),
      db.collection("users").doc(uid).collection("meals")
          .where("date", ">=", Timestamp.fromDate(startUtc))
          .where("date", "<", Timestamp.fromDate(endUtc))
          .get(),
    ]);

    // Nothing logged that day — skip entirely, per spec.
    if (weightSnap.empty && mealsSnap.empty) continue;

    let caloriesTotal = 0;
    for (const doc of mealsSnap.docs) caloriesTotal += doc.data().calories || 0;

    const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    await storiesCol.add({
      type: "dailySummary",
      photoUrl: null,
      createdAt: Timestamp.fromDate(now),
      expiresAt: Timestamp.fromDate(expiresAt),
      weightKg: null,
      mealName: null,
      mealTypeLabel: null,
      calories: null,
      proteinG: null,
      carbG: null,
      fatG: null,
      displayName: user.displayName || null,
      streakCount: user.streakCount || 0,
      summaryWeightKg:
        weightSnap.empty ? null : weightSnap.docs[0].data().weightKg,
      summaryMealsCount: mealsSnap.size,
      summaryCaloriesTotal: mealsSnap.empty ? null : caloriesTotal,
      summaryDateKey: dateKey,
    });
    posted++;
  }

  return posted;
}

// Requires the Blaze billing plan (Cloud Scheduler isn't available on Spark).
// Runs every hour to (1) delete expired stories and (2) post each user's
// dailySummary story once their local clock reads 23:xx.
exports.hourlyStoryMaintenance = onSchedule("every 60 minutes", async () => {
  const now = new Date();
  const deletedCount = await deleteExpiredStories(now);
  const postedCount = await postDailySummaries(now);
  logger.info(
      `hourlyStoryMaintenance: deleted ${deletedCount} expired stories, ` +
      `posted ${postedCount} daily summaries`,
  );
});
