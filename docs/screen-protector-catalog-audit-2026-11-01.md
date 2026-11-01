# Screen protector catalog audit — 2026-11-01

Source: connected Supabase project `zpqjslqeushjqksngetv`, table `public.protector_groups`.
This is a **read-only audit**. No production records were modified.

## Inventory
- 32 group rows / 32 group codes.
- 796 model-name occurrences.
- 786 distinct case-insensitive brand + model strings.
- 21 brands.
- The counts are string-based, not normalized by manufacturer model identifiers.

## Conflicting group assignments
| Brand | Model | Groups |
| --- | --- | --- |
| Infinix | Hot 8 Lite (X650) | G1, G7 |
| Infinix | Smart 4 (X653) | G1, G7 |
| Infinix | Smart HD 2021 (X612B) | G9, G10 |
| Nokia | G10 | G1, G9 |
| Nokia | G20 | G1, G9 |
| Oppo | A12s | G9, G10 |
| Oppo | Reno 8T 5G | G13, G31 |
| Poco | M5s | G3, G13 |
| Vivo | Y12 | G1, G8 |

Intra-group duplicate: Oppo Reno 11 F 5G appears twice in G16.

## Source-verified protector example
Samsung Galaxy A35 5G and Galaxy A55 5G share at least one commercially marketed glass-protector SKU. They are already both in G12; do not add duplicates.
- SBS manufacturer listing: https://www.sbsmobile.com/en/collections/samsung-screen-protectors/products/full-cover-glass-screen-protector-for-samsung-galaxy-a35-a55
- Belkin technical sheet lists separate SKUs for the two models, despite matching published protector dimensions: https://media.bechtle.com/asrc/180712/1c4b3d4ee288fc9434f5175bf56070570/c3/-/11b5b31c5861439d9be3fd5f904d51bf/belkin-samsung-galaxy-a55-5g-screen-prot-data-sheet-1

## Data-quality cautions
- Groups appear to mix similarity-by-size and actual interchangeable glass protector products.
- Equal diagonal screen size does **not** prove protector interchangeability; compare visible panel dimensions, corner radii, curvature, speaker and camera cutouts, adhesive border and vendor SKU.
- Distinguish `same nominal diagonal`, `candidate fit`, and `vendor-confirmed protector SKU` rather than marking entire groups as verified.
- Existing iPhone `APPLE-SIZE-*` groups are nominal diagonal categories, not blanket fitment guarantees.
- No model insertions or deletions should occur until each candidate has manufacturer/retailer SKU evidence or physical test evidence.

## Recommended next batch
1. Normalize brand names and manufacturer model numbers, retaining raw strings.
2. Resolve the nine cross-group conflicts above.
3. Add a sourced, per-pair compatibility evidence layer and a review status.
4. Expand brands in batches, comparing against a named external device catalog and documenting source URLs.
5. Keep production catalog unchanged until reviewed and approved.
