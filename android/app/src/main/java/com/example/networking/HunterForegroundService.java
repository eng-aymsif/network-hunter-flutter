package com.example.networking;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.PowerManager;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import io.flutter.FlutterInjector;

public class HunterForegroundService extends Service {
    public static final String CHANNEL_LIVE_ID = "hunter_live_status_channel";
    public static final String CHANNEL_ALERT_ID = "hunter_custom_sound_alerts_v3";
    public static final int LIVE_NOTIFICATION_ID = 1001;

    private static MediaPlayer activeMediaPlayer;

    public static final String ACTION_START = "ACTION_START";
    public static final String ACTION_UPDATE = "ACTION_UPDATE";
    public static final String ACTION_STOP = "ACTION_STOP";

    private PowerManager.WakeLock wakeLock;
    private WifiManager.WifiLock wifiLock;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannels(this);
        acquireLocks();

        // Android 14: استدعاء startForeground فوراً في onCreate لمنع انتهاء مهلة الـ 5 ثوانٍ
        try {
            Notification initNotif = buildLiveNotification(
                this,
                "Network Hunter • قيد الفحص والاصطياد 🚀",
                "جاري فحص واصطياد كروت الشبكة...",
                null
            );
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    LIVE_NOTIFICATION_ID,
                    initNotif,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                );
            } else {
                startForeground(LIVE_NOTIFICATION_ID, initNotif);
            }
        } catch (Exception e) {
            android.util.Log.e("HunterFGS", "Error calling startForeground in onCreate: " + e.getMessage());
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : ACTION_START;
        if (ACTION_STOP.equals(action)) {
            releaseLocks();
            stopForeground(true);
            stopSelf();
            return START_NOT_STICKY;
        }

        String title = intent != null ? intent.getStringExtra("title") : null;
        String body = intent != null ? intent.getStringExtra("body") : null;
        String subText = intent != null ? intent.getStringExtra("subText") : null;

        if (title == null) title = "Network Hunter • قيد الفحص والاصطياد 🚀";
        if (body == null) body = "جاري فحص واصطياد كروت الشبكة...";

        Notification notification = buildLiveNotification(this, title, body, subText);

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    LIVE_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                );
            } else {
                startForeground(LIVE_NOTIFICATION_ID, notification);
            }
        } catch (Exception e) {
            android.util.Log.e("HunterFGS", "Error in startForeground: " + e.getMessage());
            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                nm.notify(LIVE_NOTIFICATION_ID, notification);
            }
        }

        return START_STICKY;
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        // الحفاظ على استمرار الخدمة في العمل في الخلفية عند إغلاق التطبيق من قائمة التطبيقات النشطة
        super.onTaskRemoved(rootIntent);
    }

    private void acquireLocks() {
        try {
            PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
            if (pm != null && (wakeLock == null || !wakeLock.isHeld())) {
                wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "NetworkHunter::CpuWakeLock");
                wakeLock.setReferenceCounted(false);
                wakeLock.acquire();
            }
        } catch (Exception ignored) {}

        try {
            WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wm != null && (wifiLock == null || !wifiLock.isHeld())) {
                int lockType = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                        ? WifiManager.WIFI_MODE_FULL_LOW_LATENCY
                        : WifiManager.WIFI_MODE_FULL_HIGH_PERF;
                wifiLock = wm.createWifiLock(lockType, "NetworkHunter::WifiWakeLock");
                wifiLock.setReferenceCounted(false);
                wifiLock.acquire();
            }
        } catch (Exception ignored) {}
    }

    private void releaseLocks() {
        try {
            if (wakeLock != null && wakeLock.isHeld()) {
                wakeLock.release();
            }
        } catch (Exception ignored) {}

        try {
            if (wifiLock != null && wifiLock.isHeld()) {
                wifiLock.release();
            }
        } catch (Exception ignored) {}
    }

    @Override
    public void onDestroy() {
        releaseLocks();
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public static void createNotificationChannels(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) return;

            // 1. قناة المعاينة الحية الدائمة (هادئة لعدم الإزعاج مع كل تحديث رقم)
            NotificationChannel liveChannel = new NotificationChannel(
                    CHANNEL_LIVE_ID,
                    "المعاينة الحية للفحص (Live Status)",
                    NotificationManager.IMPORTANCE_LOW
            );
            liveChannel.setDescription("يعرض حالة الفحص المباشرة ورقم الكرت الحالي وعدد المحاولات في الخلفية");
            liveChannel.setShowBadge(false);
            nm.createNotificationChannel(liveChannel);

            // 2. قناة التنبيهات الحرجة (نجاح اصطياد كرت أو حدوث خلل)
            // الصوت يتم تشغيله حصرياً من ملفات assets/sounds/alert.mp3 و alert_error.mp3
            NotificationChannel alertChannel = new NotificationChannel(
                    CHANNEL_ALERT_ID,
                    "تنبيهات اصطياد الكروت والأخطاء الحرجة",
                    NotificationManager.IMPORTANCE_HIGH
            );
            alertChannel.setDescription("إشعارات فورية بصوت مخصص عالٍ جداً من assets/sounds عند اكتشاف كرت صحيح أو خطأ");
            alertChannel.enableVibration(true);
            alertChannel.setVibrationPattern(new long[]{0, 600, 200, 600, 200, 800});
            alertChannel.setBypassDnd(true);
            alertChannel.setSound(null, null);

            nm.createNotificationChannel(alertChannel);
        }
    }

    /**
     * تشغيل ملف الصوت المخصص حصرياً من المسار:
     * assets/sounds/alert.mp3 (للنجاح)
     * assets/sounds/alert_error.mp3 (للخطأ أو تغير الشبكة)
     * يعمل حتى لو كان التطبيق مغلقاً أو في الخلفية عبر MediaPlayer الأصلي للنظام.
     */
    public static void playCustomAssetAlertSound(Context context, boolean isError) {
        try {
            maximizeDeviceVolume(context);
            String assetRelativePath = isError ? "assets/sounds/alert_error.mp3" : "assets/sounds/alert.mp3";
            String lookupKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetRelativePath);

            if (activeMediaPlayer != null) {
                try {
                    if (activeMediaPlayer.isPlaying()) {
                        activeMediaPlayer.stop();
                    }
                    activeMediaPlayer.release();
                } catch (Exception ignored) {}
                activeMediaPlayer = null;
            }

            AssetFileDescriptor afd = context.getAssets().openFd(lookupKey);
            MediaPlayer mp = new MediaPlayer();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mp.setAudioAttributes(
                    new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                );
            } else {
                mp.setAudioStreamType(AudioManager.STREAM_ALARM);
            }
            mp.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            afd.close();
            mp.setVolume(1.0f, 1.0f);
            mp.prepare();
            mp.start();
            activeMediaPlayer = mp;

            // تكرار التنبيه مرة ثانية بعد انتهاء المقطع الأول لضمان الانتباه التام في الخلفية
            mp.setOnCompletionListener(player -> {
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    try {
                        player.seekTo(0);
                        player.start();
                        player.setOnCompletionListener(MediaPlayer::release);
                    } catch (Exception ignored) {}
                }, 250);
            });
        } catch (Exception ignored) {}
    }

    public static Notification buildLiveNotification(Context context, String title, String body, String subText) {
        Intent openIntent = new Intent(context, MainActivity.class);
        openIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        int flags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                : PendingIntent.FLAG_UPDATE_CURRENT;
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, openIntent, flags);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_LIVE_ID)
                .setSmallIcon(R.drawable.ic_notif_live)
                .setColor(0xFF0A224E)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(body).setBigContentTitle(title))
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setContentIntent(pendingIntent);

        if (subText != null && !subText.isEmpty()) {
            builder.setSubText(subText);
        }

        return builder.build();
    }

    public static void showHighPriorityAlertNotification(
            Context context,
            String title,
            String body,
            boolean isError,
            String alertType
    ) {
        createNotificationChannels(context);
        // تشغيل الصوت المخصص من assets/sounds/alert.mp3 أو alert_error.mp3
        playCustomAssetAlertSound(context, isError || "error".equals(alertType) || "wifi".equals(alertType));

        Intent openIntent = new Intent(context, MainActivity.class);
        openIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        int flags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                : PendingIntent.FLAG_UPDATE_CURRENT;
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 1, openIntent, flags);

        int smallIconRes = R.drawable.ic_notif_success;
        int accentColor = 0xFF00C853; // أخضر للنجاح
        if ("wifi".equals(alertType)) {
            smallIconRes = R.drawable.ic_notif_wifi_alert;
            accentColor = 0xFFFF9100; // برتقالي لتنبيه تغير الشبكة
        } else if (isError || "error".equals(alertType)) {
            smallIconRes = R.drawable.ic_notif_error;
            accentColor = 0xFFD50000; // أحمر للخطأ
        }

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ALERT_ID)
                .setSmallIcon(smallIconRes)
                .setColor(accentColor)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(body).setBigContentTitle(title))
                .setAutoCancel(true)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setVibrate(new long[]{0, 600, 200, 600, 200, 800})
                .setContentIntent(pendingIntent);

        NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) {
            int alertId = (int) (System.currentTimeMillis() % 100000) + 2000;
            nm.notify(alertId, builder.build());
        }
    }

    public static void maximizeDeviceVolume(Context context) {
        try {
            AudioManager am = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
            if (am != null) {
                int maxMusic = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
                am.setStreamVolume(AudioManager.STREAM_MUSIC, maxMusic, 0);

                int maxAlarm = am.getStreamMaxVolume(AudioManager.STREAM_ALARM);
                am.setStreamVolume(AudioManager.STREAM_ALARM, maxAlarm, 0);

                int maxNotif = am.getStreamMaxVolume(AudioManager.STREAM_NOTIFICATION);
                am.setStreamVolume(AudioManager.STREAM_NOTIFICATION, maxNotif, 0);
            }
        } catch (Exception ignored) {}
    }
}
