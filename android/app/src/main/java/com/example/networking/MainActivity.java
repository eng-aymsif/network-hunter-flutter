package com.example.networking;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.networking/native";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
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
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    private boolean checkPermissionsGranted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            boolean loc = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                boolean notif = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED;
                return loc && notif;
            }
            return loc;
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
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    perms.add(Manifest.permission.POST_NOTIFICATIONS);
                }
            }
            if (!perms.isEmpty()) {
                ActivityCompat.requestPermissions(this, perms.toArray(new String[0]), 101);
            }
        }
    }

    private boolean reconnectWifi() {
        // 1. محاولة أوامر الروت أولاً إن توفرت
        try {
            Process p = Runtime.getRuntime().exec(new String[]{"su", "-c", "svc wifi disable && sleep 1 && svc wifi enable"});
            int code = p.waitFor();
            if (code == 0) return true;
        } catch (Exception ignored) {}

        // 2. المحاولة للأجهزة العادية بدون روت
        try {
            WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wm != null) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    wm.setWifiEnabled(false);
                    new Handler(Looper.getMainLooper()).postDelayed(() -> wm.setWifiEnabled(true), 1500);
                    return true;
                } else {
                    wm.disconnect();
                    new Handler(Looper.getMainLooper()).postDelayed(wm::reconnect, 1500);
                    return true;
                }
            }
        } catch (Exception ignored) {}

        return false;
    }

    private void openWifiSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startActivity(new Intent(Settings.Panel.ACTION_WIFI));
            } else {
                startActivity(new Intent(Settings.ACTION_WIFI_SETTINGS));
            }
        } catch (Exception e) {
            startActivity(new Intent(Settings.ACTION_WIFI_SETTINGS));
        }
    }
}
