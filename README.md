# Project 3: World Cup 2022 Predictions

## 1. Project Objective
Build an end-to-end, reproducible pipeline that:
- prepares FIFA World Cup 2022 fixtures and team metadata,
- trains a three-class match outcome model (`H`, `D`, `A`) on historical international matches,
- simulates the full 2022 tournament bracket,
- reports predicted outcomes against actual results.

## 2. Folder Structure

```text
Projects/Project-3-WorldCup-2022-Predictions/
  README.md
  data/
    raw/
    processed/
  outputs/
  notebooks/
    01_data_prep_worldcup_2022.ipynb
    02_match_model_and_tournament_sim.ipynb
    03_results_report.ipynb
```

## 3. Data Inputs And Assumptions
- Primary curated source: hardcoded official 2022 fixtures (group + knockout).
- Historical training data expected in `data/raw/` with schema:
  - `date`, `home_team`, `away_team`, `home_goals`, `away_goals`, `tournament`, `neutral`
- If no valid raw historical file is available, Notebook 1 creates a deterministic synthetic fallback dataset so the pipeline still runs end-to-end.

## 4. Notebook Execution Order
1. `01_data_prep_worldcup_2022.ipynb`
2. `02_match_model_and_tournament_sim.ipynb`
3. `03_results_report.ipynb`

## 5. Output Artifacts
- `data/processed/worldcup_2022_fixtures.csv`
- `data/processed/worldcup_2022_teams.csv`
- `data/processed/international_training_matches.csv`
- `outputs/group_stage_predictions.csv`
- `outputs/knockout_predictions.csv`
- `outputs/tournament_summary.json`

## 6. Limitations
- Simplified knockout tie handling when model predicts draws.
- Feature availability is constrained by the historical data source and fallback generation.
- Team strength snapshots are lightweight proxies (form/goals/Elo-like rating), not full event-level models.

## 7. Reproducibility Notes
- Random seeds are fixed where sampling is used.
- Time-based split is used for model validation.
- Deterministic fallback tie rules are enforced for ranking ties.
- Only pre-match information is used to compute features.
