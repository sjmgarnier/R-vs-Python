"""
Copyright 2014 Randal S. Olson

This file is a script that makes pretty bar charts. It was written to be executed
in IPython Notebook.

This script is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this script.
If not, see http://www.gnu.org/licenses/.
"""

%pylab inline
from pandas import *

# read the data into a data frame, divide the body counts by the length of the film, and only keep the top 25 highest
body_count_data = read_csv("http://files.figshare.com/1332945/film_death_counts.csv")
body_count_data["Deaths_Per_Minute"] = body_count_data["Body_Count"].apply(float).values / body_count_data["Length_Minutes"].values
body_count_data = body_count_data.sort("Deaths_Per_Minute", ascending=False)[:25]
body_count_data = body_count_data.sort("Deaths_Per_Minute", ascending=True)

# generate the full titles for the movies: movie name (year)
full_title = []

for film, year in zip(body_count_data["Film"].values, body_count_data["Year"].values):
    full_title.append(film + " (" + str(year) + ")")
    
body_count_data["Full_Title"] = array(full_title)

# plot the bars
fig = plt.figure(figsize=(8,12))
rects = plt.barh(range(len(body_count_data["Deaths_Per_Minute"])), body_count_data["Deaths_Per_Minute"], height=0.8, align="center", color="#8A0707", edgecolor="none")

# plot styling
yticks(range(len(body_count_data["Full_Title"])), body_count_data["Full_Title"].values, fontsize=14)
xticks(arange(0, 5, 1), [""])
ax = axes()
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_visible(False)
ax.spines['bottom'].set_visible(False)
g = ax.yaxis.tick_left()
ax.tick_params(axis="y", color="#8A0707")
ax.tick_params(axis="x", color="white")
ax.xaxis.grid(color="white", linestyle="-")
ax.xaxis.tick_bottom()

# this function adds the deaths per minute label to the right of the bars
def autolabel(rects):
    for i, rect in enumerate(rects):
        width = rect.get_width()
        txt = str(round(float(width), 2)) + " (" + str(body_count_data["Length_Minutes"].values[i]) + " mins)"
        plt.text(width + 0.25, rect.get_y() + rect.get_height() / 2., txt, ha="left", va="center", fontsize=14)

autolabel(rects)

savefig("25-Violence-Packed-Films.png", bbox_inches="tight")
