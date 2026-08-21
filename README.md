# Application de gestion des invitations de mariage

## Audit au 19 août 2026

Le socle Laravel/Sanctum, les événements, invités, tokens QR, vérification transactionnelle, historique et scanner Flutter existaient déjà. Les compléments ajoutés sont la sélection réelle d'événement, les permissions par rôle, les statistiques enrichies, les filtres serveur, le CRUD événement Flutter, le partage de carte complète et la file offline sûre.

## Configuration Flutter

Les paramètres sont centralisés dans `mobile/lib/core/config/app_config.dart`.

Développement Android sur émulateur (surcharge facultative) :

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Développement sur téléphone physique connecté au même Wi-Fi que le PC :

```powershell
cd backend
php artisan serve --host=0.0.0.0 --port=8000
cd ..\mobile
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://11.11.11.244:8000/api
```

`11.11.11.244` est l’adresse Wi-Fi actuelle du PC et peut changer. Vérifiez-la avec `Get-NetIPAddress -AddressFamily IPv4`. Autorisez PHP sur le pare-feu Windows si le téléphone ne se connecte pas. Le HTTP local est autorisé uniquement dans le manifeste Android debug ; une version release doit utiliser HTTPS.

Sans `API_BASE_URL`, l’application utilise actuellement `http://11.11.11.244:8000/api` en développement, ce qui permet aussi les essais sur téléphone physique.

Staging :

```powershell
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging-api.mon-domaine.com/api
```

Production :

```powershell
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.mon-domaine.com/api
```

L'identifiant d'événement n'est plus imposé par les widgets : il est récupéré depuis l'API et choisi après connexion. `EVENT_ID` reste uniquement un paramètre optionnel pour les extensions futures.

## Backend

```powershell
cd backend
copy .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

Pour MySQL, renseigner `DB_CONNECTION=mysql`, `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME` et `DB_PASSWORD` dans `backend/.env` avant `php artisan migrate`.

Comptes de développement seedés :

```text
admin@mariage.test / password
staff@mariage.test / password
```

## Mode hors ligne

Un scan sans connexion est placé dans une file locale et affiché comme « synchronisation en attente ». Flutter ne déclare jamais une invitation valide hors ligne. Les scans sont rejoués lorsque la connexion revient et Laravel reste l'autorité finale ; cette stratégie évite qu'un même QR soit validé localement par deux appareils hors ligne.

## Validation

- `php artisan test` : 10 tests réussis, 28 assertions
- `flutter analyze` : aucune erreur
- `flutter test` : tests réussis
- `php artisan route:list --path=api` : routes auth, événements, invités, vérification, statistiques et historique présentes

Avant production : configurer HTTPS, MySQL, CORS, clés/secrets, sauvegardes, monitoring, comptes réels et domaine API. Tester deux appareils simultanés sur la même invitation en environnement de staging.
