# Task Automation Setup

## Product behavior

Task automation is available to all users. When a task remains pending and reaches the configured trigger window before its deadline, Task Flow runs the configured action automatically and writes an execution log.

## Firestore schema

### `users/{userId}/tasks/{taskId}`

Core fields:

- `taskId` (document id)
- `userId`: string
- `title`: string
- `description`: string
- `dueDate`: timestamp
- `status`: `pending` | `completed`

Automation fields:

- `autoExecute`: boolean
- `executionType`: `email` | `report` | `message` | `notification`
- `triggerBeforeDeadline`: number (minutes)
- `recipient`: string
- `automationStatus`: `enabled` | `disabled`
- `automationLastExecutedAt`: timestamp | null
- `generatedAutomationSummary`: string
- `generatedAutomationContent`: string

### `automation_logs/{logId}`

- `logId` (document id)
- `taskId`: string
- `userId`: string
- `executionType`: `email` | `report` | `message` | `notification`
- `generatedContent`: string
- `executionTime`: timestamp
- `status`: `success` | `failed`

## Cloud Function pipeline

`runTaskAutomation` runs every 5 minutes and performs this pipeline:

1. Query tasks where `autoExecute == true` and `status == pending`
2. Check if task is still pending
3. Compute `deadline - triggerBeforeDeadline`
4. If current time is within trigger window, run action executor
5. Store execution result in `automation_logs`
6. Disable automation and mark task completed on success

## Action executors

Supported execution actions:

- `email`: sends templated (or AI-generated when configured) content to recipient
- `report`: generates a structured task report
- `message`: generates an automated pending-task message
- `notification`: sends push notification (with token) or logs reminder content

## Environment variables

Create `functions/.env` and configure as needed:

- Optional AI content generation:
  - `GEMINI_API_KEY`
- Required for `email` execution:
  - `EMAIL_SMTP_HOST`
  - `EMAIL_SMTP_PORT`
  - `EMAIL_SMTP_USER`
  - `EMAIL_SMTP_PASSWORD`
  - `EMAIL_FROM`

## Deploy functions

```bash
cd functions
npm install
firebase deploy --only functions
```

For emulator testing:

```bash
cd functions
npm install
firebase emulators:start --only functions
```
