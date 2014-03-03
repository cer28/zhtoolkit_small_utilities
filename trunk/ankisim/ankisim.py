import random

class Card:

	#Defines the transition probabilities for a card. Parameter Card.type needs to match
	#one of these keywords
	transitions = {
		'EMPIRICAL': [
			[ 0.0, 0.628, 0.133, 0.239, 0.0 ],
			[ 0.0, 0.148, 0.852, 0.000, 0.000 ],  #lapsed. This row is oversimplified in the model, because it assumes success is the same for new cards and for relearning lapsed cards
			[ 0.0, 0.169, 0.155, 0.189, 0.486 ],
			[ 0.0, 0.199, 0.185, 0.212, 0.404 ],
			[ 0.0, 0.142, 0.111, 0.170, 0.577 ]],
		'SIMULATED': [
			[ 0.0, 0.15, 0.25, 0.60, 0.0 ],
			[ 0.0, 0.10, 0.90, 0.0, 0.0 ],  #lapsed
			[ 0.0, 0.15, 0.25, 0.4, 0.2 ],
			[ 0.0, 0.15, 0.2, 0.35, 0.3 ],
			[ 0.0, 0.05, 0.15, 0.2, 0.6 ]],
		'EASY': [
			[ 0.0, 0.0,   0.0,   1.0, 0.0 ],
			[ 0.0, 0.0,   0.1,   0.0,   0.0 ],  #lapsed
			[ 0.0, 0.0, 0.0, 0.0, 1.0 ],
			[ 0.0, 0.0, 0.0, 0.0, 1.0 ],
			[ 0.0, 0.0, 0.0, 0.0, 1.0 ]],
		'HARD': [
			[ 0.0, 0.50, 0.25, 0.25, 0.0 ],
			[ 0.0, 0.33, 0.67, 0.0, 0.0 ],  #lapsed
			[ 0.0, 0.40, 0.25, 0.25, 0.10 ],
			[ 0.0, 0.35, 0.25, 0.25, 0.15 ],
			[ 0.0, 0.25, 0.25, 0.25, 0.25 ]]
	}

	gCardNum = 0
	
	startingFactor = 2500   # conf['new']['initialFactor'] => 2500
	lapseInterval = 1	   # conf['minInt'] = 1
	lapseMultiplier = 0	 # conf['lapsed']['mult'] => 0
	reviewIntervalFactor = 1   # dconf['ivlFct'] => 1   
	reviewMaxInterval = 36500 # dconf['maxIvl'] => 36500
	reviewEase4Bonus = 1.3  # dconf['rev']['ease4'] => '1.3'
	newGraduateInterval = [ 1, 4, 7 ] # dconf['new']['ints'] = [ 1, 4, 7 ]


	def __init__(self, dueday):
		self.type = 'SIMULATED'
		self.ease = 0
		self.lastease = 0
		self.interval = 0
		self.dueday = dueday  # interval + day it was last asked on
		self.lastInterval = 0
		self.isLapsed = False
		self.factor = Card.startingFactor
		self.dailyLog = []
		self.answerLog = []
		Card.gCardNum += 1
		self.cardNum = Card.gCardNum

	def ToString(self):
		return 'Card: {interval=%d, dueday=%d, isLapsed=%s, factor=%d}' % (self.interval, self.dueday, self.isLapsed, self.factor)
		
	def SetData(self, type, ease, lastease, interval, lastInterval, day, isLapsed, factor):
		self.type = type
		self.ease = ease
		self.lastease = lastease
		self.interval = interval
		self.lastInterval = lastInterval
		self.dueday = day + interval
		self.isLapsed = isLapsed
		self.factor = factor

	def IsDue(self, day):
		return (self.dueday <= day)

	def IsMature(self):
		return ( self.lastInterval >= 21 )

	def Answer(self, day):
		self._GetRandomAnswer()
		self._Reschedule(day)
		self.dailyLog.append( [True, self.ease, self.interval, self.lastInterval, self.isLapsed, self.factor] )

	def _GetRandomAnswer(self):
		r = random.random()
		s = 0.0

		dist = Card.transitions[ self.type ][ self.ease ]

		for w in range(len(dist)):
			s += dist[w]
			#print r, s, w, dist[w]
			if s > r:
				break
				#self.ease = w

		self.lastease = self.ease
		self.ease = w
		if self.ease == 1 and self.lastease > 1:
			self.isLapsed = True
			#self.ease = 2
		else:
			self.isLapsed = False
			
	
	
	def _Reschedule(self, day):
		"""This is directly from the Anki scheduler code"""

		self.lastInterval = self.interval

		if self.isLapsed:  #card was lapsed, but it's also to be asked again today
			self.interval = 0
			#self.interval = max( Card.lapseInterval, int(self.interval * Card.lapseMultiplier) )
			self.factor = max(1300, self.factor-200)
		elif self.ease == 1 and self.lastease == 1:
			pass
		elif self.lastease == 0:	# new card
			if self.ease < 2:  # still learning
				self.interval = 0
			else:
				self.interval = Card.newGraduateInterval[ self.ease - 2 ]   # i.e., 1 day for hard and 4 days for easy
				self.factor = Card.startingFactor
		else:
			if self.lastease == 1:
				self.interval = max( Card.lapseInterval, int(self.interval * Card.lapseMultiplier) )
			else:
				self.interval = self._nextRevIvl(day)
				# the factor for a lapsed card has already been calculated
				self.factor = max(1300, self.factor + [-150, 0, 150][self.ease-2])

