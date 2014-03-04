import sqlite3
import sys
from os import getenv

print """
Tabulating the counts of each transition of the ease values
-----------------------------------------------------------
This script will query your local Anki database (read-only) for the
ease values of all the answers. This will give the count of
an ease answer for an average card based on its last ease. The raw
totals can be converted into percent value, which will represent the
probability distribution of answering a card with a particular ease.
These probabilities can be programmed into the ankisim.py Card class,
to utilize when creating new cards.
"""

#This is Windows-specific, so adjust accordingly for Mac or Linux
dbfile = getenv('USERPROFILE') + "/Documents/Anki/User 1/collection.anki2"


class Card:
	def __init__(self):
		self._revs = []

	_revs = []
	
	def addRev(self, record):
		ease = record[2]
		if ease == 2 and record[3] < 0:
			ease = 1.5

		self._revs.append( [ record[0], record[1], ease, record[3], record[4], record[5], record[6], record[7] ] )

	def addEdges(self, mat):
		map = { 0:0, 1:1, 1.5:2, 2:3, 3:4, 4:5 }

		for x in range(len(self._revs)):
			if x == 0:
				old = 0
			else:
				old = map[self._revs[x - 1][2]]

			new = map[self._revs[x][2]]

			mat[old][new] += 1


	def RevString(self):
		return [ str(record[2]) + ':' + str(record[3]) + ':' + str(record[5]) + ':' + str(record[7]) for record in self._revs];


conn = sqlite3.connect(dbfile)
cursor = conn.cursor()

cards = {}

# compute the sum of all transitions. New, Learning 1, 2, 3, 4
mat = [[0]*6 for i in range(6)]

cursor.execute("""
    select cid, id, ease, ivl, lastIvl, factor, time, type
      from revlog
     where cid in (
        select id from cards
         --where did in ('1371780570449')
    )
    order by cid, id""")

for record in cursor.fetchall():
	if record[0] not in cards:
		cards[ record[0] ] = Card()
	
	cards[ record[0] ].addRev( record )
	#break
	

for card in cards:
	cards[card].addEdges( mat )

#Uncomment this to get the list of all the transitions in order for each card.
#for card in cards:
#	print cards[ card ].RevString()

print "Raw count of transitions"
print "========================\n"
print "\t", "\t".join([str(x) for x in xrange(len(mat))])
for i, x in enumerate(mat):
	print i, "\t", "\t".join([str(y) for y in x])


print "\n\nNormalized transitions"
print     "======================\n"
print "\t", "\t".join([str(x) for x in xrange(len(mat))])
for i, x in enumerate(mat):
	total = sum(x)
	print i, "\t", "\t".join([str( round(1.0 * y/total, 3)) for y in x])
