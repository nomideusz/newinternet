# New Internet — Complete Project Handoff

> *Fresh, clean, people-oriented, network-oriented. Almost Buddhist.*

---

## For Claude Opus (or any AI assistant)

This document is a complete handoff for the **New Internet** project. It combines:
1. The project manifesto (philosophy, design language, values)
2. Technical vision and architecture decisions
3. Implementation roadmap and getting started guide

The project is based on **ONCE Campfire** by 37signals, an open-source group chat system (MIT license). We're rebuilding authentication from scratch using WebAuthn (passwordless) and adding novel features.

---

## Part 1: The Manifesto

### Core Philosophy

**New Internet** is an innovative project challenging old-school patterns. We propose something new—possibly better—while remaining intuitive for users accustomed to existing patterns.

New Internet is:
- **Friendly** — against violence, welcoming to all
- **People-oriented** — humans first, technology serves them
- **Network-oriented** — connections and communities at the center
- **Minimal** — as simple as possible, but not simpler

---

### Primary Focus: Groups

Groups are the main feature. Our priorities:
1. **Creating groups** — seamless, intuitive group creation (Spaces)
2. **Adding members** — frictionless invitations
3. **Building connections** — nurturing the network effect

---

### Design Language: Hey.com Inspired

Minimal, focused, no visual noise. Inspired by 37signals' Hey.com email.

| Principle | Description |
|-----------|-------------|
| **Radical Simplicity** | Remove everything that doesn't serve the user |
| **Content First** | UI fades into background, content takes center stage |
| **No Clutter** | No banners, no headers, no sidebars, no footers |
| **Intelligent Adaptation** | Interface responds to context without layout shifts |

### Navigation Structure

```
┌─────────────────────────────────────┐
│                        [Avatar ◯]   │  ← Top-right: user avatar
│                                     │
│           [ Content Area ]          │  ← Clean, full-width content
│                                     │
│                                     │
│            ┌─────────┐              │
│            │   ◯◯◯   │              │  ← Bottom-center: Navigation Hub
└────────────┴─────────┴──────────────┘
```

- **Navigation Hub** — Single radii element at bottom center, intelligently adapts to content
- **Avatar** — Top-right corner, opens user settings/profile
- **Sheets** — All modals/drawers appear from bottom (mobile-friendly, consistent)
- **No traditional nav** — No hamburger menus, no tab bars, no sidebars

### Content Philosophy

- **No helping texts** — we don't treat users like babies
- **Trust user intelligence** — guide through design, not words
- **Let the interface speak for itself**

---

### Values

| Principle | What it means |
|-----------|---------------|
| Friendly | Welcoming, safe, against violence |
| Fresh | Modern, innovative, forward-thinking |
| Fluid | Organic motion, springy interactions, depth |
| People-first | Human connections over engagement metrics |
| Network-first | Groups (Spaces) and connections are the product |

---

### Visual Identity

**Hey.com Inspired Palette** (colors TBD, principles defined):

| Element | Approach |
|---------|----------|
| **Background** | Clean white or pure black (OLED-friendly dark mode) |
| **Text** | High contrast, readable, minimal color |
| **Accent** | Single primary action color (to be decided) |
| **Surfaces** | Subtle, not distracting |

**Typography:** System fonts (SF Pro, Inter) for performance. Clear hierarchy, generous spacing.

**Motion:** Subtle, purposeful. No gratuitous animations.

---

### Anti-Patterns — What We Are NOT

| ❌ We avoid | Why |
|-------------|-----|
| **No "likes"** | Vanity metrics breed toxicity |
| **No marketing speak** | Authenticity over engagement |
| **No bullshit** | Honesty and clarity always |
| **No legacy patterns** | We break free from sidebars and static headers |
| **No dark patterns** | Respect user agency |
| **No ads, ever** | Non-profit, user-focused |
| **No cookie banners** | Zero tracking = GDPR exempt |

---

## Part 2: Confirmed Decisions

| Decision | Choice |
|----------|--------|
| **Username format** | Lowercase display, case-insensitive matching |
| **Recovery threshold** | 3 of 5 contacts required |
| **Visualization priority** | 1) User's connections, 2) 2nd-degree, 3) Group dynamics (future) |
| **Branding** | Keep "New Internet" name, colors TBD |
| **Deployment model** | Self-hosted, non-profit |
| **Federation** | Single instance to start (architecture allows future federation) |
| **Cookies/Banners** | Zero tracking cookies = no GDPR banner required |
| **Ads/Tracking** | None, ever |

---

## Part 3: Core Differentiators

