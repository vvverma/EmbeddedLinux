OUTPUT = $(shell date +'%Y%m%d')
BUILD_DIR = $(shell pwd)
DEPLOY = $(BUILD_DIR)/deploy
U-BOOT = $(BUILD_DIR)/u-boot
LINUX_VER ?= linux-4.14.18
KERNEL := $(BUILD_DIR)/kernel/$(LINUX_VER)
BUSYBOX = $(BUILD_DIR)/busybox
CONFIGS = $(BUILD_DIR)/configs
LCONFIG ?= omap2plus_defconfig
UCONFIG ?= am335x_boneblack_defconfig
KLOAD_ADDR ?= 0X80008000  
TARGET_ARCH ?= arm
TARGET_FS = target
BUILD_ARGS = ARCH=$(TARGET_ARCH)\
	     CROSS_COMPILE=${CC} #CHECK FOR CROSS-TOOL CHAIN LOADED IN ENV



check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))

__check_defined = \
    $(if $(value $1),, \
        $(error Undefined $1$(if $2,  \
          ($2))$(if $(value @), required by target `$@`)))


all:  u-boot linux busybox-defconfig busybox busybox-dist


u-boot-clean:	   
	$(MAKE) -C $(U-BOOT) $(BUILD_ARGS) distclean

linux-clean:
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) distclean

busybox-clean:
	$(MAKE) -C $(BUSYBOX) $(BUILD_ARGS) distclean

deploy-clean:
	rm -rf  $(DEPLOY)/*	

clean: u-boot-clean busybox-clean linux-clean
	-rm 	.*_built
	-rm -rf  $(DEPLOY)/$(OUTPUT)




u-boot-defconfig:
	$(call check_defined, UCONFIG)	
	$(MAKE) -C $(U-BOOT) $(BUILD_ARGS) $(UCONFIG)

linux-defconfig:
	$(call checked_defined, LCONFIG)
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) $(LCONFIG)     

busybox-defconfig: 
	$(MAKE) -C $(BUSYBOX) $(BUILD_ARGS) defconfig




u-boot-menuconfig:
	$(MAKE) -C $(U-BOOT) $(BUILD_ARGS) menuconfig

linux-menuconfig:
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) menuconfig

busybox-menuconfig:
	$(MAKE) -C $(BUSYBOX) $(BUILD_ARGS) menuconfig




u-boot-savedefconfig:
	$(call check_defined,UCONFIG_FILE)
	$(MAKE) -C $(U-BOOT) savedefconfig
	cp $(U-BOOT)/defconfig $(CONFIGS)/$(addprefix uboot_, $(UCONFIG))
	cp $(U-BOOT)/defconfig $(U-BOOT)/configs/$(UCONFIG)

linux-savedefconfig:
	$(call checked_defined,LCONFIG)
	$(MAKE) -C $(KERNEL) savedefconfig
	cp $(KERNEL)/defconfig $(CONFIGS)/$(addprefix "kernel_", $(LCONFIG))
	cp $(KERNEL)/defconfig $(KERNEL)/arch/$(TARGET_ARCH)/configs/$(LCONFIG)




u-boot: $(OUTPUT)
	$(MAKE) -C $(U-BOOT) $(BUILD_ARGS)  
	cp $(U-BOOT)/MLO  $(DEPLOY)/$(OUTPUT)
	cp $(U-BOOT)/u-boot.bin $(DEPLOY)/$(OUTPUT) 
	cp $(U-BOOT)/u-boot.img $(DEPLOY)/$(OUTPUT) 
	touch ".$@_built"

linux: $(OUTPUT)
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) uImage dtbs LOADADDR=$(KLOAD_ADDR) -j4	
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS) -j4 modules
	cp $(KERNEL)/arch/$(TARGET_ARCH)/boot/uImage $(DEPLOY)/$(OUTPUT)/ 
	cp $(KERNEL)/arch/$(TARGET_ARCH)/boot/zImage $(DEPLOY)/$(OUTPUT)/ 
	cp $(KERNEL)/arch/$(TARGET_ARCH)/boot/dts/am335x-boneblack.dtb $(DEPLOY)/$(OUTPUT)/
	touch ".$@_built"

busybox: $(OUTPUT)
	mkdir -p $(DEPLOY)/$(OUTPUT)/$(TARGET_FS)
	$(MAKE) -C $(BUSYBOX) $(BUILD_ARGS) CONFIG_PREFIX=$(DEPLOY)/$(OUTPUT)/$(TARGET_FS) install
	$(MAKE) -C $(KERNEL) $(BUILD_ARGS)  INSTALL_MOD_PATH=$(DEPLOY)/$(OUTPUT)/$(TARGET_FS) modules_install
	touch ".$@_built"




busybox-dist:
	cd $(DEPLOY)/$(OUTPUT); \
	tar -zcvf rootfs.tar.gz $(DEPLOY)/$(OUTPUT)/$(TARGET_FS) 

busybox-dist-clean:
	cd $(DEPLOY)/$(OUTPUT); \
	rm -rf rootfs.tar.gz 




$(OUTPUT):
	if [ ! -d "$(DEPLOY)/$(OUTPUT)" ];then \
	mkdir -p $(DEPLOY)/$(OUTPUT) ; fi

help:   
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | \ 
		sed -e 's/\\$$//' | sed -e 's/##//'



 
.PHONY: u-boot-menuconfig u-boot-savedefconfig u-boot-defconfig u-boot  linux-clean linux-defconfig linux-savdefconfig \
        linux-menuconfig linux busybox-clean busybox-menuconfig busybox-defconfig busybox busybox-dist busybox-dist-clean deploy-clean help  all
