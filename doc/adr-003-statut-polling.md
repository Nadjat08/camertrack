# ADR-003 — Cycle de statut WAITING → ASSOCIATED → PROVISIONED

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

Le moteur CamerTrack utilise un mécanisme de **polling** (`GET /api/bracelets/status/:uuid`) pour savoir si le parent a scanné le QR Code et si le bracelet peut démarrer. Trois états ont été identifiés :

1. Le bracelet vient de s'enregistrer mais aucun parent n'a encore scanné.
2. Le parent a scanné et le bracelet doit récupérer ses tokens **une seule fois**.
3. Le bracelet a déjà récupéré ses tokens et le moteur a redémarré (retry de polling).

Sans distinguer les états 2 et 3, le serveur renverrait les tokens à chaque appel de polling, ce qui :
- Exposerait inutilement les tokens sur le réseau.
- Rendrait difficile la détection d'une tentative d'interception (le token change à chaque poll).

## Décision

Introduire un champ booléen `provisioned` en base sur la table `bracelets`, et gérer trois états dans `statutBracelet()` :

| État | Condition | Réponse |
|---|---|---|
| `WAITING` | `group_id IS NULL` | `{ status: "WAITING" }` |
| `ASSOCIATED` | `group_id IS NOT NULL AND provisioned = false` | `{ status: "ASSOCIATED", accessToken, refreshToken }` + marquage `provisioned = true` |
| `PROVISIONED` | `group_id IS NOT NULL AND provisioned = true` | `{ status: "PROVISIONED" }` |

Les tokens ne sont générés et transmis **qu'une seule fois** lors du passage à `ASSOCIATED`.

## Conséquences

**Positives :**
- Les tokens ne transitent qu'une seule fois sur le réseau.
- Le moteur peut distinguer "je dois attendre" de "j'ai raté les tokens et dois me re-provisionner".
- Alignement avec ce que le `RegistrationManager` du moteur attend déjà.

**Négatives :**
- Si la montre reçoit `ASSOCIATED` mais crashe avant de sauvegarder les tokens, elle ne peut plus les récupérer par ce canal. Solution : la montre devra se re-provisionner (réinitialisation du `provisioned` à `false` via un mécanisme de reset non implémenté dans ce sprint).
