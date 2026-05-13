package com.sangnv.procare;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;

import androidx.appcompat.app.AlertDialog;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class GitHubReleaseChecker {
    private static final int CONNECT_TIMEOUT_MS = 10000;
    private static final int READ_TIMEOUT_MS = 10000;

    private final Activity activity;
    private final ExecutorService executorService = Executors.newSingleThreadExecutor();

    public GitHubReleaseChecker(Activity activity) {
        this.activity = activity;
    }

    public void checkForNewRelease() {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                ReleaseInfo releaseInfo = fetchLatestRelease();
                if (releaseInfo == null || !isNewerVersion(releaseInfo.version, BuildConfig.VERSION_NAME)) {
                    return;
                }
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        if (!activity.isFinishing()) {
                            showUpdateDialog(releaseInfo);
                        }
                    }
                });
            }
        });
    }

    public void shutdown() {
        executorService.shutdownNow();
    }

    private ReleaseInfo fetchLatestRelease() {
        HttpURLConnection connection = null;
        try {
            URL url = new URL(BuildConfig.GITHUB_RELEASES_API_URL);
            connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(CONNECT_TIMEOUT_MS);
            connection.setReadTimeout(READ_TIMEOUT_MS);
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept", "application/vnd.github+json");
            connection.setRequestProperty("User-Agent", "ProCare-Android");

            int responseCode = connection.getResponseCode();
            if (responseCode < HttpURLConnection.HTTP_OK || responseCode >= HttpURLConnection.HTTP_MULT_CHOICE) {
                return null;
            }
            return parseRelease(readStream(connection.getInputStream()));
        } catch (IOException | JSONException exception) {
            return null;
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    private ReleaseInfo parseRelease(String response) throws JSONException {
        JSONObject release = new JSONObject(response);
        String version = normalizeVersion(release.optString("tag_name", release.optString("name")));
        if (version.isEmpty()) {
            return null;
        }
        String releaseUrl = release.optString("html_url");
        String downloadUrl = findDownloadUrl(release.optJSONArray("assets"), releaseUrl);
        return new ReleaseInfo(version, downloadUrl.isEmpty() ? releaseUrl : downloadUrl);
    }

    private String findDownloadUrl(JSONArray assets, String fallbackUrl) throws JSONException {
        if (assets == null || assets.length() == 0) {
            return fallbackUrl == null ? "" : fallbackUrl;
        }
        for (int i = 0; i < assets.length(); i++) {
            JSONObject asset = assets.getJSONObject(i);
            String name = asset.optString("name", "").toLowerCase(Locale.US);
            if (name.endsWith(".apk") || name.endsWith(".aab")) {
                return asset.optString("browser_download_url", fallbackUrl);
            }
        }
        JSONObject firstAsset = assets.getJSONObject(0);
        return firstAsset.optString("browser_download_url", fallbackUrl == null ? "" : fallbackUrl);
    }

    private String readStream(InputStream inputStream) throws IOException {
        StringBuilder builder = new StringBuilder();
        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
        String line;
        while ((line = reader.readLine()) != null) {
            builder.append(line);
        }
        return builder.toString();
    }

    private void showUpdateDialog(ReleaseInfo releaseInfo) {
        new AlertDialog.Builder(activity)
                .setTitle(activity.getString(R.string.update_available_title))
                .setMessage(activity.getString(R.string.update_available_message, releaseInfo.version, BuildConfig.VERSION_NAME))
                .setPositiveButton(R.string.update_download_action, (dialog, which) -> openReleaseUrl(releaseInfo.downloadUrl))
                .setNegativeButton(R.string.update_later_action, null)
                .show();
    }

    private void openReleaseUrl(String downloadUrl) {
        if (downloadUrl == null || downloadUrl.trim().isEmpty()) {
            return;
        }
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(downloadUrl));
        try {
            activity.startActivity(intent);
        } catch (ActivityNotFoundException exception) {
            // No browser or file handler is available on the device.
        }
    }

    private boolean isNewerVersion(String remoteVersion, String currentVersion) {
        String[] remoteParts = normalizeVersion(remoteVersion).split("[.-]");
        String[] currentParts = normalizeVersion(currentVersion).split("[.-]");
        int length = Math.max(remoteParts.length, currentParts.length);
        for (int i = 0; i < length; i++) {
            int remoteValue = versionPart(remoteParts, i);
            int currentValue = versionPart(currentParts, i);
            if (remoteValue > currentValue) {
                return true;
            }
            if (remoteValue < currentValue) {
                return false;
            }
        }
        return false;
    }

    private int versionPart(String[] parts, int index) {
        if (index >= parts.length) {
            return 0;
        }
        try {
            return Integer.parseInt(parts[index].replaceAll("\\D.*", ""));
        } catch (NumberFormatException exception) {
            return 0;
        }
    }

    private String normalizeVersion(String version) {
        if (version == null) {
            return "";
        }
        return version.trim().replaceFirst("^[vV]", "");
    }

    private static class ReleaseInfo {
        private final String version;
        private final String downloadUrl;

        private ReleaseInfo(String version, String downloadUrl) {
            this.version = version;
            this.downloadUrl = downloadUrl;
        }
    }
}
