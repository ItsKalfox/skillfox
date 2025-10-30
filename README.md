# Skill Fox 🦊

A full-stack web application for user authentication and learning progress tracking.

## Tech Stack

- **Frontend:** React, Axios, Tailwind (or plain CSS)
- **Backend:** Node.js, Express
- **Database:** MySQL (via XAMPP)
- **Version Control:** Git & GitHub

---

## Project Structure

```bash
skillfox/
├── backend/
│ ├── db/
│ │ ├── db.js
│ │ ├── audit.js
│ │ ├── schema.sql
│ │ └── seed.sql
│ ├── controllers/
│ │ └── authController.js
│ ├── routes/
│ │ └── authRoutes.js
│ └── server.js
└── frontend/
  ├── src/
  │ ├── api/
  │ ├── components/
  │ ├── pages/
  │ └── App.js
  └── public/
```

---

## Setup Instructions

### 1. Clone the Repo
```bash
git clone https://github.com/<username>/skillfox.git
cd skillfox
```
---
### 2. Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your local MySQL credentials
```
Create the database tables:
```bash
mysql -u <username> -p < backend/db/schema.sql
```
Start the backend server:
```bash
npm start
```
Server will run at http://localhost:5000

---

### 3. Frontend Setup
```bash
cd frontend
npm install
cp .env.example .env
# Update REACT_APP_API_URL if needed
npm start

```

## Branch Strategy

- **main:** production-ready
- **dev:** ongoing development
- **feature/name:** feature branches
- **fix/name:** bug fixes
---