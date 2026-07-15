package com.camertrack.bracelet.data

object ApiConfig {
    private const val BASE_URL = "http://10.0.2.2:3000/api"

    const val enregistrerBracelet = "$BASE_URL/bracelets/enregistrer"
    const val locationSync = "$BASE_URL/locations/location/sync"
    const val sosSync = "$BASE_URL/locations/sos/sync"
    const val syncPositions = "$BASE_URL/locations/location/sync"

    fun statutBracelet(identifiant: String) = "$BASE_URL/bracelets/status/$identifiant"
}