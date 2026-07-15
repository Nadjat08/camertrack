package com.camertrack.bracelet.data

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.util.Calendar
import java.util.Locale
import kotlin.random.Random

/**
 * Gère l'identifiant unique du bracelet (format BRC-YYYY-XXXXXX).
 * Il est généré une seule fois, au tout premier lancement de l'app,
 * puis conservé de façon sécurisée pour tous les lancements suivants.
 */
object BraceletIdentity {

    private const val PREFS_NAME = "camertrack_bracelet_secure_prefs"
    private const val KEY_IDENTIFIANT_UNIQUE = "identifiant_unique"

    private fun prefs(context: Context) = run {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    /**
     * Retourne l'identifiant unique du bracelet.
     * S'il n'existe pas encore (premier lancement), le génère et le sauvegarde.
     */
    fun getOrCreateIdentifiant(context: Context): String {
        val sharedPrefs = prefs(context)
        val existant = sharedPrefs.getString(KEY_IDENTIFIANT_UNIQUE, null)
        if (existant != null) return existant

        val nouveau = genererIdentifiant()
        sharedPrefs.edit().putString(KEY_IDENTIFIANT_UNIQUE, nouveau).apply()
        return nouveau
    }

    /**
     * Génère un identifiant au format BRC-YYYY-XXXXXX
     * (YYYY = année courante, XXXXXX = 6 caractères alphanumériques aléatoires).
     */
    private fun genererIdentifiant(): String {
        val annee = Calendar.getInstance().get(Calendar.YEAR)
        val caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        val suffixe = (1..6)
            .map { caracteres[Random.nextInt(caracteres.length)] }
            .joinToString("")
        return String.format(Locale.US, "BRC-%d-%s", annee, suffixe)
    }
}