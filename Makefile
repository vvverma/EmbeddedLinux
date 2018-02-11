
FOLDER = $(shell date +'%y.%m.%d')
BUILD_DIR = $(shell pwd)
DEPLOY = $(BUILD_DIR)/deploy
U-BOOT = $(BUILD_DIR)/u-boot
KERNEL = $(BUILiD_DIR)/kernel
CONFIGS = $(BUILD_DIR)/configs/	
TARGET_ARCH = arm
BUILD_ARGS = ARCH=$(TARGET_ARCH)\
	     CROSS_COMPILE=${CC} #CHECK FOR CROSS-TOOL CHAIN LOADED IN ENV



check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))

__check_defined = \
    $(if $(value $1),, \
        $(error Undefined $1$(if $2,  \
          ($2))$(if $(value @), required by target `$@`)))


all: u-boot-clean u-boot-defconfig u-boot

u-boot-clean:  deploy-clean	   
	$(MAKE) -C $(U-BOOT)  $(BUILD_ARGS)   distclean
	echo $(STRING_PARSE)
u-boot-menuconfig:
	$(MAKE) -C $(U-BOOT)  $(BUILD_ARGS)   menuconfig

u-boot-defconfig:
	$(call check_defined, CONFIG_FILE)	
	$(MAKE) -C $(U-BOOT)  $(BUILD_ARGS)   $(CONFIG_FILE)

u-boot-savedefconfig:
	$(call check_defined,CONFIG_FILE)
	$(MAKE) -C $(U-BOOT) savedefconfig
	cp $(U-BOOT)/defconfig $(CONFIGS)/$(CONFIG_FILE)
	cp $(U-BOOT)/defconfig $(U-BOOT)/configs/$(CONFIG_FILE) 

u-boot:  $(FOLDER)
	$(MAKE) -C $(U-BOOT) $(BUILD_ARGS)  
	cp $(U-BOOT)/MLO  $(DEPLOY)/$(FOLDER)
	cp $(U-BOOT)/u-boot.bin $(DEPLOY)/$(FOLDER) 

deploy-clean:
	rm -rf  $(DEPLOY)/$(FOLDER)/*	

$(FOLDER):
	if [ ! -d "$(DEPLOY)/$(FOLDER)" ];then \
	mkdir -p $(DEPLOY)/$(FOLDER) ; fi

help:   
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | \ 
		sed -e 's/\\$$//' | sed -e 's/##//'
 
.PHONY: u-boot-menuconfig u-boot-savedefconfig u-boot-defconfig u-boot deploy-clean help  all
