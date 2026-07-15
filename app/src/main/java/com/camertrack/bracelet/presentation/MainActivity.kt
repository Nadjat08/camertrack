/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter to find the
 * most up to date changes to the libraries and their usages.
 */

package com.camertrack.bracelet.presentation

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.TimeText
import androidx.wear.tooling.preview.devices.WearDevices
import com.camertrack.bracelet.data.BraceletApiClient
import com.camertrack.bracelet.data.BraceletIdentity
import com.camertrack.bracelet.data.TokenStore
import com.camertrack.bracelet.presentation.theme.CamerTrackBraceletTheme
import com.camertrack.bracelet.service.TrackerService
import com.camertrack.bracelet.util.LocationHelper
import com.camertrack.bracelet.util.QrCodeGenerator
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()

        super.onCreate(savedInstanceState)

        setTheme(android.R.style.Theme_DeviceDefault)

        setContent {
            WearApp()
        }
    }
}

/**
 * Liste des permissions à demander à l'exécution.
 */
private fun permissionsRequises(): Array<String> {
    val permissions = mutableListOf(
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION
    )
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        permissions.add(Manifest.permission.POST_NOTIFICATIONS)
    }
    return permissions.toTypedArray()
}

@Composable
fun WearApp() {
    val context = LocalContext.current
    val scopeSos = rememberCoroutineScope()

    val identifiant = remember { BraceletIdentity.getOrCreateIdentifiant(context) }

    val qrBitmap = remember(identifiant) {
        QrCodeGenerator.generer(identifiant, 200).asImageBitmap()
    }

    var statutTexte by remember { mutableStateOf("Enregistrement...") }
    var dejaProvisionne by remember { mutableStateOf(TokenStore.aDesTokens(context)) }
    var permissionsAccordees by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED
        )
    }

    val lanceurPermissions = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { resultats ->
        permissionsAccordees = resultats[Manifest.permission.ACCESS_FINE_LOCATION] == true
    }

    LaunchedEffect(Unit) {
        if (!permissionsAccordees) {
            lanceurPermissions.launch(permissionsRequises())
        }
    }

    LaunchedEffect(dejaProvisionne, permissionsAccordees) {
        if (dejaProvisionne && permissionsAccordees) {
            val intent = Intent(context, TrackerService::class.java)
            ContextCompat.startForegroundService(context, intent)
        }
    }

    LaunchedEffect(identifiant) {
        if (dejaProvisionne) {
            statutTexte = "Provisionné ✓"
            return@LaunchedEffect
        }

        val braceletId = BraceletApiClient.enregistrerBracelet(identifiant)
        if (braceletId == null) {
            statutTexte = "Erreur réseau"
            return@LaunchedEffect
        }

        statutTexte = "En attente du scan..."
        while (true) {
            val resultat = BraceletApiClient.statutBracelet(identifiant)

            when (resultat.status) {
                "WAITING" -> {
                    statutTexte = "En attente du scan..."
                }
                "ASSOCIATED" -> {
                    if (resultat.accessToken != null && resultat.refreshToken != null) {
                        TokenStore.sauvegarderTokens(
                            context,
                            resultat.accessToken,
                            resultat.refreshToken
                        )
                    }
                    statutTexte = "Associé ✓"
                    dejaProvisionne = true
                    return@LaunchedEffect
                }
                "PROVISIONED" -> {
                    statutTexte = "Provisionné ✓"
                    dejaProvisionne = true
                    return@LaunchedEffect
                }
                else -> {
                    statutTexte = "Erreur de connexion"
                }
            }

            delay(3000)
        }
    }

    // --- Bouton SOS : appui maintenu 3 secondes ---
    val interactionSourceSos = remember { MutableInteractionSource() }
    val sosPresse by interactionSourceSos.collectIsPressedAsState()
    var sosProgression by remember { mutableStateOf(0f) }
    var sosStatutTexte by remember { mutableStateOf("") }
    var sosEnvoiEnCours by remember { mutableStateOf(false) }

    LaunchedEffect(sosPresse) {
        if (sosPresse) {
            val dureeMs = 3000L
            val pasMs = 50L
            var ecouleMs = 0L
            while (ecouleMs < dureeMs) {
                delay(pasMs)
                ecouleMs += pasMs
                sosProgression = ecouleMs / dureeMs.toFloat()
            }
            // Toujours pressé après les 3 secondes (sinon cet effet aurait été annulé
            // automatiquement par le changement de clé sosPresse)
            sosProgression = 0f
            scopeSos.launch {
                declencherSos(
                    context = context,
                    onStatutChange = { sosStatutTexte = it },
                    onEnvoiEnCours = { sosEnvoiEnCours = it }
                )
            }
        } else {
            sosProgression = 0f
        }
    }

    CamerTrackBraceletTheme {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colors.background),
            contentAlignment = Alignment.Center
        ) {
            TimeText()

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                if (dejaProvisionne) {
                    // Une fois provisionné, on affiche le bouton SOS plutôt que le QR
                    Text(
                        text = "CamerTrack",
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colors.primary,
                        fontSize = 12.sp
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Button(
                        onClick = { /* déclenchement géré par interactionSource + appui maintenu */ },
                        interactionSource = interactionSourceSos,
                        enabled = !sosEnvoiEnCours,
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = MaterialTheme.colors.error
                        ),
                        modifier = Modifier.size(70.dp)
                    ) {
                        Text(
                            text = if (sosEnvoiEnCours) "..." else "SOS",
                            fontSize = 16.sp
                        )
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    if (sosProgression > 0f) {
                        Text(
                            text = "Maintenir... ${(sosProgression * 100).toInt()}%",
                            fontSize = 9.sp,
                            color = MaterialTheme.colors.onBackground
                        )
                    } else if (sosStatutTexte.isNotEmpty()) {
                        Text(
                            text = sosStatutTexte,
                            fontSize = 9.sp,
                            color = MaterialTheme.colors.secondary
                        )
                    } else {
                        Text(
                            text = "Maintenir 3s en cas d'urgence",
                            fontSize = 8.sp,
                            color = MaterialTheme.colors.onBackground
                        )
                    }
                } else {
                    Text(
                        text = "Scannez-moi",
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colors.primary,
                        fontSize = 12.sp
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Image(
                        bitmap = qrBitmap,
                        contentDescription = "QR code d'association du bracelet"
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = identifiant,
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colors.onBackground,
                        fontSize = 9.sp
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = statutTexte,
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colors.secondary,
                        fontSize = 9.sp
                    )
                }
            }
        }
    }
}

