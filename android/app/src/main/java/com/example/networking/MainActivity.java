package com.example.networking;

import android.Manifest;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.networking/native";
    private MethodChannel methodChannel;
    private BroadcastReceiver wifiNetworkReceiver;
    private String lastBroadcastSsid = "";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        registerWifiBroadcastReceiver();

        methodChannel.setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "shareText": {
                            String text = call.argument("text");
                            String subject = call.argument("subject");
                            Intent sendIntent = new Intent(Intent.ACTION_SEND);
                            sendIntent.setType("text/plain");
                            sendIntent.putExtra(Intent.EXTRA_TEXT, text);
                            if (subject != null) {
                                sendIntent.putExtra(Intent.EXTRA_SUBJECT, subject);
                            }
                            Intent shareIntent = Intent.createChooser(sendIntent, "مشاركة عبر");
                            startActivity(shareIntent);
                            result.success(true);
                            break;
                        }
                        case "setKeepScreenOn": {
                            Boolean enable = call.argument("enable");
                            if (enable != null && enable) {
                                getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                            } else {
                                getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                            }
                            result.success(true);
                            break;
                        }
                        case "checkRoot": {
                            boolean isRoot = isDeviceRooted();
                            result.success(isRoot);
                            break;
                        }
                        case "executeRootMacChange": {
                            String mac = call.argument("mac");
                            Map<String, Object> res = executeRootMacChange(mac);
                            result.success(res);
                            break;
                        }
                        case "reconnectWifi": {
                            boolean ok = reconnectWifi();
                            result.success(ok);
                            break;
                        }
                        case "openWifiSettings": {
                            openWifiSettings();
                            result.success(true);
                            break;
                        }
                        case "requestAppPermissions": {
                            requestAppPermissions();
                            result.success(true);
                            break;
                        }
                        case "checkPermissions": {
                            boolean granted = checkPermissionsGranted();
                            result.success(granted);
                            break;
                        }
                        case "startForegroundService": {
                            String title = call.argument("title");
                            String body = call.argument("body");
                            String subText = call.argument("subText");
                            startHunterForegroundService(title, body, subText);
                            result.success(true);
                            break;
                        }
                        case "updateForegroundNotification": {
                            String title = call.argument("title");
                            String body = call.argument("body");
                            String subText = call.argument("subText");
                            updateHunterForegroundNotification(title, body, subText);
                            result.success(true);
                            break;
                        }
                        case "stopForegroundService": {
                            stopHunterForegroundService();
                            result.success(true);
                            break;
                        }
                        case "showAlertNotification": {
                            String title = call.argument("title");
                            String body = call.argument("body");
                            Boolean isError = call.argument("isError");
                            String alertType = call.argument("alertType");
                            HunterForegroundService.showHighPriorityAlertNotification(
                                getApplicationContext(),
                                title != null ? title : "تنبيه Network Hunter",
                                body != null ? body : "",
                                isError != null && isError,
                                alertType != null ? alertType : ((isError != null && isError) ? "error" : "success")
                            );
                            result.success(true);
                            break;
                        }
                        case "getCurrentWifiSsid": {
                            result.success(getCurrentWifiSsid());
                            break;
                        }
                        case "maximizeVolume": {
                            HunterForegroundService.maximizeDeviceVolume(getApplicationContext());
                            result.success(true);
                            break;
                        }
                        case "playCustomAlertSound": {
                            Boolean isError = call.argument("isError");
                            HunterForegroundService.playCustomAssetAlertSound(
                                getApplicationContext(),
                                isError != null && isError
                            );
                            result.success(true);
                            break;
                        }
                        case "isIgnoringBatteryOptimizations": {
                            result.success(isIgnoringBatteryOptimizations());
                            break;
                        }
                        case "requestIgnoreBatteryOptimizations": {
                            requestIgnoreBatteryOptimizations();
                            result.success(true);
                            break;
                        }
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    private void registerWifiBroadcastReceiver() {
        if (wifiNetworkReceiver != null) return;
        wifiNetworkReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (intent == null || intent.getAction() == null) return;

                // انتظر لحظة قصيرة حتى يستقر اتصال الـ DHCP/SSID بعد إعادة الاتصال
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    String currentSsid = getCurrentWifiSsid();
                    if (currentSsid != null && !currentSsid.isEmpty() && !currentSsid.equals("<unknown ssid>")) {
                        if (!currentSsid.equals(lastBroadcastSsid)) {
                            lastBroadcastSsid = currentSsid;
                            if (methodChannel != null) {
                                Map<String, Object> args = new HashMap<>();
                                args.put("ssid", currentSsid);
                                methodChannel.invokeMethod("onWifiNetworkChanged", args);
                            }
                        }
                    } else {
                        lastBroadcastSsid = "";
                    }
                }, 800);
            }
        };

        IntentFilter filter = new IntentFilter();
        filter.addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION);
        filter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        registerReceiver(wifiNetworkReceiver, filter);
    }

    private String getCurrentWifiSsid() {
        try {
            WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifiManager != null && wifiManager.isWifiEnabled()) {
                WifiInfo info = wifiManager.getConnectionInfo();
                if (info != null && info.getNetworkId() != -1) {
                    String ssid = info.getSSID();
                    if (ssid != null) {
                        if (ssid.startsWith("\"") && ssid.endsWith("\"") && ssid.length() >= 2) {
                            ssid = ssid.substring(1, ssid.length() - 1);
                        }
                        if (!ssid.equals("<unknown ssid>") && !ssid.equals("0x") && !ssid.isEmpty()) {
                            return ssid;
                        }
                    }
                }
            }
        } catch (Exception ignored) {}
        return "";
    }

    @Override
    protected void onDestroy() {
        if (wifiNetworkReceiver != null) {
            try {
                unregisterReceiver(wifiNetworkReceiver);
            } catch (Exception ignored) {}
            wifiNetworkReceiver = null;
        }
        super.onDestroy();
    }

    private void startHunterForegroundService(String title, String body, String subText) {
        try {
            Intent intent = new Intent(this, HunterForegroundService.class);
            intent.setAction(HunterForegroundService.ACTION_START);
            intent.putExtra("title", title);
            intent.putExtra("body", body);
            intent.putExtra("subText", subText);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(this, intent);
            } else {
                startService(intent);
            }
        } catch (Exception ignored) {}
    }

    private void updateHunterForegroundNotification(String title, String body, String subText) {
        try {
            Intent intent = new Intent(this, HunterForegroundService.class);
            intent.setAction(HunterForegroundService.ACTION_UPDATE);
            intent.putExtra("title", title);
            intent.putExtra("body", body);
            intent.putExtra("subText", subText);
            startService(intent);
        } catch (Exception ignored) {}
    }

    private void stopHunterForegroundService() {
        try {
            Intent intent = new Intent(this, HunterForegroundService.class);
            intent.setAction(HunterForegroundService.ACTION_STOP);
            stopService(intent);
        } catch (Exception ignored) {}
    }

    private boolean isIgnoringBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
            if (pm != null) {
                return pm.isIgnoringBatteryOptimizations(getPackageName());
            }
        }
        return true;
    }

    private void requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
                if (pm != null && !pm.isIgnoringBatteryOptimizations(getPackageName())) {
                    Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                    intent.setData(Uri.parse("package:" + getPackageName()));
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(intent);
                }
            } catch (Exception e) {
                try {
                    Intent intent = new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(intent);
                } catch (Exception ignored) {}
            }
        }
    }

    private boolean isDeviceRooted() {
        Process p = null;
        try {
            p = Runtime.getRuntime().exec(new String[]{"su", "-c", "id"});
            BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
            String line = reader.readLine();
            int exitCode = p.waitFor();
            return exitCode == 0 && line != null && line.contains("uid=0");
        } catch (Exception e) {
            return false;
        } finally {
            if (p != null) p.destroy();
        }
    }

    private Map<String, Object> executeRootMacChange(String newMac) {
        Map<String, Object> map = new HashMap<>();
        Process p = null;
        try {
            // تنفيذ أوامر الروت الحقيقية لإعادة ضبط كارت الشبكة وتعيين الماك
            String cmd = "ip link set wlan0 down 2>/dev/null; " +
                         "ip link set wlan0 address " + newMac + " 2>/dev/null; " +
                         "ip link set wlan0 up 2>/dev/null; " +
                         "svc wifi disable; sleep 1; svc wifi enable";
            p = Runtime.getRuntime().exec(new String[]{"su", "-c", cmd});
            int exitCode = p.waitFor();
            map.put("success", exitCode == 0);
            map.put("mac", newMac);
            map.put("method", "root");
            return map;
        } catch (Exception e) {
            map.put("success", false);
            map.put("error", e.getMessage());
            map.put("method", "root");
            return map;
        } finally {
            if (p != null) p.destroy();
        }
    }

    private boolean reconnectWifi() {
        if (isDeviceRooted()) {
            Process p = null;
            try {
                p = Runtime.getRuntime().exec(new String[]{"su", "-c", "svc wifi disable && sleep 1 && svc wifi enable"});
                return p.waitFor() == 0;
            } catch (Exception ignored) {
            } finally {
                if (p != null) p.destroy();
            }
        }

        // محاولة استخدام WifiManager للأجهزة ما دون Android 10 أو التي تسمح بها
        try {
            android.net.wifi.WifiManager wifiManager = (android.net.wifi.WifiManager) getApplicationContext().getSystemService(android.content.Context.WIFI_SERVICE);
            if (wifiManager != null) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    @SuppressWarnings("deprecation")
                    boolean disabled = wifiManager.setWifiEnabled(false);
                    try { Thread.sleep(1000); } catch (InterruptedException ignored) {}
                    @SuppressWarnings("deprecation")
                    boolean enabled = wifiManager.setWifiEnabled(true);
                    if (disabled && enabled) {
                        return true;
                    }
                } else {
                    // على أندرويد 10 فما فوق، محاولة إعادة الربط (reassociate / reconnect)
                    @SuppressWarnings("deprecation")
                    boolean disconnected = wifiManager.disconnect();
                    try { Thread.sleep(800); } catch (InterruptedException ignored) {}
                    @SuppressWarnings("deprecation")
                    boolean reconnected = wifiManager.reconnect();
                    if (disconnected || reconnected) {
                        return true;
                    }
                }
            }
        } catch (Exception ignored) {}

        // إذا تعذر ذلك برمجياً، يتم فتح نافذة اللوحة السريعة المباشرة
        openWifiSettings();
        return false;
    }

    private void openWifiSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Intent panelIntent = new Intent(Settings.Panel.ACTION_WIFI);
                panelIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(panelIntent);
            } else {
                Intent intent = new Intent(Settings.ACTION_WIFI_SETTINGS);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            }
        } catch (Exception e) {
            Intent intent = new Intent(Settings.ACTION_WIFI_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
    }

    private boolean checkPermissionsGranted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            boolean loc = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
            boolean battery = isIgnoringBatteryOptimizations();
            boolean nearby = true;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                nearby = ContextCompat.checkSelfPermission(this, Manifest.permission.NEARBY_WIFI_DEVICES) == PackageManager.PERMISSION_GRANTED;
                boolean notif = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED;
                return loc && nearby && notif && battery;
            }
            return loc && battery;
        }
        return true;
    }

    private void requestAppPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            List<String> perms = new ArrayList<>();
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                perms.add(Manifest.permission.ACCESS_FINE_LOCATION);
                perms.add(Manifest.permission.ACCESS_COARSE_LOCATION);
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.NEARBY_WIFI_DEVICES) != PackageManager.PERMISSION_GRANTED) {
                    perms.add(Manifest.permission.NEARBY_WIFI_DEVICES);
                }
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    perms.add(Manifest.permission.POST_NOTIFICATIONS);
                }
            }
            if (!perms.isEmpty()) {
                ActivityCompat.requestPermissions(this, perms.toArray(new String[0]), 101);
            }
            if (!isIgnoringBatteryOptimizations()) {
                requestIgnoreBatteryOptimizations();
            }
        }
    }
}
