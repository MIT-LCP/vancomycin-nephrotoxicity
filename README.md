# vancomycin-nephrotoxicity

Study in the eRI Research Database about broad spectrum antibiotic use and in particular any associated nephrotoxicity with vancomycin.

## Quick start

This uses a private database (the eRI Research Database) for the results. However, as a subset of this dataset has been made public (eICU-CRD), the study can be reproduced on the public subset (with a smaller sample size).

1. Install eICU-CRD on a local PostgreSQL server.
2. Run the SQL scripts in the `sql` folder to generate the necessary tables.
3. Export these tables as CSVs to the `data` folder.
4. Run [multiple-drug-analysis.ipynb](/multiple-drug-analysis.ipynb) to reproduce the results.