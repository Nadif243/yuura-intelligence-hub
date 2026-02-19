# Yuura Intelligence Hub 🌸

> A comprehensive data analytics platform tracking VTuber growth, content performance, and community engagement for [Yuura Yozakura](https://www.youtube.com/@yuurayozakura) from [Project Livium](https://www.youtube.com/@ProjectLIVIUM).

[![Data Pipeline](https://img.shields.io/badge/Pipeline-Automated-success)]()
[![Database](https://img.shields.io/badge/Database-PostgreSQL-blue)]()
[![Status](https://img.shields.io/badge/Status-In%20Development-yellow)]()
[![Python](https://img.shields.io/badge/Python-3.11-blue)]()
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()

---
## Project Overview

The Yuura Intelligence Hub is a full-stack data science project that collects, analyzes, and visualizes performance metrics for a VTuber's channel. The system tracks subscriber growth velocity, content performance patterns, song repertoire evolution, and community engagement trends.

**Current Stats Being Tracked:**
- 25.1+ subscribers
- 696+ videos analyzed
- 3-5 streams per week
- Multilingual content (Japanese, Indonesian, English)

---
## Motivation

This project was built to:

1. Mainly for the purpose of **Supporting a creator** - Provide Yuura's community with transparency into her channel's growth and content patterns
2. **Demonstrate end-to-end data science capabilities** - From data collection to predictive modeling to visualization
3. **Solve an analytics problem** - Content creators need data-driven insights to understand their growth and audience engagement
4. **Build a portfolio piece** - Showcase database design, ETL pipelines, time-series analysis, and full-stack development skills

---
## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Data Collection Layer                      │
│  YouTube API → Python Scripts → Cron Jobs (Every 6 hours)   │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Storage Layer                      │
│               PostgreSQL (Supabase) Database                │
│  • Channel Snapshots (time-series)                          │
│  • Content Catalog (videos/streams)                         │
│  • Performance Metrics (views, engagement)                  │
│  • Song Database (repertoire tracking)                      │
│  • Lore Tags (content categorization)                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                       Analysis Layer                        │
│  • Growth velocity & acceleration calculations              │
│  • Predictive modeling (milestone ETA)                      │
│  • Content performance analytics                            │
│  • Song frequency analysis                                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 Presentation Layer (Future)                 │
│             Next.js Dashboard with Tailwind CSS             │
│  • Real-time growth visualization                           │
│  • Content performance leaderboards                         │
│  • Song repertoire browser                                  │
│  • Milestone countdown tracker                              │
└─────────────────────────────────────────────────────────────┘
```

---
## Database Schema

The system uses a normalized relational database with 8 core tables:

```
talents (1) ──┬─→ snapshots (many)      [Growth time-series]
              ├─→ content (many)        [Video/stream catalog]
              └─→ milestones (many)     [Subscriber goals]

content (1) ──┬─→ content_metrics (many)  [Performance tracking]
              ├─→ lore_tags (many)        [Categorization]
              └─→ song_performances (many) [Songs sung in stream]

songs (1) ────→ song_performances (many)  [Song repertoire]
```

---
## 🚀 Current Progress

- [x] Database schema design and implementation
- [x] ERD modeling with 8 normalized tables
- [x] GitHub repository setup
- [x] Supabase PostgreSQL instance configured
- [ ] YouTube API integration
- [ ] Automated snapshot collection (cron jobs)
- [ ] Growth velocity calculation scripts
- [ ] Milestone prediction model (linear regression → time-series forecasting)
- [ ] Frontend dashboard development
- [ ] Deployment to production

---
## 🎓 Learning Outcomes

This project hopefully demonstrates proficiency in:
### Data Engineering
- Designing normalized relational databases
- Building automated ETL pipelines
- Handling time-series data at scale
- Implementing data quality checks
### Data Science
- Time-series analysis (growth velocity, acceleration)
- Predictive modeling (milestone predictions)
- Feature engineering (engagement metrics)
- Statistical validation (confidence scoring)
### Software Engineering
- Git version control and professional commit practices
- Environment configuration and secrets management
- API integration and rate limit handling
- Documentation and code organization
### Full-Stack Development
- Backend API design (future)
- Frontend data visualization (future)
- Database optimization and indexing
- Production deployment (future)

---
## 📝 Notes

- This is a **portfolio project** built for educational and analytical purposes
- All data is collected from public YouTube APIs
- The project respects YouTube's Terms of Service and API rate limits

---
## ℹ️ About

Built by a physics undergraduate shifting focuses into data science, combining computational physics experience with web development skills to create meaningful analytics tools.

**Why Yuura Yozakura?**
As a fan and community member, I wanted to create something that provides value back to the creator and demonstrates real-world data science application beyond academic exercises.

---

*Last Updated: 19 February 2026*
