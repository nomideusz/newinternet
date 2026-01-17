# New Internet - Caprover Deployment Guide

## Prerequisites

1. **Caprover installed** on your VPS
2. **Domain configured** and pointed to your Caprover instance
3. **Caprover CLI installed** locally: `npm install -g caprover`

## Environment Variables Required

Configure these in Caprover app settings (App Configs → Environment Variables):

### Core Rails Configuration

```
RAILS_ENV=production
SECRET_KEY_BASE=<generate with: openssl rand -hex 64>
WEBAUTHN_ORIGIN=https://your-domain.com
WEBAUTHN_RP_ID=your-domain.com
```

### Database (if using external PostgreSQL)

```
DATABASE_URL=postgresql://user:password@host:5432/dbname
```

### Optional: Sentry (Error Tracking)

```
SENTRY_DSN=your-sentry-dsn
```

## Deployment Steps

### 1. Initialize Caprover App

```bash
# Login to your Caprover instance
caprover login

# Create the app (one-time)
caprover apps:create newinternet

# Configure persistent storage for SQLite database
# In Caprover UI:
# App Configs → Persistent Directories → Add:
# Path in App: /rails/storage
# Label: database-storage
```

### 2. Configure Environment

In Caprover UI (App Configs → Environment Variables), add all required variables above.

### 3. Enable HTTPS

In Caprover UI:

- HTTP Settings → Enable HTTPS
- Force HTTPS by Default → ON

### 4. Deploy

```bash
# From project root
caprover deploy

# Or deploy from git
git add .
git commit -m "Prepare for Caprover deployment"
git push origin main
caprover deploy -b main
```

### 5. Run Database Migrations

After first deployment:

```bash
# SSH into the container
caprover exec newinternet

# Run migrations
bin/rails db:migrate

# Exit container
exit
```

## Post-Deployment

### Access the app

Visit https://newinternet.your-domain.com

### First Run Setup

The first time you visit, you'll see the WebAuthn registration screen to create your admin account.

## Updating the App

```bash
# Make changes locally
git add .
git commit -m "Your changes"
git push origin main

# Deploy
caprover deploy

# If migrations needed:
caprover exec newinternet
bin/rails db:migrate
exit
```

## Monitoring

### View Logs

```bash
caprover logs newinternet -f
```

### Restart App

In Caprover UI: App Configs → Save & Update (forces restart)

## Scaling

Caprover doesn't support multiple container instances out of the box. For scaling:

1. **Vertical scaling**: Increase container resources in App Configs
2. **External services**:
   - Use managed PostgreSQL instead of SQLite
   - Use managed Redis (e.g., Redis Cloud)
   - Configure via `DATABASE_URL` and `REDIS_URL`

## Troubleshooting

### App won't start

- Check logs: `caprover logs newinternet -f`
- Verify all environment variables are set
- Ensure SECRET_KEY_BASE is set

### Database issues

- Check persistent directory is mounted: `/rails/storage`
- Run migrations: `caprover exec newinternet` → `bin/rails db:migrate`

### WebAuthn not working

- Ensure HTTPS is enabled
- Verify `WEBAUTHN_ORIGIN` matches your domain (https://...)
- Verify `WEBAUTHN_RP_ID` matches your domain (without https://)

## Production Checklist

- [ ] SECRET_KEY_BASE generated and set
- [ ] HTTPS enabled and forced
- [ ] WEBAUTHN_ORIGIN and WEBAUTHN_RP_ID configured
- [ ] Persistent storage mounted at `/rails/storage`
- [ ] Database migrations run
- [ ] First admin account created
- [ ] Logs monitored for errors
- [ ] Backup strategy for `/rails/storage` directory
