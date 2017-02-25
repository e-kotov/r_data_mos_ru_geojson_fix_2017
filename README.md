# r_data_mos_ru_geojson_fix_2017
R script to fix attributes in GeoJSON files from data.mos.ru (as of 2017)

This is alpha version. It does not check if the dataset is actually a spatial dataset. It simply ignores any attributes that have subattributes (and are converted to nested lists and data.frames if we speak in R terms).
