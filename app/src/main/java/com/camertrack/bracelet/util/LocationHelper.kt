package com.camertrack.bracelet.util

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Récupère la dernière position GPS connue, pour un déclenchement immédiat
 * (typiquement le bouton SOS), sans attendre le prochain cycle du TrackerService.
 */
object LocationHelper {

    @SuppressLint("MissingPermission") // La permission est vérifiée par l'appelant avant d'utiliser cette fonction
    suspend fun obtenirDernierePosition(context: Context): Location? =
        suspendCancellableCoroutine { continuation ->
            val client = LocationServices.getFusedLocationProviderClient(context)
            client.lastLocation
                .addOnSuccessListener { location ->
                    continuation.resume(location)
                }
                .addOnFailureListener {
                    continuation.resume(null)
                }
        }
}