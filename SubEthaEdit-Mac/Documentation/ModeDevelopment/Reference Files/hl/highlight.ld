/* Example GNU LD Linker Script */
ENTRY(main)
OUTPUT_FORMAT(elf32-i386)

TEXT_VADDR = 0x00100000;
DATA_VADDR = 32M;
BSS_VADDR = 128M;

SECTIONS {
    . = TEXT_VADDR;
    .text ALIGN(PAGE_SIZE) : {
        *(.text)
    }
    . = DATA_VADDR;
    .data ALIGN(PAGE_SIZE) : {
        *(.data)
        *(.rodata)
    }
    . = BSS_VADDR;
    .bss ALIGN(PAGE_SIZE) : {
        *(.bss)
        *(COMMON)
    }
    /DISCARD/ : {
        *(.comment)
    }
}

