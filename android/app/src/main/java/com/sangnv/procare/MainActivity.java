package com.sangnv.procare;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.io.File;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String UPDATE_CHANNEL = "news2_l/android_update";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), UPDATE_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("openApkInstaller".equals(call.method)) {
                        String path = call.argument("path");
                        if (path == null || path.trim().isEmpty()) {
                            result.error("missing_path", "APK path is required.", null);
                            return;
                        }
                        try {
                            openApkInstaller(path);
                            result.success(null);
                        } catch (ActivityNotFoundException exception) {
                            result.error("installer_not_found", "No Android package installer was found.", null);
                        } catch (Exception exception) {
                            result.error("install_failed", exception.getMessage(), null);
                        }
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private void openApkInstaller(String path) {
        File apkFile = new File(path);
        Uri apkUri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", apkFile);
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(apkUri, "application/vnd.android.package-archive");
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }
}
