# Noé J Nava
# noejnava2@gmail.com
# https://noejn2.github.io/

# Goal:
# Some figure creation

rm(list = ls())
library(ggplot2)

# Mapping function
map.foo <- function(raster_type, 
                    xlim_low, xlim_upp, 
                    title_name, pall_type, 
                    pall_dir, pall_num) {
  # Read and tidy raster
  rrr <- readRDS(paste0("output/nlcd_prism_rasters/nlcd_prism_", raster_type, ".rds"))
  rrr <- as(rrr, "SpatialPixelsDataFrame")
  rrr <- as.data.frame(rrr)
  colnames(rrr) <- c("value", "x", "y")
  
  ggplot() +
    geom_tile(data = rrr, 
              aes(x = x, 
                  y = y, 
                  fill = value), alpha=0.8) +
    geom_polygon(data = USmap_state_df,
                 aes(x = long,
                     y = lat,
                     group = group),
                 fill = NA,
                 color = "black",
                 linewidth = .5) +
    geom_vline(xintercept = -100, linetype = "dotdash") +
    labs(
      title = title_name,
      subtitle = "Latitude"
    ) +
    guides(fill = guide_colourbar(title = "",
                                  title.position = "top"))+
    geom_text(size = 20) +
    scale_fill_distiller(type = pall_type, 
                         palette = pall_num,
                         na.value = "white", 
                         direction = pall_dir,
                         limits = c(xlim_low, xlim_upp)) +
    theme(panel.background = element_rect(fill = NA, 
                                          color = NA),
          legend.justification = c(0,1),
          legend.key.height = unit(.75, 'cm'), #change legend key height
          legend.key.width = unit(4, 'cm')) +
    theme(legend.direction = "horizontal",
          legend.position = "bottom") +
    xlab("Longitude") + ylab("")
}

# Creating and saving the maps
USmap_state_df <- readRDS(file = 'assets/USmap_state_df.rds')
year_ls <- c("2001", "2004", "2006", "2008", "2011", "2013", "2016", "2019")
for(y in year_ls) {
  png(filename = paste0("output/figs/", "cropland_", y, ".png"),
      units = "px",
      width = 720, height = 480)
  crop_plot <- map.foo(y, 
                       0, 100, 
                       "Fraction of cropland (percent)", 
                       "div", 
                       1, 1)
  plot(crop_plot)
  dev.off()
}
# Produce the average one
png(filename = paste0("output/figs/", "cropland_", "average", ".png"),
    units = "px",
    width = 720, height = 480)
crop_plot <- map.foo("average", 
                     0, 100, 
                     "Fraction of cropland (percent)", 
                     "div", 
                     1, 1)
plot(crop_plot)
dev.off()
# End