# Noé J Nava
# noejnava2@gmail.com
# https://noejn2.github.io/

# Goal:
# Script process nlcd rasters (30x30 meters) data into rasters that resemble
# PRISM rasters (4x4 kilometers). This is done because smaller rasters are 
# easier to handle, and they can be downloaded it.

# Technical note:
# While the script has been optimized for space (I know how it can be done better,
# but it will be done in the future), I recommend to have about 100 GB of free
# disk space. Also, I work with 64GB of ram and intel processors. The task 
# takes about a day to run on my computer, but it may take longer for you.

rm(list = ls())
options(timeout = 60*60)

library(prism)
library(raster)
library(sf)

# * --- Download the data  --- *
year_ls <- c("2001", "2004", "2006", "2008", "2011", "2013", "2016", "2019")
for(y in year_ls) { # Downloading the big file
  dir_path <- paste0("data/nlcd/", "nlcd_", y, "_land_cover_l48_20210604")
  if(!file.exists(paste0(dir_path, ".zip"))) {
    if(!file.exists("data/nlcd/NLCD_landcover_2019_release_all_files_20210604.zip")) {
      # Download bif file
      download.file("https://s3-us-west-2.amazonaws.com/mrlc/NLCD_landcover_2019_release_all_files_20210604.zip",
                    destfile = "data/nlcd/NLCD_landcover_2019_release_all_files_20210604.zip")
      # Unzip big file into the smaller files
      unzip("data/nlcd/NLCD_landcover_2019_release_all_files_20210604.zip", 
            exdir = "data/nlcd")
      # Delete unnecessary files for the sake of space
      unlink("data/nlcd/NLCD_landcover_2019_release_all_files_20210604.zip")
      unlink("data/nlcd/nlcd_2001_2019_change_index_l48_20210604.zip")
    }
  }
}

# * --- Resampling crop raster to match prism raster  --- *
USmap_st <- read_sf('assets/49_state/USmap_state.shp') # Needed for spherical projections

# Obtain prism projection
prism_set_dl_dir('assets/')
prism_r <- pd_stack(prism_archive_ls()) # Needed for resampling

for(y in year_ls) {
  cat("\n", "Now working on", y, "\n")
  
  dir_path <- paste0("data/nlcd/", "nlcd_", y, "_land_cover_l48_20210604")
  
  # Unzip if unzipped does not exist
  if(!file.exists(dir_path)) {
    unzip(paste0(dir_path, ".zip"), exdir = dir_path)
  }
  nlcd_r <- raster(paste0(dir_path,
                          "/nlcd_",
                          y, 
                          "_land_cover_l48_20210604.img"))
  
  # Change prism projection if it has not been changed
  if(!crs(nlcd_r)@projargs == crs(prism_r)@projargs) {
    prism_r <- projectRaster(prism_r, crs = crs(nlcd_r))
  }
  
  # Do the resampling
  nlcd_prism_r <- raster::resample(nlcd_r, prism_r, 'bilinear')
  
  # Move into spherical projections
  nlcd_prism_r_straight <- projectRaster(nlcd_prism_r, crs = crs(USmap_st))
  nlcd_prism_r_straight <- crop(nlcd_prism_r_straight, extent(USmap_st))
  nlcd_prism_r_straight <- mask(nlcd_prism_r_straight, USmap_st)
  
  # Save the output
  saveRDS(nlcd_prism_r_straight, paste0('output/nlcd_prism_rasters/nlcd_prism', y, '.rds'))
  unlink(dir_path, recursive = TRUE)
  
}

# * --- Create average of all 8 rasters  --- *
for(y in year_ls) {
  
  file_path <- paste0("output/nlcd_prism_rasters/", "nlcd_prism_", y, ".rds")
  r <- readRDS(file = file_path)
  if(y == year_ls[1]) {
    rr <- (1/8)*r 
  }else{
    rr <- rr + (1/8)*r
  }
  
}
saveRDS(rr, "output/nlcd_prism_rasters/nlcd_prism_average.rds")
# End