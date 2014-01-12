#' Copyright 2014 Simon Garnier (http://www.theswarmlab.com / @sjmgarnier)
#' 
#' This script is free software: you can redistribute it and/or modify it under
#' the terms of the GNU General Public License as published by the Free Software
#' Foundation, either version 3 of the License, or (at your option) any later
#' version.
#' 
#' This script is distributed in the hope that it will be useful, but WITHOUT
#' ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#' FOR A PARTICULAR PURPOSE.
#' 
#' See the GNU General Public License for more details.
#' 
#' You should have received a copy of the GNU General Public License along with
#' this script. If not, see http://www.gnu.org/licenses/.
#' 

#' **Document title:** R vs Python - Round 2
#' 
#' **Date:** January 12, 2014
#' 
#' **Author:** Simon Garnier (http://www.theswarmlab.com / @sjmgarnier)
#' 
#' **Description:** This script scrapes data out of 2 websites
#' (www.MovieBodyCounts.com and www.imdb.com). For more information, see
#' http://www.theswarmlab.com/r-vs-python-round-2/
#' 
#' Document generated with RStudio ([www.rstudio.com](http://www.rstudio.com)).
#' 

# Load libraries
library(RCurl)     # Everything necessary to grab webpage
library(XML)       # Everything necessary to parse HTML code

# Create curl handle for reuse
curl <- getCurlHandle(useragent = "R", followlocation = TRUE)

# Prepare URLs of the HTML files containing the list of movies by letters (first
# page are movies starting with a number)
urls.by.letter <- paste0('http://www.moviebodycounts.com/movies-', 
                         c("numbers", LETTERS[1:21], "v", "W" , "x", "Y", "Z"), '.htm')

# First, create the list of movie URLs
urls.by.movie <- vector()
for (i in 1:length(urls.by.letter)) {
  # Load raw HTML
  raw.html <- getURL(urls.by.letter[i], curl = curl)
  
  # Parse HTML content
  parsed.html <- htmlParse(raw.html)
  
  # Extract desired links from HTML content. The desired links are those after
  # image 'graphic-movies.jpg' in the page
  links <- as.vector(xpathSApply(parsed.html, "//img[@src='graphic-movies.jpg']/following::a/@href"))
  urls.by.movie <- c(urls.by.movie, links)
}

# Of course some URLs are not formatted like the others, let's remove the extra
# characters
urls.by.movie <- gsub('http://www.moviebodycounts.com/', '', urls.by.movie)

# And one URL is actually a shortcut to another page. Let's get rid of it.
id <- which(urls.by.movie == "movies-C.htm")
urls.by.movie <- urls.by.movie[-id]

# And now let's make the URLs complete
urls.by.movie <- paste0('http://www.moviebodycounts.com/', urls.by.movie)

# Ok, let's get serious now

# Prepare data frame
data <- data.frame(MBC_URL = urls.by.movie, IMDB_URL = NA, Film = NA, Year = NA, Body_Count = NA)

# Let's do the hard work now
for (i in 1:length(data$MBC_URL)) {
  # Load raw HTML
  raw.html <- getURL(data$MBC_URL[i], curl = curl)
  
  # Parse HTML content
  parsed.html <- htmlParse(raw.html)
  
  # Find movie title
  title <- xpathSApply(parsed.html, "//title", xmlValue)
  data$Film[i] <- gsub("Movie Body Counts: ", "", title)
  
  # Find movie year
  data$Year[i] <- as.numeric(xpathSApply(parsed.html, "//a[contains(@href, 'charts-year')]/descendant::text()", xmlValue))
  
  # Find IMDB link (will be useful for next challenge)
  data$IMDB_URL[i] <- as.vector(xpathSApply(parsed.html, "//a/@href[contains(.,'imdb')]"))[1]
  
  # Extract all text nodes after image 'graphic-bc.jpg'
  text <- xpathSApply(parsed.html, "//img[@src='graphic-bc.jpg']/following::text()", xmlValue)
  
  # Remove all letters, keep numbers only
  text <- gsub('[^0-9]+', ' ', text)
  
  # Select first non-empty element of vector. This is were the number of deaths
  # lies.
  deaths <- text[which(text != ' ')[1]]
  
  # Split the character string at spaces
  deaths <- unlist(strsplit(deaths, ' '))
  
  # Transform characters into numbers
  deaths <- as.numeric(deaths)
  
  # Sum up the numbers (in case they have been split into separate categories,
  # which happened for some movies) and save
  data$Body_Count[i] <- sum(deaths, na.rm = TRUE)
  
  print(paste('Film', i, 'of', length(data$MBC_URL), 'done.'))
}

# Save scraped data in a .csv file for future use
write.csv(data, "movies-R.csv", row.names = FALSE)





