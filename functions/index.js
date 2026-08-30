const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
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
