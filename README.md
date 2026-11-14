# MediAlert

A medication adherence system for elderly users. Reminders and one-tap dose confirmation run through a Telegram bot, a web view shows today's doses and the caregiver dashboard, and an append-only audit log records every change to a schedule.

MediAlert is a reminder tool. It is not medical advice and does not replace a doctor or pharmacist.

## Status

Repository skeleton. Day 1 of the MediWeek plan (`mediweek-plan-v4-telegram.md`) builds on this.

## Layout

```
medialert/
  backend/     Node.js + TypeScript API, Telegram webhook, scheduler endpoint
  frontend/    React + Vite web view for patients and caregivers
  docs/        API notes, architecture diagram, evaluation results
```

## Stack

Backend: Node.js, TypeScript, PostgreSQL (Neon or Supabase free tier).
Frontend: React, Vite.
Channel: Telegram Bot API (free, no DLT registration needed).
Scheduling: Upstash QStash calls `POST /api/process-reminders` every 5 minutes.
Prescription reading: local open-source vision model via Ollama in production; a free vision API only for development with synthetic prescriptions.

## Getting started

Requires Node.js 20 or later and PostgreSQL.

```bash
cp backend/.env.example backend/.env   # fill in values; never commit .env
npm install
npm run dev
```

## Environment

Secrets live in environment variables only. See `backend/.env.example` for the full list. Never log message text, medicine names, or chat IDs.

## Privacy

Telegram delivers messages, and bot chats are not end-to-end encrypted. The consent step in the bot says so. Account deletion and data export are planned for Day 6.
