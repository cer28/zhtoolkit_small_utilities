from ankisim import Card, Deck
import sqlite3
from os import getenv

print """
Simulation #3
-------------
An example starting from historical data from Anki. The settings in the Anki database
query are specific to my settings: day 200 on deck 1371780570449.
"""

deck = Deck()
deck.maxPerDay = 150

#Windows-specific 
dbfile = getenv('USERPROFILE') + "/Documents/Anki/User 1/collection.anki2"
conn = sqlite3.connect(dbfile)
cursor = conn.cursor()

cursor.execute("""
    select C.id, R.ease, R.ivl, R.lastIvl, due - 201 as countdown, case when R.ease = 2 and R.type = 2 then 1 else 0 end as isLapsed, R.factor
    from cards C
    join (select cid, max(id) AS id from revlog group by cid) Rmax ON Rmax.cid = C.id
    join revlog R on R.cid =  Rmax.cid AND R.id = Rmax.id
    --where queue = 2
    where C.type = 2
    and did in ('1371780570449')
    and queue in (2,3)
    """
)

for record in cursor.fetchall():
    c = Card(0)
    # Note that the day is being fudged into the past, in order to force the due date for the earliest cards to today
    c.SetData( type='EMPIRICAL', ease=record[1], lastease=None, interval=record[2], lastInterval=record[3], day=record[4] - record[2], isLapsed=record[5], factor=record[6] )
    #print c.ToString()

    deck.appendCard( c )


print """
-------------
a) Run through 20 days of reviews
"""

for x in xrange(20):
    deck.DoReviews(printSummary = True)


print """
-------------
b) Add 25 cards every 2 days, to see
how the queue develops
"""


if True:
    cards_to_add = 2409 - len( deck.cards() )

    for x in xrange(100):
        if x%2 == 1:
            for z in xrange( min(cards_to_add, 25)):
                c = Card( deck.currentDay )
                deck.appendCard( c )
                cards_to_add -= 1

        deck.DoReviews(printSummary = True)