### 1. 🔐 No Passwords, No Emails (WebAuthn Only)

**Traditional:**
```
User → Email → Password → Server validates
```

**New Internet:**
```
User → Device (Face ID, Touch ID, Security Key) → Cryptographic proof → Server validates
```

**User Flow:**
1. User visits newinternet.online
2. Enters desired username (lowercase, checked for uniqueness)
3. Device prompts for biometric/passkey creation
4. Account created — no email, no password ever stored

**Implementation:**
- `webauthn-ruby` gem for backend
- Store public keys, credential IDs, sign counts
- Username is the only identifier (like a handle)

---

### 2. 🤝 Recovery Connections (Social Recovery)

**The Problem:** Traditional recovery = email link = single point of failure

**Solution:** Recovery through trusted human connections.

**Flow:**
1. User designates 5 trusted recovery contacts
2. User loses device/passkey
3. Starts recovery from new device
4. System notifies contacts: "Jane wants to recover their account"
5. **3 of 5** contacts approve (via their own passkeys)
6. User creates new passkey on new device
7. Old credentials are revoked

**Future Enhancement:** Shamir's Secret Sharing for cryptographic key splitting.

---

### 3. 📱 Native Apps (iOS & Android)

**Approach: Hotwire Native (Turbo Native + Strada)**

```
Rails App (HTML/CSS/JS) 
    ↓
Hotwire Native (Swift/Kotlin shell)
    ↓
Native iOS/Android App
```

**Benefits:**
- One codebase (Rails) for web + mobile
- Instant updates without App Store approval
- Native features via Strada bridges (camera, push, biometrics)
- App Store presence for discoverability

---

### 4. 📊 Network Visualizations

**Priority Order:**
1. **User's Connections** — Who you're connected to
2. **2nd-Degree Connections** — Friends of friends
3. **Group Dynamics** — Room activity visualization (low priority, future)

**Technology:** D3.js with `d3-force` for force-directed graphs, integrated via Stimulus controllers.

---

### 5. ⚡ "Live" Feeling in Groups

**Goal:** Groups should feel alive — presence indicators, real-time updates, typing awareness.

