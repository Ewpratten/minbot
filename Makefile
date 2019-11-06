CC=arm-linux-gnueabihf-gcc
TEAM=5024
IP_ADDR=roborio-$(TEAM)-frc.local
NI_VERSION=v2019-12

bootstrap:
	@echo ":: Fetching NI libraries"
	@printf "Found library for roborio version: "
	@curl https://raw.githubusercontent.com/wpilibsuite/ni-libraries/master/RequiredVersion.txt

	@echo ":: Using version: $(NI_VERSION)"
	@wget https://github.com/wpilibsuite/ni-libraries/archive/$(NI_VERSION).tar.gz 

	@echo ":: Unpacking libraries"
	@tar -zxvf $(NI_VERSION).tar.gz

	@mkdir -p include
	@mkdir -p lib

	@echo ":: Copying NI libraries to source folder"
	@cp -r ni-libraries-????-*/src/lib/* lib
	@cp -r ni-libraries-????-*/src/include/* include

	@echo ":: Removing NI library tarball"
	@rm -rf $(NI_VERSION).tar.gz*
	@rm -rf ni-libraries-????-*


clean:
	rm -rf robot-program

compile:
# Clean past builds
	@make -s clean

# Compile and link
	$(CC) robot.c -o robot-program

find-robot:
	@echo ":: Trying to find RoboRIO owned by team $(TEAM)"
	@ping -c 1 $(IP_ADDR)

deploy:
	@make -s find-robot

	@echo ":: Stopping robot"
	ssh $(IP_ADDR) '. /etc/profile.d/natinst-path.sh; /usr/local/frc/bin/frcKillRobot.sh -t 2> /dev/null; rm -f /home/lvuser/robot-program'

	@echo ":: Deploying robot code"
	scp robot-program $(IP_ADDR):~/robot-program
	ssh $(IP_ADDR) 'echo "/home/lvuser/robot-program" > robotCommand'

	@echo ":: Setting permissions, and resetting robot"
	ssh $(IP_ADDR) 'chmod +x /home/lvuser/robotCommand; chown lvuser /home/lvuser/robotCommand; \
					chmod +x /home/lvuser/robot-program; chown lvuser /home/lvuser/robot-program; \
                	sync; ldconfig; sleep 2; . /etc/profile.d/natinst-path.sh; /usr/local/frc/bin/frcKillRobot.sh -t -r' 


test:
	chmod +x robot-program
	./robot-program