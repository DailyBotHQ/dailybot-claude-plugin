# Report Examples

Side-by-side comparisons of bad vs good reports. Use these as a reference when composing reports.

## Plain Reports (message only)

### 1. Feature Implementation

**Bad:** `Work in progress: 3 files modified (app/followups/services/bot_flow_serializers/followup.py, app/followups/tasks/send_followup_late_reminder_task.py)`

**Good:** "Refactored followup notifications — managers now receive their full platform profile (avatar, contact info) instead of just a name string. This improves how manager data appears in followup reminders."

**Why it's better:** Explains the change AND its user-facing impact. No file paths.

---

### 2. Bug Fix

**Bad:** `fix(api): handle null timezone in user profile`

**Good:** "Fixed a bug where users without a timezone set would see errors on their profile page."

**Why it's better:** Describes the user-facing problem, not the code fix.

---

### 3. Frontend Change

**Bad:** `feat(home): add copy icon and click feedback to hero CLI pill — pushed to dev`

**Good:** "Added copy-to-clipboard functionality to the homepage CLI demo with visual click feedback for users."

**Why it's better:** No branch names. Describes what users experience.

---

### 4. Multiple Commits

**Bad:** `2 commits — latest: fix(api): handle null timezone in user profile`

**Good:** "Fixed a bug where users without a timezone set would see errors on their profile page."

**Why it's better:** One sentence about the outcome. Commit count is irrelevant.

---

### 5. Documentation

**Bad:** `Work in progress: 1 file modified (docs/technical/ARCHITECTURE_OVERVIEW.md)`

**Good:** "Updated the architecture documentation to reflect the new notification service integration."

**Why it's better:** Describes purpose, not filename.

---

### 6. Testing

**Bad:** `Agent completed testing work`

**Good:** "Added test coverage for the manager profile serializer — 15 test cases covering edge cases and platform variations."

**Why it's better:** Specific about what was tested and scope.

---

### 7. Refactoring

**Bad:** `refactor: clean up auth middleware`

**Good:** "Refactored the authentication middleware to centralize token validation — eliminates duplicated checks across 4 endpoints."

**Why it's better:** Explains WHY the refactor matters and its scope.

---

### 8. Dependencies

**Bad:** `3 commits — latest: chore: update dependencies`

**Good:** "Updated project dependencies to latest stable versions, including security patches for the HTTP client."

**Why it's better:** Explains why the update matters.

---

### 9. Performance

**Bad:** `perf: optimize dashboard query`

**Good:** "Optimized the dashboard loading query — page now loads in under 500ms instead of 3 seconds for large teams."

**Why it's better:** Includes measurable impact.

---

### 10. Configuration

**Bad:** `Committed: ci: add e2e test step to pipeline`

**Good:** "Configured the CI pipeline for automated browser tests — PRs now get E2E test results before merge."

**Why it's better:** Describes the outcome for the team.

---

## Rich Reports (with structured data and/or milestone)

### 11. Major Feature (milestone + structured data)

**Bad:**
```bash
dailybot agent update "Completed development work and all tests pass" --name "claude-code"
```

**Good:**
```bash
dailybot agent update \
  "Built the notification preferences system — users can now configure which alerts they receive and through which channels (email, in-app, Slack)." \
  --name "claude-code" \
  --milestone \
  --json-data '{"completed":["Preferences data model","REST API endpoints (CRUD)","Email channel integration","Slack channel integration","User settings UI","Test suite (32 cases)"],"in_progress":[],"blockers":[]}' \
  --metadata '{"repo":"web-app","branch":"feature/notifications","agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Describes what users get, lists all deliverables, marks as milestone.

---

### 12. Multi-Step Task Completion (milestone + structured data)

**Bad:**
```bash
dailybot agent update "Completed a deep work plan with multiple tasks executed and validated" \
  --name "claude-code" --milestone
```

**Good:**
```bash
dailybot agent update \
  "Completed the auth refactor — JWT tokens now work across all services with centralized middleware validation, eliminating per-service token handling." \
  --name "claude-code" \
  --milestone \
  --json-data '{"completed":["JWT middleware implementation","Token validation service","Session migration script","Integration tests (24 cases)","API documentation update"],"in_progress":[],"blockers":[]}' \
  --metadata '{"repo":"api-services","branch":"feature/auth","agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Describes the outcome (not the process), lists every deliverable, plan name is absent from message.

---

### 13. Feature with Blockers (structured data, no milestone)

**Bad:**
```bash
dailybot agent update "Working on deployment, having some issues" --name "claude-code"
```

