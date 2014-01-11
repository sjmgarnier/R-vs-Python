# Load libraries
library(RCurl);     # Everything necessary to grab webpage
library(XML);       # Everything necessary to parse HTML code
library(stringr);   # Everything necessary to work with strings

# Prepare URLs of the HTML files containing the list of movies by letters (first
# page are movies starting with a number)
urls.by.letter = paste('http://www.moviebodycounts.com/movies-', c("numbers", LETTERS), '.htm', sep='');

# Load HTML pages in memory
html.by.letter = getURL(urls.by.letter, async = FALSE);

# Grab URL for each movie
urls.by.movie = {};
for (i in 1:length(html.by.letter)) {
    # Parse HTML content
    parsed.html = htmlParse(html.by.letter[i]);
    
    # Extract desired links from HTML content. The desired links are those after
    # image 'graphic-movies.jpg' in the page
    links = as.vector(xpathSApply(parsed.html, "//img[@src='graphic-movies.jpg']/following::a/@href"));
    urls.by.movie = c(urls.by.movie, links);
}

# Of course some URLs are not formatted like the others, let's remove the extra
# characters
urls.by.movie = gsub('http://www.moviebodycounts.com/', '', urls.by.movie);

# And one URL is actually a shortcut to another page. Let's get rid of it.
id = which(urls.by.movie == "movies-C.htm");
urls.by.movie = urls.by.movie[-id];

# And now let's make the URLs complete
urls.by.movie = paste('http://www.moviebodycounts.com/', urls.by.movie, sep='');

# Ok, let's get serious now

# Prepare data frame
data = data.frame(Film = rep(NA, length(urls.by.movie)), Year = NA, Body_Count = NA, MPAA_Rating = NA, Genre = NA, Director = NA, Length_Minutes = NA, IMDB_rating = NA);

# Load HTML pages in memory. Will take some time because async = FALSE.
html.by.movie = getURL(urls.by.movie, async = FALSE);

for (i in 362:length(html.by.movie)) {
  # Parse HTML content
  parsed.html = htmlParse(html.by.movie[i]);
  
  # Extract all text nodes after image 'graphic-bc.jpg'
  text = xpathSApply(parsed.html, "//img[@src='graphic-bc.jpg']/descendant::text() | //img[@src='graphic-bc.jpg']/following::text()", xmlValue);
  
  # Remove all letters, keep numbers only
  text = gsub('[^0-9]+', ' ', text);
  
  # Select first non-empty element of vector. This is were the number of deaths
  # lies.
  deaths = text[which(text != ' ')[1]];
  
  # Split the character string at spaces
  deaths = unlist(strsplit(deaths, ' '));
  
  # Transform characters into numbers
  deaths = as.numeric(deaths);
  
  # Sum up the numbers (in case they have been split into separate categories,
  # which happened for some movies) and save
  data$Body_Count[i] = sum(deaths, na.rm = TRUE);
  
  # Now let's find this IMDB link to fill out the rest of the data frame
  imdb.url = as.vector(xpathSApply(parsed.html, "//a/@href[contains(.,'imdb')]"))[1];
  
  # Download IMDB page of movie
  imdb.html = getURL(imdb.url, .opts=curlOptions(followlocation=TRUE));
  
  # Parse HTML of IMDB page
  imdb.parsed.html = htmlParse(imdb.html);
  
  # Find title
  data$Film[i] = xpathSApply(imdb.parsed.html, "//h1[@class='header']/span[@class='itemprop']", xmlValue);
  
  # Find year
  data$Year[i] = as.numeric(gsub("[^0-9]", "", xpathSApply(imdb.parsed.html, "//h1[@class='header']/span[@class='nobr']", xmlValue)));

  # Find MPAA rating
  tmp = xpathSApply(imdb.parsed.html, "//div[@class='infobar']/span/@content");
  if (!is.character(tmp)) {   # Some movies don't have a MPAA rating
    tmp <- "UNRATED"
  } 
  data$MPAA_Rating[i] = tmp;
  
  # Find genre
  data$Genre[i] = paste(xpathSApply(imdb.parsed.html, "//span[@class='itemprop' and @itemprop='genre']", xmlValue), collapse='|');
  
  # Find director
  data$Director[i] = paste(xpathSApply(imdb.parsed.html, "//div[@itemprop='director']/a", xmlValue), collapse='|');
  
  # Find length of movie in minutes
  data$Length_Minutes[i] = as.numeric(gsub("[^0-9]", "", xpathSApply(imdb.parsed.html, "//div[@class='infobar']/time[@itemprop='duration']", xmlValue)));
  
  # Find IMDB rating
  data$IMDB_rating[i] = as.numeric(xpathSApply(imdb.parsed.html, "//div[@class='titlePageSprite star-box-giga-star']", xmlValue));

  print(paste('Film', i, 'of', length(html.by.movie), 'done.'));
}




