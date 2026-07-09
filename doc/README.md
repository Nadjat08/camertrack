# Architecture Decision Records — CamerTrack Backend

Ce dossier documente les décisions d'architecture prises lors du **Sprint Backend 1 (Authentification & Provisioning)** afin de rendre le backend compatible avec le moteur CamerTrack (WearOS/Android).

Chaque ADR suit le format standard :
- **Statut** : Proposed / Accepted / Deprecated
- **Contexte** : Pourquoi cette décision a été nécessaire
- **Décision** : Ce qui a été choisi
- **Conséquences** : Impacts positifs et négatifs

## Liste des ADRs

| N°  | Titre                                              | Statut   |
|-----|----------------------------------------------------|----------|
| 001 | [Séparation des tokens utilisateur et bracelet](./adr-001-separation-tokens.md)      | Accepted |
| 002 | [Provisioning par UPSERT](./adr-002-upsert-provisioning.md)                          | Accepted |
| 003 | [Cycle de statut WAITING → ASSOCIATED → PROVISIONED](./adr-003-statut-polling.md)   | Accepted |
| 004 | [Refresh token opaque stocké en base](./adr-004-refresh-token-opaque.md)             | Accepted |
| 005 | [Versioning des routes moteur sous /api/locations](./adr-005-versioning-routes.md)   | Accepted |
| 006 | [Table dédiée sos_alerts](./adr-006-table-sos-alerts.md)                             | Accepted |
| 007 | [Diffusion Socket.IO après sync batch](./adr-007-socket-io-sync.md)                  | Accepted |
| 008 | [Respect strict du DTO du moteur](./adr-008-dto-moteur.md)                           | Accepted |
