# Pet atlases

All runtime sheets are 256 × 320 PNGs: eight columns and ten rows of 32 × 32 cells. The existing cat and kitten are the visual references for this revision. The rat and raccoon, including their babies, were regenerated. Opossum, rock and plant now have separate adult and baby artwork and entries in the app selector.

| Species | Adult | Baby | Suggested name |
| --- | --- | --- | --- |
| Cat | [cat.png](../../cat.png) | [cat_baby.png](../../cat_baby.png) | Mishi |
| Rat | [rat.png](../../rat.png) | [rat_baby.png](../../rat_baby.png) | Existing varieties |
| Raccoon | [raccoon.png](../../raccoon.png) | [raccoon_baby.png](../../raccoon_baby.png) | Existing varieties |
| Opossum | [opossum.png](../../opossum.png) | [opossum_baby.png](../../opossum_baby.png) | Pepita |
| Rock | [rock.png](../../rock.png) | [rock_baby.png](../../rock_baby.png) | Roco |
| Plant | [plant.png](../../plant.png) | [plant_baby.png](../../plant_baby.png) | Brotito |

The built-in ImageGen tool produced ten source sheets using the [expanded prompt set](expanded-pet-prompts.json). This supersedes the earlier rat/raccoon imports in [pet-atlas-prompts.json](pet-atlas-prompts.json). Historical user-selected references remain under `references/`; the adult raccoon is no longer locked to the earlier sheet because this revision explicitly requests improving it against the cat references.

`tool/import_pet_atlas.mjs` imports generated art using nearest-neighbor point sampling, binary alpha (source threshold 200), and nearest RGB palette swatches. It never averages pixels, dithers or expands dark contours. Animals use five flat swatches, rocks three and plants seven. Every cell keeps at least two clear pixels on all sides. The import preserves up to four pixels of the generated celebration jump arc and two for running instead of grounding every pose.

Runtime rows are idle, look, groom, stretch, walk, run, sleep, curious, celebrate, relax. The app consumes rows 0 and 4–9; its original timings are unchanged. Some generated sheets contain nine rows (rat baby, both raccoons, opossum baby). For those, the importer derives the run row from alternating walk poses, using the app's faster cadence, and maps sleep/curious/celebrate/relax to rows 6–9. The adult raccoon's unused stretching row has seven source poses; its final pose is held to fill the eighth cell via `PET_HOLD_LAST_ROW=3`.

Import command: `node tool/import_pet_atlas.mjs SOURCE OUTPUT MAX_WIDTH MAX_HEIGHT rows|nine pet|rock|plant`. The [prompt set](expanded-pet-prompts.json) also records the per-asset import parameters and generated source filenames.

The catalog selects baby assets below 200 XP, adults from 200 XP and the same adult atlas with the existing master scaling from 600 XP. All species are available through the existing scrollable filters and random selection in the shared pet picker used by settings and onboarding. This change covers the Flutter app; the native Android home-screen widget still uses its existing cat drawables.

Phone previews use the **actual runtime pixels**, enlarged without smoothing:

- [Cat, rat and raccoon](pet-atlas-mobile-light.png), [dark](pet-atlas-mobile.png), [animation](pet-atlas-mobile.gif)
- [Opossum, rock and plant](pet-atlas-mobile-new-light.png), [dark](pet-atlas-mobile-new.png), [animation](pet-atlas-mobile-new.gif)
- [Interactive preview of all twelve assets](pet-atlas-preview.html)

Export with `node tool/export_pet_previews.mjs` (requires ImageMagick).
Validate with `flutter test --no-pub test/pet_atlas_test.dart test/pet_species_test.dart test/launch_screen_test.dart`.
Checks cover dimensions, colors, alpha, gutters, distinct poses/artwork, growth asset resolution, and scrolling/selecting all new species. No APK build needed.
