import matplotlib
import matplotlib.pyplot as plt


#colours for graphs
dueYoungC = "#ffb380"
dueMatureC = "#ff5555"
dueCumulC = "#ff8080"

reviewNewC = "#80ccff"
reviewYoungC = "#3377ff"
reviewMatureC = "#0000ff"
reviewTimeC = "#0fcaff"

easesNewC = "#80b3ff"
easesYoungC = "#5555ff"
easesMatureC = "#0f5aff"

addedC = "#b3ff80"
firstC = "#b380ff"
intervC = "#80e5ff"



try:
    from matplotlib.figure import Figure
except UnicodeEncodeError:
    # haven't tracked down the cause of this yet, but reloading fixes it
    try:
        from matplotlib.figure import Figure
    except ImportError:
        pass
except ImportError:
    pass



width, height, dpi = 8, 3, 75


#fig = Figure(figsize=(width, height), dpi=dpi)

fig, graph = plt.subplots()

#graph = fig.add_subplot(111)
fig.figsize=(width, height)
fig.dpi = dpi


graph.set_xlim(xmin=0, xmax=30)
graph.set_xlabel("Day (0 = today)")

graph.set_ylabel("Cards Added")

points = (
	[0, 46],
	[1, 57],
	[2, 50],
	[3, 49],
	[4, 32],
	[5, 31],
	[6, 36],
	[7, 30],
	[8, 38],
	[9, 33],
	[10, 29],
	[11, 23],
	[12, 31],
	[13, 22],
	[14, 18],
	[15, 16],
	[16, 18],
	[17, 11],
	[18, 16],
	[19, 15],
	[20, 7],
	[21, 23],
	[22, 18],
	[23, 9],
	[24, 10],
	[25, 9],
	[26, 9],
	[27, 10],
	[28, 11],
	[29, 7]
)


for p in points:
	graph.bar(p[0], p[1], color=dueYoungC, width=1, linewidth=1)

plt.show()
