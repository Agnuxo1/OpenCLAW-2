---
name: book-marketing-agent-automation
description: "Cron jobs for 24/7 automated book marketing operations"
---

# Book Marketing Agent - Cron Automation Schedule

## Overview

This file defines automated jobs for the Book Marketing Agent to run 24/7.

## Daily Jobs

### 1. Morning Sales Check (6:00 AM)
```bash
cron add --name "Morning Sales Report" --cron "0 6 * * *" --message "Check overnight sales and rankings across all platforms. Generate morning report."
```

### 2. Social Media Morning Post (7:00 AM)
```bash
cron add --name "Morning Social Posts" --cron "0 7 * * *" --message "Post morning book recommendations and engaging content on Twitter, Instagram, and Facebook."
```

### 3. Email Newsletter (Tuesday 9:00 AM)
```bash
cron add --name "Weekly Newsletter" --cron "0 9 * * 2" --message "Send weekly newsletter to email subscribers with book updates and recommendations."
```

### 4. Midday Engagement (12:00 PM)
```bash
cron add --name "Midday Engagement" --cron "0 12 * * *" --message "Engage with readers on social media, respond to comments, and share user-generated content."
```

### 5. Afternoon Promotion (3:00 PM)
```bash
cron add --name "Afternoon Promotion" --cron "0 15 * * *" --message "Run advertising campaigns and post promotional content on all platforms."
```

### 6. Evening Review Response (6:00 PM)
```bash
cron add --name "Evening Review Response" --cron "0 18 * * *" --message "Respond to new reviews and comments across all platforms."
```

### 7. Daily Summary (9:00 PM)
```bash
cron add --name "Daily Marketing Summary" --cron "0 21 * * *" --message "Generate daily marketing summary report and plan tomorrow's priorities."
```

## Weekly Jobs

### Monday - Weekly Planning
```bash
cron add --name "Weekly Marketing Plan" --cron "0 8 * * 1" --message "Create weekly marketing plan, review performance metrics, and adjust strategies."
```

### Wednesday - Content Creation
```bash
cron add --name "Weekly Content Creation" --cron "0 10 * * 3" --message "Create new content assets: graphics, videos, blog posts for the week."
```

### Thursday - Influencer Outreach
```bash
cron add --name "Influencer Outreach" --cron "0 11 * * 4" --message "Reach out to book bloggers, reviewers, and influencers for promotions and reviews."
```

### Friday - Performance Review
```bash
cron add --name "Friday Performance Review" --cron "0 16 * * 5" --message "Analyze weekly performance across all channels and generate optimization recommendations."
```

## Monthly Jobs

### First Monday - Monthly Strategy
```bash
cron add --name "Monthly Strategy Review" --cron "0 9 1-7 * 1" --message "Monthly strategy review: analyze monthly metrics, adjust budgets, plan major campaigns."
```

### 15th of Month - Mid-Month Assessment
```bash
cron add --name "Mid-Month Assessment" --cron "0 10 15 * *" --message "Mid-month performance assessment and course correction if needed."
```

## Campaign-Specific Jobs

### New Release Launch (Run during launch week)
```bash
# Pre-launch countdown
cron add --name "Launch Countdown Day 7" --cron "0 9 * *" --message "Day 7 countdown: Release teaser content and countdown graphics."

# Launch day
cron add --name "Launch Day Blitz" --cron "0 8 * *" --message "LAUNCH DAY: Maximum promotion across all channels simultaneously."
```

### Seasonal Promotion (Run during sale periods)
```bash
cron add --name "Seasonal Sale Start" --cron "0 0 1 * *" --message "Start seasonal promotion: activate all sale campaigns and notifications."
```

### Free Book Promotion
```bash
cron add --name "Free Book Start" --cron "0 0 * *" --message "Begin free book promotion: activate all download links and email sequences."
```

## Monitoring Alerts (Immediate)

### Sales Alert Trigger
```bash
# Configure in-agent monitoring
if sales_drop > 20%:
    cron.add_immediate("Sales Investigation", "Investigate sales drop and recommend corrective actions")
```

### Review Alert Trigger
```bash
# Configure in-agent monitoring
if new_review.rating < 3.0:
    cron.add_immediate("Negative Review Response", "Draft and schedule response to negative review")
```

### Advertising Alert Trigger
```bash
# Configure in-agent monitoring
if adspend > daily_budget * 1.2:
    cron.add_immediate("Ad Spend Review", "Review and optimize advertising campaigns")
```

## How to Activate

### 1. Add Individual Cron Jobs
```bash
openclaw cron add --name "Morning Sales Report" --cron "0 6 * * *" --message "Check overnight sales and rankings across all platforms. Generate morning report." --session isolated
```

### 2. Create Heartbeat for Continuous Monitoring
```bash
# Add HEARTBEAT.md to workspace for 30-minute checks
# See HEARTBEAT.md in this skill directory
```

### 3. Enable Agent for 24/7 Operation
Configure the agent to use:
- `heartbeat: true` (enable heartbeats)
- `cron: enabled` (enable cron jobs)
- `timeout: high` (allow long-running tasks)

## Cron Job Management

### List Active Jobs
```bash
openclaw cron list
```

### Pause Jobs
```bash
openclaw cron pause <jobId>
```

### Resume Jobs
```bash
openclaw cron resume <jobId>
```

### Delete Jobs
```bash
openclaw cron delete <jobId>
```

## Emergency Procedures

### Pause All Marketing
```bash
openclaw cron pause --all
```

### Emergency Stop
```bash
# Use in agent
/exit
```

### Resume After Emergency
```bash
openclaw cron resume --all
```

## Performance Targets

Set these targets in agent memory:

```
Daily Targets:
- Sales: [X] books
- Revenue: $[Amount]
- Reviews: [X] new
- Social Engagement: [X] interactions

Weekly Targets:
- Email Opens: [X]%
- Ad ROI: [X]%
- New Followers: [X]

Monthly Targets:
- Books Sold: [X]
- Revenue: $[Amount]
- Library Placements: [X]
- Review Count: [X]
```
