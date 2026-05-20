package com.sangnv.procare

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UPDATE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "openApkInstaller") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("missing_path", "APK path is required.", null)
                return@setMethodCallHandler
            }

            try {
                openApkInstaller(path)
                result.success(null)
            } catch (_: ActivityNotFoundException) {
                result.error(
                    "installer_not_found",
                    "No Android package installer was found.",
                    null,
                )
            } catch (exception: Exception) {
                result.error("install_failed", exception.message, null)
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val sourcePath = call.argument<String>("sourcePath")
            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType")
            if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank() || mimeType.isNullOrBlank()) {
                result.error("missing_args", "sourcePath, fileName, and mimeType are required.", null)
                return@setMethodCallHandler
            }

            try {
                result.success(saveToDownloads(sourcePath, fileName, mimeType))
            } catch (exception: UnsupportedOperationException) {
                result.error("downloads_unsupported", exception.message, null)
            } catch (exception: Exception) {
                result.error("save_failed", exception.message, null)
            }
        }
    }

    private fun openApkInstaller(path: String) {
        val apkFile = File(path)
        val apkUri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            apkFile,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun saveToDownloads(
        sourcePath: String,
        fileName: String,
        mimeType: String,
    ): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw UnsupportedOperationException("Public Downloads export requires Android 10 or newer.")
        }
        val source = File(sourcePath)
        require(source.exists()) { "Source file does not exist." }

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(
                MediaStore.Downloads.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/NEWS2-L",
            )
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Could not create Downloads file.")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(source).use { input ->
                    input.copyTo(output)
                }
            } ?: throw IllegalStateException("Could not open Downloads file.")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } catch (exception: Exception) {
            resolver.delete(uri, null, null)
            throw exception
        }
    }

    private companion object {
        const val UPDATE_CHANNEL = "news2_l/android_update"
        const val FILE_CHANNEL = "news2_l/android_files"
    }
}
