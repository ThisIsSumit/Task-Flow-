# Premium Automation Setup

## Firestore schema

### `users/{userId}`

- `uid`: string
- `email`: string
- `name`: string
- `subscriptionType`: `free` | `premium`
- `subscriptionStartDate`: timestamp | null
- `subscriptionEndDate`: timestamp | null
- `taskStats`: map

### `users/{userId}/tasks/{taskId}`

- Existing fields remain unchanged.
- New automation fields:
  - `status`: `pending` | `completed`
  - `autoExecute`: boolean
  - `automationInstruction`: string (free-text goal for the agent)
  - `automationMode`: `suggest` | `execute`
  - `triggerBeforeDeadline`: number (minutes)
  - `automationStatus`: `enabled` | `disabled`
  - `automationLastExecutedAt`: timestamp | null
  - `generatedAutomationContent`: string | null
  - `generatedAutomationSummary`: string | null

### `automation_logs/{logId}`

- `taskId`: string
- `userId`: string
- `actionType`: string
- `summary`: string
- `mode`: `suggest` | `execute`
- `generatedContent`: string
- `executionTime`: timestamp
- `status`: `success` | `failed`

## Flutter app changes included

- Premium gating in the task form
- Paywall screen
- Subscription state on the user model
- In-app purchase service for Android/iOS
- Automation settings saved with tasks

## Mobile store setup

Configure these product IDs in Google Play Console / App Store Connect:

- `taskflow_premium_monthly`
- `taskflow_premium_yearly`

The Flutter client currently maps those IDs in [lib/data/services/subscription_service.dart](../lib/data/services/subscription_service.dart).

## Cloud Functions setup

1. Install the Firebase CLI if not already installed.
2. From the project root run:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

1. Optional for local testing:

```bash
cd functions
npm install
cd ..
firebase emulators:start --only functions
```

## Environment variables for email automation

Create `functions/.env` (you can copy from `functions/.env.example`) and add:

- `GEMINI_API_KEY`

Optional email delivery settings (only needed when the agent selects email in `execute` mode):

- `EMAIL_SMTP_HOST`
- `EMAIL_SMTP_PORT`
- `EMAIL_SMTP_USER`
- `EMAIL_SMTP_PASSWORD`
- `EMAIL_FROM`

For production, store these in a secure secret manager flow before deployment.

## Scheduling and behavior

- `runTaskAutomation` runs every 5 minutes.
- It scans tasks with automation enabled and pending status.
- It checks if the trigger time has passed.
- It verifies the user still has an active premium subscription.
- It sends task context and user instruction to Gemini.
- In `execute` mode, the task is completed after successful execution.
- In `suggest` mode, output is generated and saved, but task remains pending.
- On failure, automation is disabled and a failed log is written to avoid repeated retries.

## Recommended folder structure

```text
lib/
  data/
    models/
      task_model.dart
      user_models.dart
      automation_log_model.dart
    services/
      auth_service.dart
      firestore_service.dart
      notification_service.dart
      subscription_service.dart
  modules/
    home_view.dart
    subscription_view.dart
functions/
  src/
    index.js
    executors.js
    templates.js
docs/
  premium_automation_setup.md
```

## Production notes

- For real subscription validation, prefer server-side receipt verification or RevenueCat entitlements.
- The provided `in_app_purchase` flow is a client-first integration and should be hardened before launch.
- Cloud Functions collection group queries may require Firestore composite indexes once deployed.
