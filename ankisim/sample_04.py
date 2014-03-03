from ankisim import Card, Deck

print """
Simulation #4
-------------
Simulate adding 30 new cards every day fro a 3000 item list, to
see how the queue progresses. This simulates cramming of 3000
characters by learning 30 new ones a day.
"""

numToLearn = 3000

deck = Deck()
deck.maxPerDay = 200

for day in xrange(200):
	for x in xrange( min(30, numToLearn - len(deck.cards()) )  ):
		c = Card( deck.currentDay )
		c.type = 'SIMULATED'
		deck.appendCard( c )

	deck.DoReviews(printSummary=True)