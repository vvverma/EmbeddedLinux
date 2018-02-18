FOLDER = $(shell date +'%Y%m%d')
BUILD_DIR = $(shell pwd)
DEPLOY = $(BUILD_DIR)/deploy
U-BOOT = $(BUILD_DIR)/u-boot
KERNEL = $(BUILD_DIR)/kernel/linux-4.14.18
CONFIGS = $(BUILD_DIR)/configs
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


all: u-boot-clean u-boot-defconfig u-boot linux-clean linux-defconfig linux


u-boot-clean:  deploy-clean	   
	$(MAKE) -C $(U-BOOT)  $(BUILD_ARGS)   distclean

u-boot-menuconfig:
	$(MAKE) -C $(U-BOOT)  $(BUILD_ARGS)   menuconfig

u-boot-defconfig:
	$(call check_defined, UCONFIG)	
	$(MAKE) -C $(U-BOOT)  $(BUILD_ARGS)   $(UCONFIG)

u-boot-savedefconfig:
	$(call check_defined,UCONFIG_FILE)
	$(MAKE) -C $(U-BOOT) savedefconfig
	cp $(U-BOOT)/defconfig $(CONFIGS)/$(addprefix uboot_, $(UCONFIG))
	cp $(U-BOOT)/defconfig $(U-BOOT)/configs/$(UCONFIG)

u-boot: $(FOLDER)
	$(MAKE) -C $(U-BOOT) $(BUILD_ARGS)  
	cp $(U-BOOT)/MLO  $(DEPLOY)/$(FOLDER)
	cp $(U-BOOT)/u-boot.bin $(DEPLOY)/$(FOLDER) 

linux-clean:
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) distclean

linux-menuconfig:
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) menuconfig

linux-defconfig:
	$(call checked_defined, LCONFIG)
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) $(LCONFIG)     

linux-savedefconfig:
	$(call checked_defined,LCONFIG)
	$(MAKE) -C $(KERNEL) savedefconfig
	cp $(KERNEL)/defconfig $(CONFIGS)/$(addprefix "kernel_", $(LCONFIG))
	cp $(KERNEL)/defconfig $(KERNEL)/arch/$(TARGET_ARCH)/configs/$(LCONFIG)

linux: $(FOLDER)
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) uImage dtbs LOADADDR=0x80008000 -j4	
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) -j4 modules
	cp $(KERNEL)/arch/$(TARGET_ARCH)/boot/uImage $(DEPLOY)/$(FOLDER)/ 
	cp $(KERNEL)/arch/$(TARGET_ARCH)/boot/dts/am335x-boneblack.dtb $(DEPLOY)/$(FOLDER)/

deploy-clean:
	rm -rf  $(DEPLOY)/$(FOLDER)/*	

$(FOLDER):
	if [ ! -d "$(DEPLOY)/$(FOLDER)" ];then \
	mkdir -p $(DEPLOY)/$(FOLDER) ; fi

help:   
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | \ 
		sed -e 's/\\$$//' | sed -e 's/##//'
 
.PHONY: u-boot-menuconfig u-boot-savedefconfig u-boot-defconfig u-boot  linux-clean linux-defconfig linux-savdefconfig linux-menuconfig linux deploy-clean help  all
