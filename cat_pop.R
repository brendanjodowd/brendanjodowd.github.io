library(tidyverse)
library(eurostat)
library(magick)

# Importing the data on cattle numbers
cat_1 <- get_eurostat('apro_mt_lscatl', type = 'label')

# Doing some filtering.
cat_2 <- cat_1 %>% 
  filter(month=='December', animals == 'Live bovine animals', TIME_PERIOD==as.Date("2023-01-01")) %>% 
  select(-freq, -animals, -month, -TIME_PERIOD) %>% 
  mutate(values = values*1000)

# Here I just look at how cattle numbers vary between summer and winter 
cat_compare <- cat_1 %>% 
  filter(animals == 'Live bovine animals', TIME_PERIOD==as.Date("2023-01-01")) %>% 
  select(-freq, -animals, -TIME_PERIOD) %>% 
  mutate(month = if_else(month == 'December', 'Dec', 'May')) %>% 
  pivot_wider(names_from = month, values_from = values) %>% 
  mutate(diff = May/Dec) %>% 
  filter(!is.na(diff))

# Here I'm looking at the the summer/winter difference for Ireland by year.
cat_compare <- cat_1 %>% 
  filter(animals == 'Live bovine animals', geo=='Ireland') %>% 
  select(-freq, -animals, geo) %>% 
  mutate(month = if_else(month == 'December', 'Dec', 'May')) %>% 
  pivot_wider(names_from = month, values_from = values) %>% 
  mutate(diff = May/Dec) %>% 
  filter(!is.na(diff))
  

# Importing population data
pop_1 <- get_eurostat('tps00001', type = 'label')
pop_2 <- pop_1 %>% 
  filter(TIME_PERIOD==as.Date("2023-01-01"))



# UK cattle https://www.gov.uk/government/statistics/livestock-populations-in-the-united-kingdom
# UK population https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/bulletins/annualmidyearpopulationestimates/mid2023

# This is the main dataset used for plotting.
# I start with the (human) population data and join on the cattle numbers.
# The key variable is cpp which stands for cattle per person, though it is 
# number of cattle for every ten persons. 
cat_pop <- pop_2 %>% 
  rename(pop = values) %>% select(pop, geo) %>% 
  left_join(cat_2 %>% rename(cat = values) %>% select(geo, cat)) %>% 
  filter(!is.na(cat)) %>% 
  mutate(cpp = cat*10/pop) %>% 
  # Adding a blank row for the ten person emojis at the top.
  add_row(geo = '', cpp = 13) %>% 
  # Adding the UK data
  # Adding in *10 here, with thanks to Dan Ridley-Ellis for spotting that it was missing
  # in the first version.
  add_row(geo='UK', cat = 9244254, pop =  68265209, cpp = cat*10/pop) %>% 
  arrange(-cpp) %>% 
  mutate(geo = case_when(
    str_detect(geo, 'European') ~ 'EU 27',
    T ~ geo
  )) %>% 
  # Filtering out some countries that I don't want to include.
  filter(! geo %in% c('Türkiye', 'Bosnia and Herzegovina', 'Serbia', 'North Macedonia', 'Montenegro',
                      'Albania') ) 
  


# Two emoji images were needed for the plot, a cow and a person.
# I used powerpoint to copy the emojis from the web, convert them into an
# image, and then set the area outside the emoji to transparent.
# Maybe a way could be found to do this entirely within R. 

# This object cow is a magick image pointer, based on a cow emoji. You can view it with plot(cow)
cow <- image_read('input/cow_emoji.png') %>% 
  image_trim() %>% 
  image_flop()

# This creates an object that can be added to ggplot images. 
cow_raster <- grid::rasterGrob(cow, interpolate=TRUE)

# An emoji for a person that can be added to ggplot images. 
person_raster <- image_read('input/person_emoji.png') %>% 
  image_trim() %>% 
  grid::rasterGrob(interpolate = T)

bg_colour <- 'grey95'

