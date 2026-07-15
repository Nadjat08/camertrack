package com.camertrack.bracelet.service

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.camertrack.bracelet.R
import com.camertrack.bracelet.data.BraceletApiClient
import com.camertrack.bracelet.data.TokenStore
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Service d'arrière-plan (daemon) qui envoie la position GPS de la montre
 * au backend toutes les 30 secondes, même écran éteint.
 * Ne démarre que si le bracelet possède déjà un accessToken (statut ASSOCIATED/PROVISIONED).
 */
class TrackerService : Service() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    companion object {
        private const val CHANNEL_ID = "camertrack_tracker_channel"
        private const val NOTIFICATION_ID = 1
        private const val INTERVALLE_MS = 30_000L
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        demarrerEnPremierPlan()
        demarrerSuiviPosition()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        if (::locationCallback.isInitialized) {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        }
    }

    /**
     * Un Foreground Service doit obligatoirement afficher une notification persistante
     * tant qu'il tourne (exigence Android).
     */
    private fun demarrerEnPremierPlan() {
        creerCanalNotification()

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("CamerTrack Bracelet")
            .setContentText("Localisation active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun creerCanalNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Suivi de localisation",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * Démarre l'écoute des mises à jour GPS toutes les 30 secondes,
     * et envoie chaque nouvelle position au backend.
     */
    private fun demarrerSuiviPosition() {
        val permissionAccordee = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!permissionAccordee) {
            Log.e("CamerTrackBracelet", "Permission localisation manquante, arrêt du service")
            stopSelf()
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, INTERVALLE_MS)
            .setMinUpdateIntervalMillis(INTERVALLE_MS)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { envoyerPosition(it) }
            }
        }

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            mainLooper
        )
    }

    private fun envoyerPosition(location: Location) {
        val accessToken = TokenStore.getAccessToken(applicationContext)
        if (accessToken == null) {
            Log.e("CamerTrackBracelet", "Pas de token disponible, position non envoyée")
            return
        }

        scope.launch {
            val succes = BraceletApiClient.syncPosition(
                accessToken = accessToken,
                latitude = location.latitude,
                longitude = location.longitude,
                precision = location.accuracy
            )
            if (!succes) {
                Log.e("CamerTrackBracelet", "Échec de l'envoi de position")
            }
        }
    }
}