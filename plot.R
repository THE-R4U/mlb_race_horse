library(reshape2)
library(dplyr)
library(ggplot2)
library(gganimate)
library(directlabels)



colors <- read.table("colors.txt", header = FALSE, sep = " ",
                     col.names = c("team_abbrev", "color"))
colors$team_abbrev <- toupper(colors$team_abbrev)

season.colors <- merge(x = season, y = colors, by = "team_abbrev", all = TRUE)
season.colors$color <- paste("#", season.colors$color, sep="")

season.melt <- melt(season.colors, id.vars = c("team_abbrev","image_url", "color"), 
                    variable.name = "date",
                    value.name = "pct")
season.melt$pct <- as.numeric(season.melt$pct)
season.melt$date <- as.Date(season.melt$date)

hr <- ggplot(season.melt, aes(x=date, y=pct, group=team_abbrev, color=team_abbrev, 
                              fill=color, frame=date, cumulative=TRUE)) + 
  geom_line(size=1.15) +
  labs(title = "Horse Race", color = "Team") +
  scale_x_date('Standings as of', date_breaks = '2 weeks', date_labels = '%m/%d') +
  scale_y_continuous(name = "Win Percentage") +
  scale_color_manual(breaks = season.colors$team_abbrev, values = season.colors$color) +
  geom_dl(aes(label = team_abbrev), method = list(dl.trans(x = x + .2), "last.points")) + 
  theme_minimal()

# save as a GIF
gganimate(hr, "hr.gif", ani.width = 300, ani.height = 250, interval = 0.2)

# save as a video 
gganimate(hr, "hr.mp4", ani.width = 1600, ani.height = 900, interval = 0.1)
