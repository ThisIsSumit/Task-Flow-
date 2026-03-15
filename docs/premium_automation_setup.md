# Task Automation Setup

## Product behavior

Task automation is available only to users with an active premium subscription. When a task remains pending and reaches the configured trigger window before its deadline, Task Flow runs the configured action automatically and writes an execution log.

Free users can still create and manage tasks, but they cannot enable task automation settings.

Premium users can:

- Enable per-task automation
- Choose execution type (`email`, `report`, `message`, `meeting`)
- Configure trigger time before deadline

## Firestore schema

### `users/{userId}`

- `userId`: string
- `email`: string
- `subscriptionType`: `free` | `premium`
- `subscriptionStartDate`: timestamp | null
- `subscriptionEndDate`: timestamp | null

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
- `executionType`: `email` | `report` | `message` | `meeting`
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
- `actionType`: `email` | `report` | `message` | `meeting`
- `executionType`: `email` | `report` | `message` | `meeting`
- `generatedContent`: string
- `executionTime`: timestamp
- `status`: `success` | `failed`

## Cloud Function pipeline

`runTaskAutomation` runs every 5 minutes and performs this pipeline:

1. Query tasks where `autoExecute == true` and `status == pending`
2. Check if task is still pending
3. Compute `deadline - triggerBeforeDeadline`
4. Check user subscription (`subscriptionType == premium` and not expired)
5. If current time is within trigger window, run action executor
6. Store execution result in `automation_logs`
7. Disable automation and mark task completed on success

## Action executors

Supported execution actions:

- `email`: sends templated (or AI-generated when configured) content to recipient
- `report`: generates a structured task report
- `message`: generates an automated pending-task message
- `meeting`: generates a meeting link and optionally sends push notification

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

## Recommended folder structure

Use this module layout to keep subscription and automation code scalable:

```text
lib/
  data/
    models/
      task_model.dart
      user_models.dart
      automation_log_model.dart
    services/
      firestore_service.dart
      subscription_service.dart
  controllers/
    home_controller.dart
  modules/
    home_view.dart
    automation_view.dart
    subscription_view.dart
functions/
  src/
    index.js         # scheduler entry and orchestration
    executors.js     # action dispatch + integration calls
    templates.js     # text/template builders for actions
docs/
  premium_automation_setup.md
```

If the automation surface grows, split Cloud Functions further into:

- `functions/src/services/subscriptionValidator.js`
- `functions/src/services/loggingService.js`
- `functions/src/executors/emailExecutor.js`
- `functions/src/executors/reportExecutor.js`
- `functions/src/executors/messageExecutor.js`
- `functions/src/executors/meetingExecutor.js`

## AI Copilot Automation

### Feature summary

AI Copilot Automation is a premium-only feature that lets users provide a natural language instruction and generate structured task plans.

Flutter flow:

1. User opens AI Copilot screen from Home.
2. User enters natural language instruction.
3. App calls callable function `generateTasksWithAI`.
4. Function validates auth, premium status, and daily rate limit.
5. Function calls AI provider and returns validated JSON tasks.
6. App shows generated plan preview screen.
7. User edits (optional) and saves tasks to Firestore.

### Callable Cloud Function

`generateTasksWithAI` in `functions/src/copilot.js`:

- Requires `request.auth.uid`
- Verifies premium subscription (`subscriptionType == premium`, not expired)
- Enforces per-user daily quota (`users/{uid}/usage/copilot_daily`)
- Calls AI provider (`gemini` by default, `openai` optional)
- Validates and sanitizes AI JSON before returning

### AI response shape

```json
{
  "tasks": [
    {
      "title": "Prepare Weekly Report",
      "description": "Compile weekly progress report",
      "deadline": "2026-03-20T17:00:00Z",
      "repeat": "weekly",
      "reminderMinutesBefore": 30,
      "subtasks": ["Collect updates", "Draft report", "Review"],
      "automation": {
        "enabled": true,
        "executionType": "email",
        "triggerBeforeDeadline": 10,
        "config": {
          "recipientEmail": "manager@company.com",
          "subject": "Weekly Report",
          "template": "weekly_report"
        }
      }
    }
  ]
}
```

### Firestore writes from Copilot save

For compatibility with existing scheduler and new schema needs, saved task docs include both:

- Existing scheduler fields: `autoExecute`, `executionType`, `triggerBeforeDeadline`, `recipient`, `status`
- New nested object: `automation { enabled, executionType, triggerBeforeDeadline, config }`
- Copilot metadata: `repeat` and generated subtasks

### Added Flutter files

- `lib/features/copilot/models/ai_task_model.dart`
- `lib/features/copilot/services/copilot_service.dart`
- `lib/features/copilot/controllers/copilot_controller.dart`
- `lib/features/copilot/screens/copilot_input_screen.dart`
- `lib/features/copilot/screens/copilot_preview_screen.dart`
- `lib/bindings/copilot_binding.dart`

### Added Functions files

- `functions/src/copilot.js`

### New routes

- `Routes.COPILOT_INPUT`
- `Routes.COPILOT_PREVIEW`

### Environment variables for Copilot

- `AI_PROVIDER` (`gemini` or `openai`)
- `COPILOT_DAILY_LIMIT` (default 20)
- For Gemini: `GEMINI_API_KEY`
- For OpenAI: `OPENAI_API_KEY`, optional `OPENAI_MODEL`
