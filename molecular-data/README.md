# Mobilizing molecular data

A couple of approaches:

- See folder using-existing-taxa for generating a dwca using occurrence core and two extensions for ggbn and emof data
- See folder using-checklist for generating two dwca files, one with a checklist for bacterial taxonomy and another with the molecular data

Regardless of approach, the data and scripts aim at reproducibly generating dwca files which can be validated at gbif.org using the tools for data validation there.

These files can then be ingested into the Living Atlas system using the biocache CLI command.

Random notes:

- Use Australian example primarily ie look at https://www.gbif.org/dataset/f8ceb4e6-82ff-4325-afc8-eb5e64b5f842 since this format has already been successfully used in the Living Atlas system.

- It is possible to create a separate checklist for bacterial taxonomy using the taxon core format
  - parse_bacterial_taxonomy.R
  - ~/repos/bioatlas/data-mobilization-pipeline/molecular-data/using-checklist/bac_taxonomy_r86_clean.tsv

- Do not use BIOWIDE right now ie https://www.gbif.org/dataset/3b8c5ed8-b6c2-4264-ac52-a9d772d69e9f

- Is there an example dataset somewhere at gbif.org that contains sequences - Christian?
