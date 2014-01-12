"""
Copyright 2014 Randal S. Olson

This file is a script that scrapes on-screen body counts for various movies on
www.MovieBodyCounts.com. The script requires an internet connection and two libraries
installed: urllib2 and html2text.

Due to inconsistent formatting of the HTML on www.MovieBodyCounts.com, the script will
not scrape everything perfectly. As such, the resulting output file *will* require some
cleanup afterwards.


This script is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this script.
If not, see http://www.gnu.org/licenses/.
"""

import string

# urllib2 reads web pages if you provide it an URL
import urllib2

# html2text converts HTML to Markdown, which is much easier to parse
from html2text import html2text

# Generate a list of all letters for the Movie pages (+ a "numbers" page)
# MovieBodyCount's actor pages are all with capital letters EXCEPT v and x
letters = ["numbers"] + list(string.letters[26:52].replace("V", "v").replace("X", "x"))

list_of_films = []

# Go through each movie list page and gather all of the movie web page URLs
for letter in letters:
    try:
        # Read the raw HTML from the web page
        page_text = urllib2.urlopen("http://www.moviebodycounts.com/movies-" + letter + ".htm").read()
		
        # Convert the raw HTML into Markdown
        page_text = html2text(page_text).split("\n")
		
        # Search through the web page for movie page entries
        for line in page_text:
            # We know it's a movie page entry when it has ".htm" in it, but not ".jpg", "contact.htm", and "movies.htm"
            # Try looking at the raw Markdown to see why this is
            if ".htm" in line and ".jpg" not in line and "contact.htm" not in line and "movies.htm" not in line:
				#print line
				list_of_films.append(line.split("(")[-1].strip(")"))
				
    # If the movie list page doesn't exist, keep going
    except:
        print "\nerror with " + letter + "\n"


# Now that we have every movie web page URL, go through each movie page and extract the movie name, kill counts, etc.
out_file = open("film-death-counts.csv", "wb")
for film_page in list_of_films:

    try:
        # The information we're looking for on the page:
        film = ""
        year = ""
        kills = ""
        rating = ""
        directors = ""
        genre = ""
        
        # A flag indicating that we've found the film title on the page
        found_title = False
        
        # Read the page's raw HTML and convert it to Markdown (again) and go through each line
        for line in html2text(urllib2.urlopen("http://www.moviebodycounts.com/" + film_page).read()).split("\n"):
		
            # If we haven't found the title yet, these markers tell us we've found the movie title
            if not found_title and "!" not in line and "(" not in line and "[" not in line and line.strip() != "":
                film = line
                found_title = True
				
            # The kill counts are usually on a line with "Film:"
            if "Film:" in line:
                kills = line.split()[-1]

            # The genre(s) are usually on a line with "Genre"
            if "Genre" in line:
                genre = ""
				
                # If there's multiple genres, combine them with bars |
                try:
                    for gr in line.split(": ")[1].split(","):
                        gr = gr.strip()
                        gr = gr.split("]")[0].strip("[")
                        genre += gr + "|"
                    genre = genre.strip("|")
                except:
                    genre = ""

            # The director(s) are usually on a line with "Director"
            if "Director" in line:
                # Remove non-ASCII characters from the line
                # Sometimes directors have accents in their name
                line = line.encode("ascii", "replace")
				
                # If there's multiple genres, combine them with bars |
                try:
                    directors = line.split(":")[1].strip()
                    if "[" in directors:
                        directors = directors.strip("[").split("]")[0]
                except:
                    directors = ""
                
            # The rating is usually on a line with "Rating"
            if "Rating" in line:
                try:
                    rating = line.split(": ")[1].split()[0]
                    if rating.lower() == "rated":
                        rating = line.split(": ")[1].split()[1]
                except:
                    rating = ""

            # The year is usually on a line with "charts-year"
            if "charts-year" in line:
                year = line.split("[")[1].split("]")[0]
                
        out_file.write(film + "," + year + "," + kills + "," + rating + "," + genre + "," + directors + "\n")
            
    # If a movie page fails to open, print out the error and move on to the next movie
    except Exception as e:
        print film_page
        print e
        
out_file.close()