# A function to add cows to the plot.
# I got the idea from here: https://stackoverflow.com/questions/25014492/geom-bar-pictograms-how-to
# It does two loops, over each country (i) and over each cow required (j)
# The annotate_list starts out as empty and is added to over each loop.
add_cows <- function(){
  annotate_list <- list()
  for(i in 1:nrow(cat_pop)){
    if(cat_pop$geo[i] != ''){
      # This loop is for whole cows, bits of cows are dealt with separately.
      if(cat_pop$cpp[i]>1){
        for(j in 1:floor(cat_pop$cpp[i])){
          
          annotate_list <- c(annotate_list , annotation_custom(cow_raster, 
                                                               j-0.5, j+0.5,
                                                               nrow(cat_pop)-i+1.5, nrow(cat_pop)-i+0.5
          ))
        }
      }
      # Now we deal with bits or fractions of cows. First we find the proportion "prop"
      prop = round(cat_pop$cpp[i] - floor(cat_pop$cpp[i]), digits=3)
      # We make first_bit which is the bit of the cow that appears.
      # And then second bit, which is just a blank box the same colour as the 
      # background, having width so that the two bits together have the same
      # width as the full cow. This is good because it ensures that the bits or
      # fractions of cows appear aligned correctly with the full cows. Without
      # second bit, it is very difficult to align the partial icons with the 
      # full ones.
      first_bit <- cow %>% 
        image_crop(paste0(100*prop , '%x100%')  ) 
      
      second_bit <- cow %>% 
        image_crop(paste0(100*(1-prop) , '%x100%')  ) %>% 
        image_colorize( 100, bg_colour) # %>% 
      # Here I was trying to play with the opacity, but I couldn't get it to work.
      # It would have been preferable to have second_bit as transparent instead of bg_colour.
        # image_fx(expression = '0.3*a')
      # The two bits are stuck together.
      cow_bit <- image_append(c(first_bit, second_bit)) %>% 
        grid::rasterGrob(interpolate=TRUE)
      
      # The list is added to.
      annotate_list <- c(annotate_list , annotation_custom(cow_bit, 
                                                           ceiling(cat_pop$cpp[i])-0.5, 
                                                           ceiling(cat_pop$cpp[i])-0.5+1,
                                                           nrow(cat_pop)-i+1.5,
                                                           nrow(cat_pop)-i+0.5
      ))
      rm(prop,cow_bit,first_bit,second_bit)
    }
  }
  annotate_list
}


# A function to add the people to the ggplot. It is similar to and
# simpler than the one above.
add_people <- function(){
  annotate_list <- list()
  for(i in 1:10){
    annotate_list <- c(annotate_list ,annotation_custom(person_raster, 
                                                        i-0.5, i+0.5,
                                                        nrow(cat_pop)+0.5, nrow(cat_pop)-0.5))
  }
  annotate_list
}

# This is where the plot is made. 
ggplot(cat_pop) + 
  # This was used in development to check that the cows were lined up with 
  # the bars. The reorder piece is still important for the row of people.
  # fill is set to NA so you no longer see the bars.
  geom_col( aes(y = reorder(geo, cpp), x = cpp), fill=NA, na.rm=TRUE) +
  # Adding the cows and people.
  add_cows() +
  add_people() +
  # The numbers to the right of the cows are added
  geom_text(data =cat_pop %>% filter(geo!='') , 
            aes(x = cpp + 1.2, y =reorder(geo, cpp), label = round(cpp, digits=1) ), 
            size = 4, colour = '#B8311A') +
  # The rest is just formatting and labels.
  theme_minimal() +
  theme(plot.title    = ggtext::element_textbox_simple(size = 20, margin=margin(0.4,0,0.3,0.6, "cm")),
        axis.text.y = element_text(size=11),
        axis.text.x = element_text(size=12),
        # For some reason the margin controls on this one aren't working...
        axis.title.x = ggtext::element_textbox_simple(size=13, hjust=0,
                                                      margin=margin(0.4,0,0.6,0, "cm")),
        plot.caption = ggtext::element_textbox_simple(size = 9, colour ='grey30', 
                                                      margin=margin(0.4,0,0,0, "cm"), halign=1),
        plot.title.position = 'plot',
        plot.caption.position = 'plot'
        ) +
  labs(x = 'Number of live bovine animals for every 10 people', 
       y = '',
       caption = 'Source: Eurostat, bovine data from table "apro_mt_lscatl", 
       population data from table "tps00001". Data is from December 2023. N.B. 
       Irish cattle numbers are typically 8-12% higher in summer.  
       UK data from ONS and Department for Environment, Food & Rural Affairs.',
       title = 'Ireland is the only country in Europe with more cattle than people') +
  scale_x_continuous(position = 'top', limits=c(1,16), breaks = seq(0,16,2)) 

ggsave('images/cat_pop.png',width=14, height=20,units = 'cm', bg=bg_colour)




