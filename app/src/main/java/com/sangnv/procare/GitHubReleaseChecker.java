package com.sangnv.procare;

import android.util.Log;
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
    private static final String TAG = "GitHubReleaseChecker";
    private static final int CONNECT_TIMEOUT_MS = 10000;
    private static final int READ_TIMEOUT_MS = 10000;

    private final ExecutorService executorService = Executors.newSingleThreadExecutor();
    private final UpdateListener updateListener;
    private boolean hasStartedCheck;

    public GitHubReleaseChecker(UpdateListener updateListener) {
        this.updateListener = updateListener;
    }

    public void checkForNewRelease() {
        if (hasStartedCheck) {
            return;
        }
        hasStartedCheck = true;
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                UpdateInfo updateInfo = fetchLatestRelease();
                if (updateInfo == null) {
                    Log.d(TAG, "No GitHub release information is available.");
                    return;
                }
                if (!isNewerVersion(updateInfo.version, BuildConfig.VERSION_NAME)) {
                    Log.d(TAG, "Latest release " + updateInfo.version + " is not newer than installed version " + BuildConfig.VERSION_NAME + ".");
                    return;
                }
                updateListener.onUpdateAvailable(updateInfo);
            }
        });
    }

    public void shutdown() {
        executorService.shutdownNow();
    }

    private UpdateInfo fetchLatestRelease() {
        UpdateInfo newestRelease = null;
        for (String apiUrl : BuildConfig.GITHUB_RELEASES_API_URLS) {
            UpdateInfo updateInfo = fetchLatestRelease(apiUrl);
            if (updateInfo != null && (newestRelease == null || isNewerVersion(updateInfo.version, newestRelease.version))) {
                newestRelease = updateInfo;
            }
        }
        return newestRelease;
    }

    private UpdateInfo fetchLatestRelease(String apiUrl) {
        HttpURLConnection connection = null;
        try {
            URL url = new URL(apiUrl);
            connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(CONNECT_TIMEOUT_MS);
            connection.setReadTimeout(READ_TIMEOUT_MS);
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept", "application/vnd.github+json");
            connection.setRequestProperty("User-Agent", "NEWS2-L-Android");

            int responseCode = connection.getResponseCode();
            if (responseCode < HttpURLConnection.HTTP_OK || responseCode >= HttpURLConnection.HTTP_MULT_CHOICE) {
                Log.d(TAG, "GitHub release request failed for " + apiUrl + " with HTTP " + responseCode + ".");
                return null;
            }
            return parseRelease(readStream(connection.getInputStream()));
        } catch (IOException | JSONException exception) {
            Log.d(TAG, "Unable to fetch GitHub release information from " + apiUrl + ".", exception);
            return null;
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    private UpdateInfo parseRelease(String response) throws JSONException {
        JSONObject release = new JSONObject(response);
        String version = extractVersion(release.optString("tag_name", release.optString("name")));
        if (version.isEmpty()) {
            return null;
        }
        String releaseUrl = release.optString("html_url");
        String downloadUrl = findDownloadUrl(release.optJSONArray("assets"), releaseUrl);
        return new UpdateInfo(version, downloadUrl.isEmpty() ? releaseUrl : downloadUrl, releaseUrl);
    }

    private String findDownloadUrl(JSONArray assets, String fallbackUrl) throws JSONException {
        if (assets == null || assets.length() == 0) {
            return fallbackUrl == null ? "" : fallbackUrl;
        }
        for (int i = 0; i < assets.length(); i++) {
            JSONObject asset = assets.getJSONObject(i);
            String name = asset.optString("name", "").toLowerCase(Locale.US);
            String contentType = asset.optString("content_type", "").toLowerCase(Locale.US);
            if (name.endsWith(".apk") || contentType.equals("application/vnd.android.package-archive")) {
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

    private boolean isNewerVersion(String remoteVersion, String currentVersion) {
        String[] remoteParts = extractVersion(remoteVersion).split("[.-]");
        String[] currentParts = extractVersion(currentVersion).split("[.-]");
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

    private String extractVersion(String version) {
        if (version == null) {
            return "";
        }
        String normalized = version.trim().replaceFirst("^[vV]", "");
        java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("(\\d+(?:[.-]\\d+)+)").matcher(normalized);
        return matcher.find() ? matcher.group(1) : normalized;
    }

    public interface UpdateListener {
        void onUpdateAvailable(UpdateInfo updateInfo);
    }

    public static class UpdateInfo {
        public final String version;
        public final String downloadUrl;
        public final String releaseUrl;

        private UpdateInfo(String version, String downloadUrl, String releaseUrl) {
            this.version = version;
            this.downloadUrl = downloadUrl;
            this.releaseUrl = releaseUrl;
        }
    }
}