#		if self.ease != 1:
		self.dueday = day + self.interval

	def _nextRevIvl(self, day):
		"""directly from Anki 2 sched.py"""
		delay = max( -1 * (self.dueday - day), 0)
		fct = self.factor / 1000

		ivl2 = self._constrainedIvl((self.interval + delay // 4) * 1.2, self.interval)
		ivl3 = self._constrainedIvl((self.interval + delay // 2) * fct, ivl2)
		ivl4 = self._constrainedIvl((self.interval + delay) * fct * Card.reviewEase4Bonus, ivl3)
		if self.ease == 2:
			interval = ivl2
		elif self.ease == 3:
			interval = ivl3
		elif self.ease == 4:
			interval = ivl4
		# interval capped?
		return min(interval, Card.reviewMaxInterval)

	def _constrainedIvl(self, ivl, prev):
		"""(From Anki 2 sched.py) Integer interval after interval factor and prev+1 constraints applied."""
		new = ivl * Card.reviewIntervalFactor
		return int(max(new, prev+1))




class Deck:
	rescheduleTypes = ('FailToEnd', 'FailToTenth')

	def __init__(self):
		pass
		self.maxPerDay = 100  # conf.decks(json) [1][rev][perDay] : 100
		self.currentDay = 0
		self._cards = []
		self.rescheduleType = Deck.rescheduleTypes[0]

	def appendCard(self, card):
		self._cards.append(card)

	def cards(self):
		return self._cards

	def DoReviews(self, printSummary = False):
		numReviewed = 0
		numPassed = 0
		numLapsed = 0
		numRelearn = 0 #count of reviews for lapsed cards still at ease=1
		toReview = [ c for c in self._cards if c.IsDue(self.currentDay) ]
		numScheduled = len(toReview)

		#it's not clear whether maxPerDay means the number of cards, number of reviews, or number of non-lapses/
		#It seems to mean the number of non-lapses in practice
		#while len(toReview) > 0 and numReviewed < self.maxPerDay:
		while len(toReview) > 0 and numPassed < self.maxPerDay and numReviewed < 100000:   # this number is a panic limit in case an impossible card would loop forever
			r = toReview.pop()
			r.Answer(self.currentDay)
			numReviewed += 1
			#if r.ease == 1:
			if r.ease < 2:
				if r.isLapsed:
					numLapsed += 1
				else:
					numRelearn += 1

				if (self.rescheduleType == 'FailToEnd'):
					toReview.append(r)
				elif (self.scheduleType == 'FailToTenth'):
					toReview.insert(  min( len(toReview), 10), r)
				else:
					print 'Unknown reschedule type: %s' % self.rescheduleType
			else:
				numPassed += 1
			

		if printSummary:
			print "numReviewed:\tday\t%d\treviews\t%d\tscheduled\t%d\tpassed\t%d\tlapsed\t%d\trelearn\t%d\tcards in deck:\t%d" % (self.currentDay, numReviewed, numScheduled, numPassed, numLapsed, numRelearn, len(self._cards))

		self.currentDay += 1
