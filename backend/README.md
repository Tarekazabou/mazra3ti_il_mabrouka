# Backend — Universal Plant Irrigation

This README explains how to run the Flask + Firestore + Gemini backend for the Universal Plant Irrigation system in this repository.

## What this service does
- Stores and serves plant trait profiles (Firestore).
- Synthesizes plant characteristics via Gemini if a profile is missing.
- Generates a synthetic dataset, trains XGBoost models (classifier + 2 regressors).
- Produces irrigation recommendations by combining rule-based safety nets, ML baseline, and optional Gemini refinement.

## Prerequisites
- Python 3.10+ installed
- A Google Cloud project with Firestore enabled and a service account JSON for server access
- A Gemini API key (Google Generative Language API) for plant enrichment and reasoning

## Key files
- `app/main.py` — Flask application and HTTP endpoints
- `app/config.py` — Environment-driven settings (prefix `IRRIGATION_`)
- `app/services/plant_database.py` — Firestore-backed plant profiles + Gemini fallback
- `app/services/llm.py` — Gemini client wrapper
- `app/services/ml.py` — XGBoost training + model manager
- `app/data/plant_database.json` — Seed plant traits used to populate Firestore if empty

## Environment variables
The application uses Pydantic with `IRRIGATION_` env prefix. Example variables you should set before running:

- `IRRIGATION_DEBUG=true|false` — optional, default true
- `IRRIGATION_GEMINI_API_KEY` — Gemini (Generative Language) API key
- `IRRIGATION_GEMINI_MODEL_NAME` — Gemini model name (default: `models/gemini-1.5-pro`)
- `IRRIGATION_FIRESTORE_PROJECT_ID` — GCP project id for Firestore (optional if `GOOGLE_APPLICATION_CREDENTIALS` defines project)
- `IRRIGATION_FIRESTORE_PLANTS_COLLECTION` — collection name (default: `plant_profiles`)
- `GOOGLE_APPLICATION_CREDENTIALS` — path to service account JSON used by google-cloud-firestore

Tip: For local development you can use a `.env` loader or set variables in PowerShell like shown below.

## Install & run (Windows PowerShell)
Open PowerShell, then:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e .[dev]

# set required env vars (example)
$env:IRRIGATION_GEMINI_API_KEY = "YOUR_GEMINI_KEY"
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
$env:IRRIGATION_FIRESTORE_PROJECT_ID = "your-gcp-project-id"

# run the server
python -m app.main
```

The service binds to 0.0.0.0:8000 by default (see `app/main.py`).

## HTTP Endpoints
- GET `/health` — health check
- GET `/plants` — list plant profiles stored in Firestore
- POST `/plants` — upsert a plant profile
  - Body: `PlantUpsertRequest` (see code under `app/schemas/`)
- POST `/predict` — compute irrigation recommendation
  - Body: `IrrigationPredictionRequest` (either `plant_name` or `plant_characteristics` + sensor snapshot)
- POST `/train` — create synthetic dataset from plant profiles and train XGBoost models
  - JSON body (optional): `{ "samples": 20000 }`

Example `predict` JSON (minimal):
```json
{
  "plant_name": "tomato",
  "sensor_snapshot": {
    "soil_moisture": 55.0,
    "current_temperature": 27.0,
    "current_humidity": 60.0,
    "minutes_since_last_watering": 240,
    "soil_compaction": 20.0,
    "slope_degrees": 2.0,
    "soil_type": "loam",
    "hour_of_day": 10,
    "day_of_year": 150,
    "season": "spring"
  },
  "weather_snapshot": {
    "rain_probability_24h": 0.6,
    "rain_quantity_mm": 8.0
  }
}
```

## Behavior & notes
- Firestore seeding: on first startup the service will seed the configured collection from `app/data/plant_database.json` if the collection is empty.
- Gemini fallback: if a plant profile doesn't exist, the service calls Gemini to generate characteristics and persists the result to Firestore.
- Training: `POST /train` generates a synthetic dataset and trains three XGBoost models which are saved to `app/ml_models/`.
- If models are not present, prediction falls back to the deterministic rule-based policy.

## Troubleshooting
- Firestore auth errors: ensure `GOOGLE_APPLICATION_CREDENTIALS` points to a valid service account JSON with Firestore permissions.
- Gemini errors: verify `IRRIGATION_GEMINI_API_KEY` and model name are correct; Gemini calls are optional (fallback present).
- Large installs: xgboost and pandas may take some time to build / install—use wheels when available.

## Next steps & suggestions
- Add automated unit tests for the prediction pipeline.
- Add a small Postman or curl collection describing the main endpoints for manual testing.
- If you plan to deploy, consider secrets management for Gemini and Firestore credentials (e.g., Secret Manager).

---

If you'd like, I can also:
- add a `backend/.env.example` file with the exact env var names,
- add a small Postman `collection.json` or cURL examples,
- or create unit tests for the main prediction flow.

Tell me which of those you'd like next and I will continue.