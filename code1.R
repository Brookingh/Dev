library(foreign)
library(dplyr)

setwd('D:/Postdoc-Helsinki/project/review2/model4_outbreak')
df = read.csv('Confirmed_cases_Notification_rate.csv')
unique(df$RegionName)

#The grids
grid = read.dbf('Europe/Europe_ebba2_intercept.dbf')
grid_country = grid %>% 
  group_by(ID) %>% 
  slice_max(AREA_GEO)

#merge predicted prevalence with country
setwd('D:/Postdoc-Helsinki/project/review2/Model2_host/code/riskmap5')
Pathogen = c("Plasmodium","Trichomonas","Campylobacter","Avian influenza virus",
             "Leucocytozoon","Salmonella","Escherichia","Chlamydia",
             "Haemoproteus","Anaplasma","West Nile virus","Coxiella",
             "Rickettsia","Sindbis virus","Borrelia","Usutu virus","Tick-borne encephalitis virus")

i=6
load(paste('predict/',Pathogen[i],".Rdata",sep = ""))
names(predictwresult)[17] = 'pred_preva'
names(predictbresult)[17] = 'pred_preva'
hii = foreign::read.dbf('hii_mean.dbf')

# Merge Name and eoagrid
grid_country = grid_country %>% tidyr::unite("New", Name, eoagrid, na.rm=TRUE)
grid_country = merge(grid_country,hii, by = "ID")

#'First sum up the prevalence of different species occurring in each grid
predict.grid.w = predictwresult %>% 
  group_by(cell50x50) %>%
  summarize(overallrisk_grid = sum(pred_preva),
            communityrisk = mean(pred_preva),
            sr = n_distinct(animal))

predict.grid.b = predictbresult %>% 
  group_by(cell50x50) %>%
  summarize(overallrisk_grid = sum(pred_preva),
            communityrisk = mean(pred_preva),
            sr = n_distinct(animal))

#separate seasons
pred.grid.breed = merge(grid_country,predict.grid.b,by.x = "New", by.y = "cell50x50")
pred.grid.breed$season = "Breeding"
pred.grid.winter = merge(grid_country,predict.grid.w,by.x = "New", by.y = "cell50x50")
pred.grid.winter$season = "Nonbreeding"
pred.grid = rbind(pred.grid.breed, pred.grid.winter)


#per country risk
country.risk = pred.grid.breed %>% 
  group_by(name_1) %>% 
  summarize(totalrisk = mean(overallrisk_grid),
            commrisk = mean(communityrisk),
            sr = mean(sr),
            hii = mean(MEAN))

#country notification rate
unique(df$RegionName)
df = df %>%
  filter(RegionName !="EU (without UK)" &
        RegionName !="EU (with UK until 2019)"&
  RegionName !="EU/EEA (without UK)"&
  RegionName !="EU/EEA (with UK until 2019)")%>%
  mutate(across(everything(), ~replace(., . ==  "United Kingdom" , "UK")))

df$NumValue = as.numeric(df$NumValue)
#31 Countries
country.df = df %>% 
  group_by(RegionName) %>% 
  summarize(rate = mean(NumValue, na.rm = T))

df1 = merge(country.df,country.risk,by.x = "RegionName", by.y = "name_1")

df1$sorisk = (log(df1$hii+0.01))*df1$totalrisk

hist(df1$rate)
hist(df1$totalrisk)
hist(df1$sorisk)

plot(df1$totalrisk,df1$rate) 
summary(lm(rate~totalrisk,data=df1))
abline(lm(rate~totalrisk,data=df1), col = 'darkred')

plot(df1$sorisk, df1$rate) 
summary(lm(rate~sorisk,data=df1))
abline(lm(rate~sorisk,data=df1), col = 'darkred')

plot(df1$commrisk, df1$rate)
summary(lm(rate~commrisk,data=df1))
abline(lm(rate~commrisk,data=df1), col = 'darkred')

plot(df1$sr, df1$rate)
summary(lm(rate~sr,data=df1))
abline(lm(rate~sr,data=df1), col = 'darkred')
