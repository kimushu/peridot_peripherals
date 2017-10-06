#ifndef __PERIDOT_SPI_FLASH_H__
#define __PERIDOT_SPI_FLASH_H__

#include "system.h"

#if defined(PERIDOT_SPI_FLASH_ENABLE) || defined(PERIDOT_SWI_FLASH_ENABLE)

#include "sys/alt_flash_dev.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PERIDOT_SPI_FLASH_INSTANCE(name, state) \
    ; peridot_spi_flash_dev state##_flash

#define PERIDOT_SPI_FLASH_INIT_ARGS \
    , peridot_spi_flash_dev *flash_dev, const char *flash_name

#define PERIDOT_SPI_FLASH_INIT_PASS(name, state) \
    , &state##_flash, name##_NAME "_flash"

#define PERIDOT_SPI_FLASH_INIT_CALL() \
    peridot_spi_flash_init(flash_dev, flash_name)

typedef struct peridot_spi_flash_dev_s
{
  alt_flash_dev dev;
  alt_u8 erase_inst;
  alt_u8 four_bytes_mode;
  alt_u16 page_size;
}
peridot_spi_flash_dev;

extern void peridot_spi_flash_init(peridot_spi_flash_dev *dev, const char *name);

extern int peridot_spi_flash_command(alt_u32 write_length, const alt_u8 *write_data,
                                     alt_u32 read_length, alt_u8 *read_data, alt_u32 flags);

#define PERIDOT_SPI_FLASH_MERGE     (0x0400)

#ifdef __cplusplus
}   /* extern "C" */
#endif

#else   /* !PERIDOT_SPI_FLASH_ENABLE && !PERIDOT_SWI_FLASH_ENABLE */

#define PERIDOT_SPI_FLASH_INSTANCE(name, state)
#define PERIDOT_SPI_FLASH_INIT_ARGS
#define PERIDOT_SPI_FLASH_INIT_PASS(name, state)
#define PERIDOT_SPI_FLASH_INIT_CALL()   do {} while (0)

#endif  /* !PERIDOT_SPI_FLASH_ENABLE && !PERIDOT_SWI_FLASH_ENABLE */

#if defined(PERIDOT_SPI_FLASH_BOOT_ENABLE) || defined(PERIDOT_SWI_FLASH_BOOT_ENABLE)

#define PERIDOT_SPI_FLASH_BOOT_INSTANCE(name, state) \
    ; extern int __reset_spi_flash; void * const name##_reset = &__reset_spi_flash

#else   /* !PERIDOT_SWI_FLASH_BOOT_ENABLE && !PERIDOT_SWI_FLASH_BOOT_ENABLE */

#define PERIDOT_SPI_FLASH_BOOT_INSTANCE(name, state)

#endif  /* !PERIDOT_SWI_FLASH_BOOT_ENABLE && !PERIDOT_SWI_FLASH_BOOT_ENABLE */

#endif  /* __PERIDOT_SPI_FLASH_H__ */
