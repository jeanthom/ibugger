NAME ?= flasher
LS = ls.x

LIBGCC = /cygdrive/c/programme/gnuarm/lib/gcc/arm-elf/4.1.1/libgcc.a

CROSS  ?= arm-elf-
AS      = $(CROSS)as
CC      = $(CROSS)gcc
LD      = $(CROSS)ld
NM      = $(CROSS)nm
OBJCOPY = $(CROSS)objcopy
CFLAGS += -Os -W -Wall -ffreestanding -fomit-frame-pointer
LDFLAGS+= -T$(LS)

BIN   = $(NAME).bin
ELF   = $(NAME).elf
SYM   = $(NAME).sym
OBJS  = flasher.o

all: $(BIN)

$(ELF): $(OBJS) $(LS)
	$(LD) -Map $(NAME).map -o $@ $(OBJS) $(LIBS) $(LDFLAGS)

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

%.o: %.c
	$(CC) $(CFLAGS) -Wa,-alhn=$*.lst -c $< -o $@

%.o: %.S
	$(AS) -alhn=$*.lst $< -o $@

clean:
	$(RM) *.lst  $(NAME).map $(OBJS) $(BIN) $(ELF)
