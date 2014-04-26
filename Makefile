COMPONENT=AnimalAppC
BUILD_EXTRA_DEPS = PingMsg.py GetFoodDailyDosage.py UpdateFoodDailyDosage.py GetFoodResponse.py
CLEAN_EXTRA = PingMsg.py *.pyc GetFoodDailyDosage.py UpdateFoodDailyDosage.py GetFoodResponse.py

PingMsg.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=PingMsg Animal.h PingMsg -o $@

GetFoodDailyDosage.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=GetFoodDailyDosage Animal.h GetFoodDailyDosage -o $@

UpdateFoodDailyDosage.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=UpdateFoodDailyDosage Animal.h UpdateFoodDailyDosage -o $@

GetFoodResponse.py: Animal.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=GetFoodResponse Animal.h GetFoodResponse -o $@
include $(MAKERULES)
