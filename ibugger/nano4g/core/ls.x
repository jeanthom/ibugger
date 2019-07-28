OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm",
	      "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

SECTIONS
{
  . = 0x22000000;

  .text : { *(.text) } 

  __data_start__ = . ;
  .data : { *(.data) *(.rodata) }

  __clear_start__ = 0x22020000;
  debug_sendbuf = 0x22020000;
  debug_recvbuf = 0x22028000;
  debug_sendbuf_readptr = 0x22028610;
  debug_sendbuf_writeptr = 0x22028614;
  debug_recvbuf_readptr = 0x22028618;
  debug_recvbuf_writeptr = 0x2202861c;

  usb_sendbuf = 0x22028400;
  usb_recvbuf = 0x22028620;

  target_regs = 0x22028830;
  target_status = 0x22028878;

  debug_printf_lr = 0x2202887c;

  usb_ctrl_sendbuf = 0x22028880;
  usb_ctrl_recvbuf = 0x220288c0;

  supervisor_stack = 0x220288d8;
  exception_stack = 0x220288e0;

  debug_snprintf_buf = 0x220288e0;

  . = 0x220289e0;

  __bss_start__ = .;
  .bss : {
    *(.bss) *(COMMON);
    __bss_end__ = . ;
  }

  stack_top = 0x22030000;

  __clear_end__ = 0x22030000;

}