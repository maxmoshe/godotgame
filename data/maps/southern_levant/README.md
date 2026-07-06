# Southern Levant Map Dataset

Engine-agnostic map layers for the southern Levant, centered on the Iron Age / Saul-David campaign prototype.

## Coordinate System

All geometry is stored in GeoJSON-style longitude/latitude coordinates using WGS84 (`EPSG:4326`).

The Godot prototype projects the declared dataset bounding box into its existing top-down map rectangle. Other engines can reproject, rescale, or tile these files directly from the same source data.

## Layer Rules

- Physical geography stays in `physical/`.
- Historical influence zones stay in `history/`.
- Human gameplay layers such as settlements and roads stay in `human/`.
- Ancient territory overlays are source data only for now; the Godot prototype does not render them because they make the campaign map too busy.
- Settlement ownership is stored per feature as `owner_faction` in `human/settlements.geojson`, so villages and cities can change sides without repainting the map.
- Settlement classification is explicit: use `settlement_class`, `location_class_label`, `site_role`, `fortification_level`, and `classification_confidence` instead of inferring type from the prose `kind`.
- Every region polygon carries gameplay metadata: `movement_cost`, `supply_value`, `water_access`, `agriculture_value`, `defense_bonus`, `settlement_density`, `road_difficulty`, and `seasonal_risk`.

## Source Notes

This first pass is a game-scale interpretive dataset, not a survey-grade GIS product. Modern physical outlines are simplified from public/open geodata references such as Natural Earth, OpenStreetMap, and NASA SRTM-derived relief concepts. Historical regions are approximate synthesis zones based on standard southern Levant historical geography, biblical-toponym traditions, and Iron Age scholarship. Each layer includes source notes and confidence metadata where appropriate.

Use this as a clean data spine for prototype rendering and gameplay. Later passes can replace individual geometries with higher-resolution GIS exports without changing the Godot importer contract.
