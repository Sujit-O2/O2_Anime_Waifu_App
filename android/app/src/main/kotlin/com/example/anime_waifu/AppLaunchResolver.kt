package com.example.anime_waifu

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

object AppLaunchResolver {
    fun openByPackage(context: Context, targetPackage: String): Boolean {
        if (targetPackage.isBlank()) return false
        return try {
            val pm = context.packageManager
            val launchIntent = pm.getLaunchIntentForPackage(targetPackage)
            if (launchIntent != null) {
                launchIntent.addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
                context.startActivity(launchIntent)
                return true
            }

            val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
                `package` = targetPackage
            }
            @Suppress("DEPRECATION")
            val candidates = pm.queryIntentActivities(launcherIntent, 0)
            if (!candidates.isNullOrEmpty()) {
                val first = candidates.first().activityInfo
                val explicit = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    component = ComponentName(first.packageName, first.name)
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    )
                }
                context.startActivity(explicit)
                return true
            }

            val knownClasses = knownLaunchComponents(targetPackage)
            for (className in knownClasses) {
                try {
                    val explicit = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        component = ComponentName(targetPackage, className)
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP
                        )
                    }
                    context.startActivity(explicit)
                    return true
                } catch (_: Exception) {
                    // Try next component.
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    fun openResolvedIntent(
        context: Context,
        action: String,
        category: String?,
        data: String?
    ): Boolean {
        if (action.isBlank()) return false
        return try {
            val pm = context.packageManager
            val baseIntent = Intent(action).apply {
                if (!category.isNullOrBlank()) addCategory(category)
                if (!data.isNullOrBlank()) {
                    this.data = Uri.parse(data)
                }
            }

            val resolved = pm.resolveActivity(baseIntent, PackageManager.MATCH_DEFAULT_ONLY)
                ?: pm.resolveActivity(baseIntent, 0)
                ?: return false

            val activityInfo = resolved.activityInfo ?: return false
            val explicitIntent = Intent(baseIntent).apply {
                setClassName(activityInfo.packageName, activityInfo.name)
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }

            context.startActivity(explicitIntent)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun openByName(context: Context, query: String): String? {
        if (query.isBlank()) return null
        return try {
            val pm = context.packageManager
            val packageLike = query.trim()
            if (packageLike.contains(".") && openByPackage(context, packageLike)) {
                return packageLike
            }

            val q = normalizeAppToken(query)
            val knownPackages = resolveKnownPackagesByQuery(q)
            for (pkg in knownPackages) {
                if (openByPackage(context, pkg)) {
                    return pkg
                }
            }

            val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            @Suppress("DEPRECATION")
            val apps = pm.queryIntentActivities(launcherIntent, 0)
            if (apps.isNullOrEmpty()) return null

            var best: android.content.pm.ResolveInfo? = null
            var bestScore = 0

            for (resolve in apps) {
                val activity = resolve.activityInfo ?: continue
                val label = normalizeAppToken(resolve.loadLabel(pm)?.toString() ?: "")
                val pkg = normalizeAppToken(activity.packageName)
                val score = when {
                    label == q || pkg == q -> 100
                    label.startsWith(q) || pkg.startsWith(q) -> 90
                    label.contains(q) || pkg.contains(q) -> 80
                    q.contains(label) && label.length >= 4 -> 60
                    hasStrongTokenOverlap(label, q) || hasStrongTokenOverlap(pkg, q) -> 55
                    else -> 0
                }
                if (score > bestScore) {
                    bestScore = score
                    best = resolve
                }
            }

            val target = best?.activityInfo ?: return null
            if (bestScore <= 0) return null

            val explicitIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
                setClassName(target.packageName, target.name)
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }
            context.startActivity(explicitIntent)
            target.packageName
        } catch (_: Exception) {
            null
        }
    }

    private fun normalizeAppToken(input: String): String {
        return input.lowercase().replace(Regex("[^a-z0-9]"), "")
    }

    private fun hasStrongTokenOverlap(a: String, b: String): Boolean {
        if (a.isBlank() || b.isBlank()) return false
        if (a.length < 4 || b.length < 4) return false
        val minLen = minOf(a.length, b.length)
        var longest = 0
        for (i in a.indices) {
            for (j in b.indices) {
                var k = 0
                while (i + k < a.length && j + k < b.length && a[i + k] == b[j + k]) {
                    k++
                }
                if (k > longest) longest = k
                if (longest >= minLen.coerceAtMost(6)) return true
            }
        }
        return longest >= 5
    }

    private fun resolveKnownPackagesByQuery(query: String): List<String> {
        return when (query) {
            "whatsapp",
            "whatsap",
            "whatsaapp",
            "watsapp",
            "whatsup",
            "wa",
            "whatsappmessenger" -> listOf("com.whatsapp", "com.whatsapp.w4b")
            "whatsappbusiness",
            "wabusiness",
            "whatsappbiz" -> listOf("com.whatsapp.w4b", "com.whatsapp")
            "gmail",
            "gmain",
            "gmial",
            "googlemail",
            "mail" -> listOf(
                "com.google.android.gm",
                "com.google.android.gm.lite",
                "com.google.android.email",
            )
            "youtube",
            "youtub",
            "yt" -> listOf("com.google.android.youtube")
            "telegram",
            "tele",
            "tg",
            "telegrammessenger",
            "telegramapp" -> listOf("org.telegram.messenger")
            "telegramx",
            "tgx",
            "tx",
            "xtelegram",
            "telegramxapp" -> listOf("org.thunderdog.challegram")
            "xplayer",
            "xvideo",
            "xvideos",
            "xvideoplayer",
            "xvideoplayerapp" -> listOf(
                "video.player.videoplayer",
                "com.inshot.xplayer",
                "com.mxtech.videoplayer.ad",
            )
            "google",
            "googlesearch",
            "googleapp" -> listOf(
                "com.google.android.googlequicksearchbox",
                "com.android.chrome",
            )
            "playstore",
            "playstoreapp",
            "googleplay",
            "googleplaystore" -> listOf("com.android.vending")
            else -> emptyList()
        }
    }

    private fun knownLaunchComponents(pkg: String): List<String> {
        return when (pkg) {
            "com.whatsapp" -> listOf(
                "com.whatsapp.HomeActivity",
                "com.whatsapp.Main",
            )
            "com.whatsapp.w4b" -> listOf(
                "com.whatsapp.w4b.HomeActivity",
            )
            "com.google.android.gm" -> listOf(
                "com.google.android.gm.ConversationListActivityGmail",
                "com.google.android.gm.GmailActivity",
            )
            "com.google.android.youtube" -> listOf(
                "com.google.android.apps.youtube.app.WatchWhileActivity",
                "com.google.android.youtube.HomeActivity",
            )
            "org.telegram.messenger" -> listOf(
                "org.telegram.ui.LaunchActivity",
            )
            "org.thunderdog.challegram" -> listOf(
                "org.thunderdog.challegram.MainActivity",
            )
            "video.player.videoplayer" -> listOf(
                "video.player.videoplayer.videoeffect.MainActivity",
                "video.player.videoplayer.MainActivity",
            )
            "com.google.android.googlequicksearchbox" -> listOf(
                "com.google.android.apps.gsa.searchnow.SearchNowActivity",
                "com.google.android.apps.gsa.search.core.google.GoogleAppActivity",
            )
            else -> emptyList()
        }
    }
}
