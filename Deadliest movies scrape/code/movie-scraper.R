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
urls.by.movie <- unlist(lapply(urls.by.letter, FUN = function(URL) {
  # Load raw HTML
  raw.html <- getURL(URL, curl = curl)
  
  # Parse HTML content
  parsed.html <- htmlParse(raw.html)
  
  # Extract desired links from HTML content. The desired links are those after
  # image 'graphic-movies.jpg' in the page
  links <- as.vector(xpathSApply(parsed.html, "//img[@src='graphic-movies.jpg']/following::a/@href"))
  
  if (!is.null(links)) {
    ix = grepl("http://www.moviebodycounts.com/", links)
    links[!ix] <- paste0("http://www.moviebodycounts.com/", links[!ix])
    return(links)
  }
}), use.names = FALSE)

# One URL is actually a shortcut to another page. Let's get rid of it.
ix <- which(grepl("movies-C.htm", urls.by.movie))
urls.by.movie <- urls.by.movie[-ix]

# Ok, let's get serious now

data <- do.call(rbind, lapply(urls.by.movie, FUN = function(URL) {
  # Load raw HTML
  raw.html <- getURL(URL, curl = curl)
  
  # Parse HTML content
  parsed.html <- htmlParse(raw.html)
  
  # Find movie title
  Film <- xpathSApply(parsed.html, "//title", xmlValue)
  Film <- gsub("Movie Body Counts: ", "", Film)
  
  # Find movie year
  Year <- as.numeric(xpathSApply(parsed.html, "//a[contains(@href, 'charts-year')]/descendant::text()", xmlValue))
  
  # Find IMDB link (will be useful for next challenge)
  IMDB_URL <- as.vector(xpathSApply(parsed.html, "//a/@href[contains(.,'imdb')]"))[1]
  
  # Extract all text nodes after image 'graphic-bc.jpg'
  Body_Count <- xpathSApply(parsed.html, "//img[@src='graphic-bc.jpg']/following::text()", xmlValue)
  
  # Remove all letters, keep numbers only
  Body_Count <- gsub('[^0-9]+', ' ', Body_Count)
  
  # Select first non-empty element of vector. This is were the number of deaths
  # lies.
  Body_Count <- Body_Count[which(Body_Count != ' ')[1]]
  
  # Split the character string at spaces
  Body_Count <- unlist(strsplit(Body_Count, ' '))
  
  # Transform characters into numbers
  Body_Count <- as.numeric(Body_Count)
  
  # Sum up the numbers (in case they have been split into separate categories,
  # which happened for some movies) and save
  Body_Count <- sum(Body_Count, na.rm = TRUE)
    
  return(data.frame(IMDB_URL, Film, Year, Body_Count))
}))

# Save scraped data in a .csv file for future use
write.csv(data, "movies-R.csv", row.names = FALSE)