/**
 * Récupère la position actuelle et déclenche l'envoi de l'alerte SOS.
 */
private suspend fun declencherSos(
    context: android.content.Context,
    onStatutChange: (String) -> Unit,
    onEnvoiEnCours: (Boolean) -> Unit
) {
    val accessToken = TokenStore.getAccessToken(context)
    if (accessToken == null) {
        onStatutChange("Erreur : non provisionné")
        return
    }

    val permissionAccordee = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED

    if (!permissionAccordee) {
        onStatutChange("Erreur : permission GPS manquante")
        return
    }

    onEnvoiEnCours(true)
    onStatutChange("Envoi du SOS...")

    val position = LocationHelper.obtenirDernierePosition(context)
    if (position == null) {
        onEnvoiEnCours(false)
        onStatutChange("Erreur : position indisponible")
        return
    }

    val succes = BraceletApiClient.syncSos(
        accessToken = accessToken,
        latitude = position.latitude,
        longitude = position.longitude,
        precision = position.accuracy,
        severity = "HIGH"
    )

    onEnvoiEnCours(false)
    onStatutChange(if (succes) "SOS envoyé ✓" else "Erreur d'envoi du SOS")
}

@Preview(device = WearDevices.SMALL_ROUND, showSystemUi = true)
@Composable
fun DefaultPreview() {
    WearApp()
}