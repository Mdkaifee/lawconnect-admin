# Rishikesh Law Hub — API (Node + Express + MongoDB)

Powers both the Flutter user app and the owner admin panel.

## Run locally

```bash
cd backend
cp .env.example .env    # fill MONGODB_URI + JWT_SECRET
npm install
npm run seed            # creates owner login Rishikesh / Rishikesh@1 + sample data
npm start               # http://localhost:4000
```

## Deploy on Render

- New Web Service → root directory `backend`
- Build command: `npm install`
- Start command: `npm start`
- Environment: `MONGODB_URI`, `JWT_SECRET`, `CORS_ORIGIN` (your admin panel URL(s), comma separated)
- After first deploy run `npm run seed` once (Render Shell) to create the owner login.

## Endpoints

Auth
- `POST /api/auth/admin/login` `{ username, password }` → owner token
- `GET  /api/auth/admin/me`
- `POST /api/auth/admin/change-password`
- `POST /api/auth/register` / `POST /api/auth/login` / `GET,PUT /api/auth/me` (app users)

Content (GET public, write = admin token)
- `GET/POST /api/cases`, `GET/PUT/DELETE /api/cases/:id` — search by `q`, `court`, `year`, `category`, `tag`
- `GET/POST /api/acts`, `GET/PUT/DELETE /api/acts/:id`, `GET /api/acts/search/sections?q=`
- `POST /api/acts/:id/sections`, `DELETE /api/acts/:id/sections/:sectionId`
- `GET/POST /api/updates`, `GET/PUT/DELETE /api/updates/:id`
- `GET /api/posts`, `POST /api/posts` (user), `POST /api/posts/admin`, `POST /api/posts/:id/like`, `PUT/DELETE /api/posts/:id` (admin)
- `GET/POST/PUT/DELETE /api/categories`

Per-user (app token)
- `/api/notes`, `/api/bookmarks`, `/api/history`

Admin only
- `/api/users` (list, update, delete), `/api/stats` (dashboard counts)

Add `?all=1` on list endpoints with an admin token to include unpublished items.
