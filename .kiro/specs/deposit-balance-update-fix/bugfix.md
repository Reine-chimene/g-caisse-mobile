# Bugfix Requirements Document

## Introduction

Ce document décrit le bug affectant la mise à jour automatique du solde utilisateur après un dépôt via Notch Pay dans l'application G-Caisse. Actuellement, lorsqu'un utilisateur effectue un dépôt et clique sur "J'AI PAYÉ - VÉRIFIER", le solde ne se met pas à jour correctement, obligeant l'utilisateur à rafraîchir manuellement ou à attendre.

Le bug impacte l'expérience utilisateur en créant de la confusion sur l'état réel du compte après un paiement réussi.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN un utilisateur initie un dépôt via `initiatePayment()` et complète le paiement sur Notch Pay, puis clique sur "J'AI PAYÉ - VÉRIFIER" THEN le système vérifie le statut via `checkDepositStatus()` mais le solde affiché ne se met pas à jour automatiquement même si le paiement est confirmé

1.2 WHEN la vérification via `checkDepositStatus()` retourne un statut "pending" ou autre que "complete" THEN le système appelle `verifyDeposits()` mais n'actualise pas l'interface utilisateur avec le nouveau solde retourné

1.3 WHEN l'utilisateur ferme le dialogue de vérification après avoir cliqué sur "J'AI PAYÉ - VÉRIFIER" THEN le solde affiché dans la carte de balance reste inchangé même si le backend a crédité le compte

1.4 WHEN plusieurs tentatives de vérification sont effectuées (retry loop avec 3 tentatives) THEN le système ne met pas à jour l'état local `totalBalance` avec les données reçues du backend

### Expected Behavior (Correct)

2.1 WHEN un utilisateur clique sur "J'AI PAYÉ - VÉRIFIER" et que le paiement est confirmé par Notch Pay (statut "complete") THEN le système SHALL mettre à jour immédiatement le solde affiché dans l'interface utilisateur avec le montant crédité

2.2 WHEN la vérification via `checkDepositStatus()` retourne un statut autre que "complete" THEN le système SHALL appeler `verifyDeposits()` et mettre à jour le solde affiché avec la valeur `balance` retournée par cette API

2.3 WHEN l'utilisateur ferme le dialogue de vérification THEN le système SHALL rafraîchir automatiquement les données via `_loadData()` pour afficher le solde mis à jour

2.4 WHEN le backend crédite le compte utilisateur (via `/api/deposit/status/:reference` ou `/api/deposit/verify/:userId`) THEN le frontend SHALL récupérer et afficher le nouveau solde sans nécessiter une action manuelle de l'utilisateur

### Unchanged Behavior (Regression Prevention)

3.1 WHEN un utilisateur initie un dépôt et que le paiement est en cours (statut "pending" sur Notch Pay) THEN le système SHALL CONTINUE TO afficher le message "Le paiement est en cours de traitement" sans créditer le compte

3.2 WHEN un utilisateur clique sur le bouton de rafraîchissement manuel du solde THEN le système SHALL CONTINUE TO appeler `_loadData()` et mettre à jour l'affichage correctement

3.3 WHEN un utilisateur effectue un retrait, transfert ou autre opération financière THEN le système SHALL CONTINUE TO mettre à jour le solde automatiquement comme prévu

3.4 WHEN l'application revient au premier plan (AppLifecycleState.resumed) THEN le système SHALL CONTINUE TO recharger automatiquement les données via `_loadData()`

3.5 WHEN un utilisateur effectue un "pull-to-refresh" sur l'écran d'accueil THEN le système SHALL CONTINUE TO rafraîchir le solde et les autres données correctement
