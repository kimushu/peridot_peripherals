#ifndef __PERIDOT_SWI_REGS_H__
#define __PERIDOT_SWI_REGS_H__

#ifndef __ASSEMBLER__
#include <io.h>
#endif

/* CLASSID register (compatible with altera_avalon_sysid_qsys) */
#define PERIDOT_SWI_CLASSID_REG             0
#define IOADDR_PERIDOT_SWI_CLASSID(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_CLASSID_REG)
#define IORD_PERIDOT_SWI_CLASSID(base) \
  IORD(base, PERIDOT_SWI_CLASSID_REG)

/* TIMECODE register (compatible with altera_avalon_sysid_qsys) */
#define PERIDOT_SWI_TIMECODE_REG            1
#define IOADDR_PERIDOT_SWI_TIMECODE(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_TIMECODE_REG)
#define IORD_PERIDOT_SWI_TIMECODE(base) \
  IORD(base, PERIDOT_SWI_TIMECODE_REG)

/* UID register */
#define PERIDOT_SWI_UID_L_REG               2
#define IOADDR_PERIDOT_SWI_UID_L(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_UID_L_REG)
#define IORD_PERIDOT_SWI_UID_L(base) \
  IORD(base, PERIDOT_SWI_UID_L_REG)
#define PERIDOT_SWI_UID_H_REG               3
#define IOADDR_PERIDOT_SWI_UID_H(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_UID_H_REG)
#define IORD_PERIDOT_SWI_UID_H(base) \
  IORD(base, PERIDOT_SWI_UID_H_REG)

/* RSTSTS register */
#define PERIDOT_SWI_RSTSTS_REG              4
#define IOADDR_PERIDOT_SWI_RSTSTS(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_RSTSTS_REG)
#define IORD_PERIDOT_SWI_RSTSTS(base) \
  IORD(base, PERIDOT_SWI_RSTSTS_REG)
#define IOWR_PERIDOT_SWI_RSTSTS(base, data) \
  IOWR(base, PERIDOT_SWI_RSTSTS_REG, data)
#define PERIDOT_SWI_RSTSTS_RST_MSK          (0x1)
#define PERIDOT_SWI_RSTSTS_RST_OFST         (0)
#define PERIDOT_SWI_RSTSTS_LED_MSK          (0x2)
#define PERIDOT_SWI_RSTSTS_LED_OFST         (1)
#define PERIDOT_SWI_RSTSTS_UIDENA_MSK       (0x4000)
#define PERIDOT_SWI_RSTSTS_UIDENA_OFST      (14)
#define PERIDOT_SWI_RSTSTS_UIDVALID_MSK     (0x8000)
#define PERIDOT_SWI_RSTSTS_UIDVALID_OFST    (15)
#define PERIDOT_SWI_RSTSTS_KEY_MSK          (0xffff0000u)
#define PERIDOT_SWI_RSTSTS_KEY_OFST         (16)
#define PERIDOT_SWI_RSTSTS_KEY_VAL          (0xdead0000u)

/* FLASH register */
#define PERIDOT_SWI_FLASH_REG               5
#define IOADDR_PERIDOT_SWI_FLASH(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_FLASH_REG)
#define IORD_PERIDOT_SWI_FLASH(base)\
  IORD(base, PERIDOT_SWI_FLASH_REG)
#define IOWR_PERIDOT_SWI_FLASH(base, data) \
  IOWR(base, PERIDOT_SWI_FLASH_REG, data)
#define PERIDOT_SWI_FLASH_RXDATA_MSK        (0xff)
#define PERIDOT_SWI_FLASH_RXDATA_OFST       (0)
#define PERIDOT_SWI_FLASH_TXDATA_MSK        (0xff)
#define PERIDOT_SWI_FLASH_TXDATA_OFST       (0)
#define PERIDOT_SWI_FLASH_SS_MSK            (0x100)
#define PERIDOT_SWI_FLASH_SS_OFST           (8)
#define PERIDOT_SWI_FLASH_RDY_MSK           (0x200)
#define PERIDOT_SWI_FLASH_RDY_OFST          (9)
#define PERIDOT_SWI_FLASH_STA_MSK           (0x200)
#define PERIDOT_SWI_FLASH_STA_OFST          (9)
#define PERIDOT_SWI_FLASH_IRQENA_MSK        (0x8000)
#define PERIDOT_SWI_FLASH_IRQENA_OFST       (15)

/* MESSAGE register */
#define PERIDOT_SWI_MESSAGE_REG             6
#define IOADDR_PERIDOT_SWI_MESSAGE(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_MESSAGE_REG)
#define IORD_PERIDOT_SWI_MESSAGE(base) \
  IORD(base, PERIDOT_SWI_MESSAGE_REG)
#define IOWR_PERIDOT_SWI_MESSAGE(base, data) \
  IOWR(base, PERIDOT_SWI_MESSAGE_REG, data)

/* SWI register */
#define PERIDOT_SWI_SWI_REG                 7
#define IOADDR_PERIDOT_SWI_SWI(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SWI_SWI_REG)
#define IORD_PERIDOT_SWI_SWI(base) \
  IORD(base, PERIDOT_SWI_SWI_REG)
#define IOWR_PERIDOT_SWI_SWI(base, data) \
  IOWR(base, PERIDOT_SWI_SWI_REG, data)
#define PERIDOT_SWI_SWI_SWI_MSK             (0x1)
#define PERIDOT_SWI_SWI_SWI_OFST            (0)

#endif /* __PERIDOT_SWI_REGS_H__ */
