subprojects {
    if (name != "isar_flutter_libs") {
        return@subprojects
    }

    pluginManager.withPlugin("com.android.library") {
        afterEvaluate {
            val androidExtension = extensions.findByName("android") ?: return@afterEvaluate
            androidExtension.javaClass.methods
                .firstOrNull { method ->
                    method.name == "setNamespace" &&
                        method.parameterTypes.contentEquals(arrayOf(String::class.java))
                }
                ?.invoke(androidExtension, "dev.isar.isar_flutter_libs")
            androidExtension.javaClass.methods
                .firstOrNull { method ->
                    method.name == "setCompileSdkVersion" &&
                        method.parameterTypes.size == 1
                }
                ?.invoke(androidExtension, 34)
        }
    }
}
