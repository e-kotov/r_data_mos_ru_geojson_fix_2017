#-------------------------Package Installer--------------------------
# load packages and install if missing
# thanks to Richard Schwinn for the code, http://stackoverflow.com/a/33876492

# list the packages you need
p <- c('data.table', 'jsonlite', 'rgdal', 'sp', 'RCurl', 'sf')

# this is a package loading function
loadpacks <- function(package.list = p){
new.packages <- package.list[!(package.list %in% installed.packages()[,'Package'])]
    if(length(new.packages)) {
        install.packages(new.packages)
    }
lapply(eval(package.list), require, character.only = TRUE)
}

loadpacks(p) # calling function to load and/or install packages
rm(loadpacks, p) # cleanup namespace

#----------------------End of Package Installer----------------------


workflow <- function() {

    pre_load_data_set_list()
    fix_geojson(dataset_id = prompt_input())
}


pre_load_data_set_list <- function() {

    data_set_list <- fromJSON('https://data.mos.ru/opendata/list.json')
    data_set_list <<- data.table(data_set_list$Meta)
    print('Data set list is updated from "https://data.mos.ru/opendata/list.json".')
}


fix_geojson <- function(dataset_id) {

    raw_folder <- 'json_raw'
    fixed_folder <- 'json_fixed'
    if (dir.exists(raw_folder) == F) { dir.create(raw_folder) }
    if (dir.exists(fixed_folder) == F) { dir.create(fixed_folder) }
    
    raw_json_save_path <- paste0(raw_folder, '/', dataset_id, '.geojson')
    
    if (file.exists(raw_json_save_path) == F) {
        # download.file(url = paste0('https://apidata.mos.ru/v1/datasets/', dataset_id, '/features'),
                      # destfile = raw_json_save_path)
        json_data <- getURL(paste0('https://apidata.mos.ru/v1/datasets/', dataset_id, '/features'))
        # x <- fromJSON(json_data)
        sink( raw_json_save_path )
        cat(json_data)
        sink()
    } else {
        json_data <- readLines(raw_json_save_path)
    }
    
    fixed_json_save_path <- paste0(fixed_folder, '/', dataset_id, '.geojson')
    
    x <- fromJSON(json_data)
    
    dt <- data.table(RowId = x$features$properties$RowId,
                     data.table(x$features$properties$Attributes))
    
    nested_lists <- sapply(dt, is.list)
    
    dts <- dt[ , .SD, .SDcols = -names(nested_lists[ nested_lists == T ])]
    
    
    # sp <- readOGR(raw_json_save_path, 'OGRGeoJSON')
    # sp <- readOGR(json_data, 'OGRGeoJSON')
    sf <- st_read(raw_json_save_path)
    
    
    sf$Attributes <- NULL
    
    
    # sp@data$Attributes <- NULL
    
    sfx <- merge(sf, dts, by = 'RowId', all.x = T, all.y = F)
    # spx <- merge(sp, dts, by = 'RowId', all.x = T, all.y = F)
    
    st_write(sfx, fixed_json_save_path, layer = 'OGRGeoJSON', driver = 'GeoJSON')
    # writeOGR(spx, fixed_json_save_path, layer = 'OGRGeoJSON', driver = 'GeoJSON', overwrite_layer = T)
}



prompt_input <- function() {

    print('This scipt will fetch the GeoJSON of a data set put it into "json_raw" folder in your current R working directory, read this file, fix it and put the fixed GeoJSON file into "json_fixed" folder in your current R working directory.')
    answ = ""
    while (!answ %in% data_set_list$Id){
        answ <- readline(prompt = paste0('To proceed enter data.mos.ru data set id (3 or 4 digits, e.g. 1106, current range of ids is ', paste0(range(data_set_list$Id), collapse = ' to '),'): '))
        if (! answ %in% c("y", "n")){
            print (paste0('This does not seem to be a valid data set id. To proceed enter data.mos.ru data set id (3 or 4 digits, e.g. 1106, current range of ids is ', paste0(range(data_set_list$Id), collapse = ' to '),'): ') )
            }
    }
    
    return(answ)
}
