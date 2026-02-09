package com.aurora.chat

import android.util.Log
import com.baseflow.permissionhandler.PermissionHandlerPlugin
import dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin
import dev.isar.isar_flutter_libs.IsarFlutterLibsPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.pathprovider.PathProviderPlugin
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
import io.flutter.plugins.urllauncher.UrlLauncherPlugin
import one.mixin.pasteboard.PasteboardPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
            Log.i(TAG, "GeneratedPluginRegistrant completed")
        } catch (t: Throwable) {
            Log.e(TAG, "GeneratedPluginRegistrant failed; continue with fallback registration", t)
        }

        // If any plugin throws Error during static init, registration aborts and
        // plugins listed later are skipped. Register critical plugins defensively.
        safeRegister(flutterEngine, "isar_flutter_libs", IsarFlutterLibsPlugin::class.java) {
            IsarFlutterLibsPlugin()
        }
        safeRegister(flutterEngine, "package_info_plus", PackageInfoPlugin::class.java) {
            PackageInfoPlugin()
        }
        safeRegister(flutterEngine, "pasteboard", PasteboardPlugin::class.java) {
            PasteboardPlugin()
        }
        safeRegister(flutterEngine, "path_provider_android", PathProviderPlugin::class.java) {
            PathProviderPlugin()
        }
        safeRegister(flutterEngine, "permission_handler_android", PermissionHandlerPlugin::class.java) {
            PermissionHandlerPlugin()
        }
        safeRegister(flutterEngine, "shared_preferences_android", SharedPreferencesPlugin::class.java) {
            SharedPreferencesPlugin()
        }
        safeRegister(flutterEngine, "url_launcher_android", UrlLauncherPlugin::class.java) {
            UrlLauncherPlugin()
        }
    }

    private fun <T : FlutterPlugin> safeRegister(
        flutterEngine: FlutterEngine,
        name: String,
        pluginClass: Class<T>,
        factory: () -> T,
    ) {
        try {
            if (flutterEngine.plugins.has(pluginClass)) {
                Log.i(TAG, "Plugin already registered: $name")
                return
            }
            flutterEngine.plugins.add(factory())
            Log.i(TAG, "Plugin registered: $name")
        } catch (t: Throwable) {
            Log.e(TAG, "Plugin registration failed: $name", t)
        }
    }

    companion object {
        private const val TAG = "AuroraPluginInit"
    }
}
