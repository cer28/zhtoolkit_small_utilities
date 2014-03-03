from ankisim import Card, Deck

print """
Simulation #1
-------------
Simulate a single card, showing how the interval and factor
changes based on the randomly generated ease.
"""

for type in ['EMPIRICAL', 'SIMULATED', 'EASY', 'HARD']:
	print "Card Type: %s" % type

	c = Card(0)
	c.type = type
	deck = Deck()
	deck.appendCard( c )

	for x in xrange(1000):
		if c.IsDue(deck.currentDay):
			toAsk = True
		else:
			toAsk = False

		deck.DoReviews(printSummary=False)

		if toAsk:
			print "....\tDay:\t%d\tEase:\t%d, Interval:\t%d\tDueDate:\t%d\tFactor:\t%d" % (x, c.ease, c.interval, c.dueday, c.factor)

	print
