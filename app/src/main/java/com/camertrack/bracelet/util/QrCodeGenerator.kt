package com.camertrack.bracelet.util

import android.graphics.Bitmap
import android.graphics.Color
import com.google.zxing.BarcodeFormat
import com.google.zxing.MultiFormatWriter
import com.google.zxing.common.BitMatrix

/**
 * Génère une image de QR code (Bitmap) à partir d'une chaîne de texte,
 * sans dépendance à la caméra (la montre n'a besoin que d'afficher le code,
 * pas de le scanner).
 */
object QrCodeGenerator {

    fun generer(contenu: String, taille: Int = 200): Bitmap {
        val bitMatrix: BitMatrix = MultiFormatWriter().encode(
            contenu,
            BarcodeFormat.QR_CODE,
            taille,
            taille
        )

        val bitmap = Bitmap.createBitmap(taille, taille, Bitmap.Config.RGB_565)
        for (x in 0 until taille) {
            for (y in 0 until taille) {
                bitmap.setPixel(x, y, if (bitMatrix[x, y]) Color.BLACK else Color.WHITE)
            }
        }
        return bitmap
    }
}