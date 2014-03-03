from ankisim import Card, Deck

print """
Simulation #2
-------------
Simulate adding 1000 new cards on day 0, observing
the number of backlogged cards as dependent on the
maximum cards asked per day.
"""


for maxPerDay in [100, 150, 200, 500, 1000]:
	deck = Deck()
	deck.maxPerDay = maxPerDay

	print "Max per day: %d" % maxPerDay

	for x in xrange(1000):
		c = Card(0)
		c.type = 'SIMULATED'
		#c.ease = 2
		deck.appendCard( c )

	for x in xrange(100):
		deck.DoReviews(printSummary=True)

	print
