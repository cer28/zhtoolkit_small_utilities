from ankisim import Card, Deck

print """
Simulation #6
-------------
What is the effect of forgetting on the daily review load?
"""


types = ('EMPIRICAL', 'SIMULATED', 'SIMULATED15', 'SIMULATED10', 'SIMULATED08', 'SIMULATED05', 'SIMULATED03', 'SIMULATED01', 'SIMULATED00')
#types = ('EMPIRICAL', 'SIMULATED', 'SIMULATED15', 'SIMULATED10', 'SIMULATED08', 'SIMULATED05', 'SIMULATED03', 'SIMULATED01', 'SIMULATED00')
#types = ('SIMULATED',)


for type in types:

	print type
	print "================"


	all_forecasts = []
	all_reviews = []
	all_lapserates = []
	all_lapses = []

	for run in range(5):

		forecasts = []
		reviews = []
		lapses = []

		#Set up cards
		deck = Deck()
		deck.maxPerDay = 200

		#Add 20 cards a day for the first 50 days
		for day in range(100):
			for x in range(20):
				c = Card( deck.currentDay )
				c.type = type
				deck.appendCard(c)

			deck.DoReviews(printSummary=False)

		#Do another 15 days of reviews
		for day in range(5):
			deck.DoReviews(printSummary=False)

		forecasts = deck.GetForecast(120)

		for x in range(120):
			stats = deck.DoReviews(printSummary=True)
			#print stats
			reviews.append(stats[2])
			lapses.append(stats[4])

		#print forecasts
		#print reviews
		#print lapses
		#print
		
		all_forecasts.append(forecasts)
		all_reviews.append(reviews)
		all_lapses.append(lapses)
		all_lapserates.append( 1.0 * sum(lapses) / sum(reviews) )


	#print all_forecasts
	#print all_reviews
	#print all_lapserates

	import numpy as np
	
	#print np.array(all_forecasts).mean(axis=0)
	#print np.array(all_reviews).mean(axis=0)
	#print np.array(all_lapserates).mean()

	print "\t".join( str(x) for x in np.array(all_forecasts).mean(axis=0).tolist() )
	print "\t".join( str(x) for x in np.array(all_reviews).mean(axis=0).tolist()   )
	print "\t".join( str(x) for x in np.array(all_lapses).mean(axis=0).tolist()   )
	#print np.array(all_forecasts).mean(axis=0).tolist()
	#print np.array(all_reviews).mean(axis=0).tolist()
	print np.array(all_lapserates).mean()
	print
	

#
#
#
#deck.LogReschedules = True
#
#for x in range(120):
#
#	print "%d\tBefore run: Lapsed:\t%d\tRelearn\t%d\tReschedule\t%d" % (
#		deck.currentDay,
#		len( [c for c in deck._cards if c.IsDue(deck.currentDay) and c.reschedule == 'LAPSED'] ),
#		len( [c for c in deck._cards if c.IsDue(deck.currentDay) and c.reschedule == 'RELEARN'] ),
#		len( [c for c in deck._cards if c.IsDue(deck.currentDay) and c.reschedule == 'RESCHEDULE'] )
#		)
#	
#	deck.DoReviews(printSummary=True)