**Good:**
```bash
dailybot agent update \
  "Implemented the staging deployment pipeline — builds and tests are automated, but the final deploy step is blocked by a Docker image issue." \
  --name "claude-code" \
  --json-data '{"completed":["Build automation","Test runner integration","Environment configuration"],"in_progress":["Deploy step automation"],"blockers":["Docker base image missing libpq-dev — needs infrastructure team to update"]}' \
  --metadata '{"repo":"api-services","branch":"feature/deploy","agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Clear about what's done, what's pending, and exactly what's blocking progress.

---

### 14. Deployment (milestone, no structured data)

**Bad:**
```bash
dailybot agent update "Deployed to production" --name "claude-code" --milestone
```

**Good:**
```bash
dailybot agent update \
  "Deployed the new billing system to production — subscription management is now fully automated with Stripe webhook handling." \
  --name "claude-code" \
  --milestone \
  --metadata '{"repo":"billing-service","branch":"main","agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Says WHAT was deployed and what it means for the product.

---

### 15. Non-Code Work (analysis/research)

**Bad:**
```bash
dailybot agent update "Completed analysis" --name "claude-code"
```

**Good:**
```bash
dailybot agent update \
  "Completed the API performance audit — identified 3 N+1 query issues and a missing database index that account for 80% of p95 latency. Documented findings with fix recommendations." \
  --name "claude-code" \
  --json-data '{"completed":["Query analysis across 12 endpoints","N+1 detection and documentation","Missing index identification","Fix recommendation document"],"in_progress":[],"blockers":[]}' \
  --metadata '{"repo":"api-services","branch":"main","agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Specific findings, quantified impact, clear deliverables — even though no code was written.

---

### 16. Product Spec / PRD (structured data, no milestone)

**Bad:**
```bash
dailybot agent update "Worked on product requirements" --name "claude-code"
```

**Good:**
```bash
dailybot agent update \
  "Drafted the product requirements for the team notifications feature — covers user stories, acceptance criteria, and edge cases for cross-platform delivery (email, Slack, in-app)." \
  --name "claude-code" \
  --json-data '{"completed":["User story mapping (8 stories)","Acceptance criteria for each story","Edge case documentation","Cross-platform delivery matrix"],"in_progress":["Stakeholder review"],"blockers":[]}' \
  --metadata '{"agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Describes the deliverable and its scope. No code involved — metadata has no repo/branch because this isn't a git project.

---

### 17. Competitive Analysis / Research

**Bad:**
```bash
dailybot agent update "Did some research on competitors" --name "claude-code"
```

**Good:**
```bash
dailybot agent update \
  "Completed competitive analysis of 5 workflow automation tools — documented feature gaps, pricing comparison, and positioning recommendations for the Q3 strategy review." \
  --name "claude-code" \
  --metadata '{"agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Says what was analyzed, the scope (5 tools), and what it feeds into (Q3 strategy). Plain report is fine here — single deliverable.

---

### 18. Process Design / Workflow

**Bad:**
```bash
dailybot agent update "Designed a new process" --name "claude-code"
```

**Good:**
```bash
dailybot agent update \
  "Designed the new customer onboarding workflow — mapped 6 stages from signup to first value, defined handoff points between sales and CS, and documented SLA targets for each stage." \
  --name "claude-code" \
  --json-data '{"completed":["6-stage workflow map","Sales-to-CS handoff definitions","SLA targets per stage","Exception handling paths"],"in_progress":[],"blockers":[]}' \
  --metadata '{"agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Specific about the workflow scope, the handoffs, and what was produced.

---

### 19. Content / Communication

**Bad:**
```bash
dailybot agent update "Wrote some content" --name "claude-code"
```

**Good:**
```bash
dailybot agent update \
  "Drafted the Q3 investor update — covers revenue growth, product milestones, and the hiring roadmap. Ready for founder review." \
  --name "claude-code" \
  --metadata '{"agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}'
```

**Why it's better:** Names the specific document, what it covers, and its current status.

---

## Quick Reference: The Standup Test

Before sending any report, ask: *"Would I say this in a real standup with my team?"*

| Report | Standup-worthy? |
|--------|:-:|
| "Implemented the notification preferences system" | Yes |
| "Fixed a typo in a test file" | No |
| "Deployed the new auth middleware to staging" | Yes |
| "Updated a lockfile" | No |
| "Built the user preferences API with full test coverage" | Yes |
| "Read some code and explored the codebase" | No |
| "Completed the 8-task auth refactor with JWT across all services" | Yes |
| "3 files modified" | No |
| "Drafted the Q3 product roadmap with prioritized initiatives" | Yes |
| "Read a few articles about competitors" | No |
| "Completed competitive analysis with positioning recommendations" | Yes |
| "Had a brainstorming conversation with no conclusions" | No |
