import urllib2
from html2text import html2text
import string

letters = ["numbers"] + list(set(list(string.letters.lower())))
list_of_films = []

for letter in letters:
    try:
        page_text = html2text(urllib2.urlopen("http://www.moviebodycounts.com/movies-" + letter + ".htm").read()).split("\n")
        for line in page_text:
            if ".htm" in line and ".jpg" not in line and "_" in line:
                list_of_actors.append(line.split("(")[1].strip(")"))
    except:
        print "error with " + letter
        pass
    
with open("deadly-film-list.csv", "wb") as out_file:
    for film in list_of_films:
        out_file.write(film + "\n")

movie_pages = []

with open("deadly-film-list.csv") as in_file:
    for line in in_file:
        line = line.strip()
        movie_pages.append(line)
        
out_file = open("film-death-counts.csv", "wb")
        
for mp in movie_pages:
    
    try:
        film = ""
        year = ""
        kills = ""
        rating = ""
        directors = ""
        genre = ""
        
        found_title = False
        
        for line in html2text(urllib2.urlopen("http://www.moviebodycounts.com/" + mp).read()).split("\n"):
		
            if not found_title and "!" not in line and "(" not in line and "[" not in line and line.strip() != "":
                film = line
                found_title = True
                
            if "Film:" in line:
                kills = line.split()[-1]
                
            if "Genre" in line:
                genre = ""
                try:
                    for gr in line.split(": ")[1].split(","):
                        gr = gr.strip()
                        gr = gr.split("]")[0].strip("[")
                        genre += gr + "|"
                    genre = genre.strip("|")
                except:
                    genre = ""

            if "Director" in line:
                line = line.encode("ascii", "replace")
                try:
                    directors = line.split(":")[1].strip()
                    if "[" in directors:
                        directors = directors.strip("[").split("]")[0]
                except:
                    directors = ""
                
            if "Rating" in line:
                try:
                    rating = line.split(": ")[1].split()[0]
                    if rating.lower() == "rated":
                        rating = line.split(": ")[1].split()[1]
                except:
                    rating = ""
                
            if "charts-year" in line:
                year = line.split("[")[1].split("]")[0]
                
        out_file.write(film + "," + year + "," + kills + "," + rating + "," + genre + "," + directors + "\n")
            
    except Exception as e:
        print mp
        print e
        
out_file.close()
