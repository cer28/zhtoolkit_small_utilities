from ankisim import Card, Deck

print """
Simulation #5
-------------
Shows how the forecast for N days into the future doesn't
accurately reflect the number of cards actually asked on that day
"""



#Set up cards
deck = Deck()
deck.maxPerDay = 200
type = 'EMPIRICAL'

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


deck.DoReviews(printSummary=True)

print

for c in deck._cards:	print c
print

deck.PrintForecast(30)
print

#Now that the backlog is cleared, do more reviews but show the forecast on each day
for z in range(4):
	for x in range(7):
	  deck.DoReviews(printSummary=True)

	for c in deck._cards:	print c
	print

	deck.PrintForecast(30)
	print ""




"""
0	371
1	451
2	517
3	587
4	638
5	679
6	717
"""
