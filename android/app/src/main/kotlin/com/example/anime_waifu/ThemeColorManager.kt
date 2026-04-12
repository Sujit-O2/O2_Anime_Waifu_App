package com.example.anime_waifu

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import com.google.gson.Gson
import com.google.gson.JsonObject

/**
 * Manages theme colors from Flutter app's SharedPreferences
 * Reads custom theme colors and converts them to Android notification colors
 */
object ThemeColorManager {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val ACTIVE_THEME_KEY = "flutter.active_theme_id"
    private const val CUSTOM_THEMES_KEY = "flutter.custom_themes"
    private const val APP_THEME_PRIMARY = "flutter.app_theme_primary"
    private const val APP_THEME_ACCENT = "flutter.app_theme_accent"

    data class ThemeColors(
        val primaryColor: Int,
        val accentColor: Int,
        val backgroundColor: Int,
        val secondaryColor: Int
    )

    /**
     * Get notification colors from the current app theme
     */
    fun getNotificationColors(context: Context): ThemeColors {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // Try to get colors from custom theme first
            val customColors = getCustomThemeColors(prefs)
            if (customColors != null) {
                return customColors
            }
            
            // Fallback to default colors from app settings
            val primaryHex = prefs.getString(APP_THEME_PRIMARY, "#FF2196F3") ?: "#FF2196F3"
            val accentHex = prefs.getString(APP_THEME_ACCENT, "#FFE91E63") ?: "#FFE91E63"
            
            ThemeColors(
                primaryColor = hexToAndroidColor(primaryHex),
                accentColor = hexToAndroidColor(accentHex),
                backgroundColor = 0xFF121212.toInt(), // Dark background default
                secondaryColor = hexToAndroidColor("#FF1976D2")
            )
        } catch (e: Exception) {
            e.printStackTrace()
            // Return default Material Design colors if something fails
            getDefaultThemeColors()
        }
    }

    /**
     * Get colors from custom theme in SharedPreferences
     */
    private fun getCustomThemeColors(prefs: SharedPreferences): ThemeColors? {
        return try {
            val themesJson = prefs.getString(CUSTOM_THEMES_KEY, null) ?: return null
            val gson = Gson()
            val customThemes = gson.fromJson(themesJson, Array<JsonObject>::class.java)
            
            if (customThemes.isEmpty()) return null
            
            // Use the most recently modified theme (last one)
            val theme = customThemes.last()
            
            ThemeColors(
                primaryColor = hexToAndroidColor(theme.get("primaryColor").asString),
                accentColor = hexToAndroidColor(theme.get("accentColor").asString),
                backgroundColor = hexToAndroidColor(theme.get("backgroundColor").asString),
                secondaryColor = hexToAndroidColor(theme.get("secondaryColor").asString)
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    /**
     * Convert hex string (#RRGGBB format) to Android Color int
     */
    fun hexToAndroidColor(hexString: String): Int {
        return try {
            val hex = when {
                hexString.startsWith("#") -> hexString.substring(1)
                else -> hexString
            }
            
            // Ensure 8-digit hex (with alpha channel FF for opaque)
            val fullHex = when (hex.length) {
                6 -> "FF$hex"  // Add opaque alpha
                8 -> hex
                else -> "FFFF2196F3"  // Default Material blue
            }
            
            Color.parseColor("#$fullHex")
        } catch (e: Exception) {
            e.printStackTrace()
            0xFFFF2196F3.toInt()  // Material blue fallback
        }
    }

    /**
     * Get default Material Design 3 colors
     */
    fun getDefaultThemeColors(): ThemeColors {
        return ThemeColors(
            primaryColor = 0xFF2196F3.toInt(),      // Material Blue
            accentColor = 0xFFE91E63.toInt(),       // Material Pink
            backgroundColor = 0xFF121212.toInt(),   // Dark background
            secondaryColor = 0xFF1976D2.toInt()     // Deep Blue
        )
    }
}
