from ankisim import Card, Deck

print """
Simulation #5b
-------------
What is the relative contribution of lapsed vs. rescheduled cards to the forecast?
"""



#Set up cards
deck = Deck()
deck.maxPerDay = 200
type = 'SIMULATED05'

#Add 20 cards a day for the first 50 days
for day in range(100):
  for x in range(20):
    c = Card( deck.currentDay )
    c.type = type
    deck.appendCard(c)
  deck.DoReviews(printSummary=False)

#Do another 15 days of reviews
for day in range(5):
  deck.DoReviews(printSummary=True)


print

deck.PrintForecast(120)

print


deck.LogReschedules = True

for x in range(120):

	print "%d\tBefore run: Lapsed:\t%d\tRelearn\t%d\tReschedule\t%d" % (
		deck.currentDay,
		len( [c for c in deck._cards if c.IsDue(deck.currentDay) and c.reschedule == 'LAPSED'] ),
		len( [c for c in deck._cards if c.IsDue(deck.currentDay) and c.reschedule == 'RELEARN'] ),
		len( [c for c in deck._cards if c.IsDue(deck.currentDay) and c.reschedule == 'RESCHEDULE'] )
		)
	
	deck.DoReviews(printSummary=True)
