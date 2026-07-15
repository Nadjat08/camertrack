package com.camertrack.bracelet.data

import android.os.Build
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

/**
 * Client réseau pour les appels du bracelet vers le backend.
 * enregistrerBracelet et statutBracelet ne passent jamais par verifierToken,
 * puisque la montre n'a pas encore de token à ce stade (voir bracelets.routes.js).
 * syncPosition et syncSos, eux, sont authentifiés via l'accessToken (verifierBraceletToken).
 */
object BraceletApiClient {

    private val client = OkHttpClient()
    private val JSON = "application/json; charset=utf-8".toMediaType()

    /**
     * POST /api/bracelets/enregistrer
     * Enregistre le bracelet côté backend (UPSERT, idempotent aux retry réseau).
     * Retourne le bracelet_id si succès, null en cas d'échec.
     */
    suspend fun enregistrerBracelet(identifiantUnique: String): Int? = withContext(Dispatchers.IO) {
        try {
            val corps = JSONObject().apply {
                put("identifiant_unique", identifiantUnique)
                put("deviceType", Build.MODEL)
                put("platform", "WearOS")
            }.toString().toRequestBody(JSON)

            val requete = Request.Builder()
                .url(ApiConfig.enregistrerBracelet)
                .post(corps)
                .build()

            client.newCall(requete).execute().use { reponse ->
                if (!reponse.isSuccessful) {
                    val corpsErreur = reponse.body?.string()
                    Log.e("CamerTrackBracelet", "Réponse HTTP ${reponse.code} : $corpsErreur")
                    return@withContext null
                }
                val texte = reponse.body?.string() ?: return@withContext null
                val json = JSONObject(texte)
                val braceletId = json.optInt("bracelet_id", -1)
                if (braceletId == -1) null else braceletId
            }
        } catch (e: Exception) {
            Log.e("CamerTrackBracelet", "Erreur enregistrerBracelet : ${e.message}", e)
            null
        }
    }

    /**
     * Résultat du polling de statut : l'état actuel du bracelet,
     * accompagné des tokens uniquement lors du passage à ASSOCIATED.
     */
    data class StatutResult(
        val status: String,
        val accessToken: String? = null,
        val refreshToken: String? = null
    )

    /**
     * GET /api/bracelets/status/:identifiant
     * Interroge le backend pour savoir si le bracelet est WAITING, ASSOCIATED ou PROVISIONED.
     */
    suspend fun statutBracelet(identifiantUnique: String): StatutResult = withContext(Dispatchers.IO) {
        try {
            val requete = Request.Builder()
                .url(ApiConfig.statutBracelet(identifiantUnique))
                .get()
                .build()

            client.newCall(requete).execute().use { reponse ->
                if (!reponse.isSuccessful) {
                    val corpsErreur = reponse.body?.string()
                    Log.e("CamerTrackBracelet", "statutBracelet HTTP ${reponse.code} : $corpsErreur")
                    return@withContext StatutResult(status = "ERREUR")
                }

                val texte = reponse.body?.string() ?: return@withContext StatutResult(status = "ERREUR")
                val json = JSONObject(texte)

                StatutResult(
                    status = json.optString("status", "ERREUR"),
                    accessToken = if (json.has("accessToken")) json.getString("accessToken") else null,
                    refreshToken = if (json.has("refreshToken")) json.getString("refreshToken") else null
                )
            }
        } catch (e: Exception) {
            Log.e("CamerTrackBracelet", "Erreur statutBracelet : ${e.message}", e)
            StatutResult(status = "ERREUR")
        }
    }

    /**
     * POST /api/locations/location/sync
     * Envoie une position GPS au backend. Authentifié via l'accessToken du bracelet.
     * Retourne true si la synchronisation a réussi.
     */
    suspend fun syncPosition(
        accessToken: String,
        latitude: Double,
        longitude: Double,
        precision: Float
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val position = JSONObject().apply {
                put("id", System.currentTimeMillis().toString())
                put("latitude", latitude)
                put("longitude", longitude)
                put("accuracy", precision)
                put("timestamp", java.time.Instant.now().toString())
            }
            val corps = "[$position]".toRequestBody(JSON)

            val requete = Request.Builder()
                .url(ApiConfig.locationSync)
                .addHeader("Authorization", "Bearer $accessToken")
                .post(corps)
                .build()

            client.newCall(requete).execute().use { reponse ->
                if (!reponse.isSuccessful) {
                    val corpsErreur = reponse.body?.string()
                    Log.e("CamerTrackBracelet", "syncPosition HTTP ${reponse.code} : $corpsErreur")
                    return@withContext false
                }
                true
            }
        } catch (e: Exception) {
            Log.e("CamerTrackBracelet", "Erreur syncPosition : ${e.message}", e)
            false
        }
    }

    /**
     * POST /api/locations/sos/sync
     * Déclenche une alerte SOS. Authentifié via l'accessToken, comme syncPosition.
     * Retourne true si l'alerte a bien été transmise au backend.
     */
    suspend fun syncSos(
        accessToken: String,
        latitude: Double,
        longitude: Double,
        precision: Float,
        severity: String = "HIGH"
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val alerte = JSONObject().apply {
                put("id", System.currentTimeMillis().toString())
                put("latitude", latitude)
                put("longitude", longitude)
                put("accuracy", precision)
                put("timestamp", java.time.Instant.now().toString())
                put("severity", severity)
            }
            val corps = "[$alerte]".toRequestBody(JSON)

            val requete = Request.Builder()
                .url(ApiConfig.sosSync)
                .addHeader("Authorization", "Bearer $accessToken")
                .post(corps)
                .build()

            client.newCall(requete).execute().use { reponse ->
                if (!reponse.isSuccessful) {
                    val corpsErreur = reponse.body?.string()
                    Log.e("CamerTrackBracelet", "syncSos HTTP ${reponse.code} : $corpsErreur")
                    return@withContext false
                }
                true
            }
        } catch (e: Exception) {
            Log.e("CamerTrackBracelet", "Erreur syncSos : ${e.message}", e)
            false
        }
    }
}