**Implementation:**
- Action Cable (WebSockets) for real-time
- Turbo Streams for DOM updates without refresh
- Live presence indicators (who's active)
- Typing indicators
- Read receipts
- Real-time reactions

---

## Part 4: Technical Architecture

### Tech Stack

| Layer | Technology | Reasoning |
|-------|------------|-----------|
| **Backend** | Ruby on Rails 8 | Majestic Monolith, Hotwire native |
| **Frontend** | Hotwire (Turbo + Stimulus) | Server-rendered, minimal JS |
| **Database** | PostgreSQL | Production-ready, scalable |
| **Cache** | Solid Cache (Rails 8) | Built-in, no Redis needed |
| **Queue** | Solid Queue (Rails 8) | Built-in, no Sidekiq needed |
| **WebSockets** | Action Cable | Real-time via Turbo Streams |
| **Auth** | WebAuthn (webauthn-ruby) | Passwordless-first |
| **Mobile** | Hotwire Native + Strada | Native shells for iOS/Android |
| **Deployment** | Docker | Single container, self-hosted |
| **SSL** | Let's Encrypt (auto) | Built into Campfire deployment |

### Rails 8 Advantages

- **Solid Queue/Cache/Cable**: No external Redis/Sidekiq dependencies
- **Native WebAuthn support**: First-class passkey authentication
- **Hotwire 2.0**: Improved Turbo and Stimulus
- **Kamal 2**: Modern deployment

---

### Project Structure (Modified Campfire)

```
newinternet/
├── app/
│   ├── controllers/
│   │   ├── sessions_controller.rb      # REPLACE: WebAuthn auth
│   │   ├── registrations_controller.rb # NEW: WebAuthn registration
│   │   ├── recovery_controller.rb      # NEW: Recovery flow
│   │   └── api/
│   │       └── graphs_controller.rb    # NEW: Network visualization data
│   ├── models/
│   │   ├── user.rb                     # MODIFY: Remove password, add webauthn
│   │   ├── webauthn_credential.rb      # NEW: Store passkeys
│   │   ├── recovery_contact.rb         # NEW: Trusted contacts
│   │   └── recovery_request.rb         # NEW: Recovery flow state
│   ├── views/
│   │   ├── sessions/                   # REPLACE: WebAuthn login UI
│   │   ├── registrations/              # REPLACE: WebAuthn signup UI
│   │   └── graphs/                     # NEW: Visualization pages
│   └── javascript/
│       ├── controllers/
│       │   ├── webauthn_controller.js  # NEW: Credential ceremony
│       │   └── graph_controller.js     # NEW: D3.js integration
│       └── webauthn.js                 # NEW: Browser API wrapper
├── config/
│   └── initializers/
│       └── webauthn.rb                 # NEW: WebAuthn configuration
├── ios/                                # NEW: Hotwire Native iOS
└── android/                            # NEW: Hotwire Native Android
```

---

## Part 5: Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- Clone `basecamp/once-campfire`
- Remove password/email authentication
- Implement WebAuthn with `webauthn-ruby`
- Build registration flow (username + passkey)
- Build login flow (passkey authentication)

**Deliverable:** Working passwordless login/signup

---

### Phase 2: Recovery System (Weeks 3-4)
- Design recovery contact UX
- Create `RecoveryContact` and `RecoveryRequest` models
- Build "Add Recovery Contact" flow
- Build "Request Recovery" and "Approve Recovery" flows
- Implement 3/5 threshold logic

**Deliverable:** Social recovery working

---

### Phase 3: Core Chat + Design (Weeks 5-6)
- Apply Fluid Design language to Campfire UI
- Enhance real-time presence
- Add typing indicators
- Improve notifications

**Deliverable:** Polished chat with "live" feel

---

### Phase 4: Native Apps (Weeks 7-8)
- Set up Xcode project (Hotwire iOS)
- Set up Android Studio project (Hotwire Android)
- Implement WebAuthn bridges
- Implement push notification bridges
- App Store / Play Store submission

**Deliverable:** iOS and Android apps in stores

---

### Phase 5: Visualizations (Weeks 9-10)
- Create Rails API endpoints for graph data
- Integrate D3.js via Stimulus
- Build connection map
- Build 2nd-degree connections view

**Deliverable:** Network graphs working

---

### Phase 6: Polish & Launch (Weeks 11-12)
- Security audit
- Performance optimization
- Accessibility review
- Documentation
- Beta testing
- Production deployment

**Deliverable:** Production-ready New Internet

---

## Part 6: Getting Started

### Prerequisites

- Ruby 3.3+
- PostgreSQL 14+
- Node.js 20+
- Xcode (for iOS)
- Android Studio (for Android)

### Clone and Setup

```bash
# Clone Campfire
git clone https://github.com/basecamp/once-campfire.git newinternet
cd newinternet

# Remove their git history, start fresh
rm -rf .git
git init
git add .
git commit -m "Initial commit: forked from ONCE Campfire"

# Setup
bin/setup

# Start server
bin/rails server
```

### Add WebAuthn

```ruby
# Gemfile
gem 'webauthn', '~> 3.0'
```

```ruby
# config/initializers/webauthn.rb
WebAuthn.configure do |config|
  config.origin = ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")
  config.rp_name = "New Internet"
end
```

### Generate Credential Model

```bash
bin/rails generate model WebauthnCredential \
  user:references \
  external_id:string:uniq \
  public_key:text \
  nickname:string \
  sign_count:integer:default:0

bin/rails db:migrate
```

---

## Part 7: Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| WebAuthn browser compatibility | Low | High | Don't support old browsers |
| Users confused by passwordless | Medium | Medium | Excellent onboarding UX |
| Recovery contact doesn't respond | Medium | High | Multiple contacts + timeouts |
| App Store WebAuthn issues | Medium | High | Test early with Strada bridges |
| Scope creep | High | Medium | Strict MVP definition |

---

## Part 8: Success Metrics

1. **Technical**: Zero password storage, 100% WebAuthn auth
2. **Adoption**: Users create accounts without friction
3. **Recovery**: Users recover via contacts, no support tickets
4. **Performance**: Sub-second page loads
5. **Mobile**: Successful app store listings

---

## Conclusion

New Internet represents a meaningful departure from traditional platforms:

- **ONCE Campfire's** proven chat foundation
- **WebAuthn's** passwordless future
- **Social recovery's** human-centered security
- **Hotwire Native's** efficient mobile development
- **Fluid Design** for organic, minimal interfaces

The Majestic Monolith approach means one developer can ship meaningful features quickly. Start small, iterate fast, evolve based on real usage.

---

## Source Material

- **ONCE Campfire**: https://github.com/basecamp/once-campfire (MIT License)
- **WebAuthn Ruby**: https://github.com/cedarcode/webauthn-ruby
- **Hotwire Native**: https://native.hotwired.dev/
- **D3.js Force**: https://d3js.org/d3-force

---

*Document prepared for project handoff. January 2026.*
