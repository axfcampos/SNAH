COMPONENT=AnimalAppC
BUILD_EXTRA_DEPS = PingMsg.py UpdateFoodDailyDosage.py AnimalInfo.py UpdateFeedingSpot.py Proximity.py #GetFoodDailyDosage.py GetFoodResponse.py
CLEAN_EXTRA = PingMsg.py *.pyc UpdateFoodDailyDosage.py AnimalInfo.py UpdateFeedingSpot.py Proximity.py #GetFoodResponse.py GetFoodDailyDosage.py

PingMsg.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=PingMsg Animal.h PingMsg -o $@

#GetFoodDailyDosage.py: Animal.h
#	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=GetFoodDailyDosage Animal.h GetFoodDailyDosage -o $@

AnimalInfo.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=AnimalInfo Animal.h AnimalInfo -o $@

UpdateFoodDailyDosage.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=UpdateFoodDailyDosage Animal.h UpdateFoodDailyDosage -o $@

UpdateFeedingSpot.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=UpdateFeedingSpot Animal.h UpdateFeedingSpot -o $@

Proximity.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=Proximity Animal.h Proximity -o $@


#GetFoodResponse.py: Animal.h
#	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=GetFoodResponse Animal.h GetFoodResponse -o $@

include $(MAKERULES)
