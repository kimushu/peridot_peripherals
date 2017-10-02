#ifndef __PERIDOT_SPI_MASTER_H__
#define __PERIDOT_SPI_MASTER_H__

#include "alt_types.h"
#ifdef __tinythreads__
# include <tthread.h>
#endif
#include "system.h"
#ifdef PERIDOT_SPI_FLASH_ENABLE
# include "sys/alt_flash_dev.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct peridot_spi_master_state_s
{
  const char *name;
  alt_u32 base;
  alt_u32 freq;
  alt_u32 irq_controller_id;
  alt_u32 irq;
  alt_8 slave_locked;
#ifdef __tinythreads__
  pthread_mutex_t lock;
  sem_t done;
#else
  volatile alt_u8 lock;
  volatile alt_u8 done;
#endif
#ifdef __PERIDOT_PFC_INTERFACE
  const struct peridot_pfc_map_out_s *ss_n_pfc_map;
#endif
}
peridot_spi_master_state;

#ifdef __PERIDOT_PFC_INTERFACE
typedef struct peridot_spi_master_pfc_map_s {
  peridot_spi_master_state *sp;
  const struct peridot_pfc_map_out_s *ss_n_pfc_map;
  const struct peridot_pfc_map_out_s *sclk_pfc_map;
  const struct peridot_pfc_map_out_s *mosi_pfc_map;
  const struct peridot_pfc_map_in_s  *miso_pfc_map;
}
peridot_spi_master_pfc_map;
#endif  /* __PERIDOT_PFC_INTERFACE */

#ifdef PERIDOT_SPI_FLASH_ENABLE
typedef struct peridot_spi_flash_dev_s
{
  alt_flash_dev dev;
  alt_u8 erase_inst;
  alt_u8 four_bytes_mode;
  alt_u16 page_size;
}
peridot_spi_flash_dev;

# define PERIDOT_SPI_MASTER_FLASH_STATE_INSTANCE(name, state) \
  peridot_spi_flash_dev state##_flash
#else
# define PERIDOT_SPI_MASTER_FLASH_STATE_INSTANCE(name, state)
#endif

#define PERIDOT_SPI_MASTER_STATE_INSTANCE(name, state) \
  peridot_spi_master_state state =      \
  {                                     \
    #name,                              \
    name##_BASE,                        \
    name##_FREQ,                        \
    name##_IRQ_INTERRUPT_CONTROLLER_ID, \
    name##_IRQ,                         \
  };                                    \
  PERIDOT_SPI_MASTER_FLASH_STATE_INSTANCE(name, state)

#ifdef PERIDOT_SPI_FLASH_ENABLE
extern void peridot_spi_master_init(peridot_spi_master_state *state, peridot_spi_flash_dev *flash_dev, const char *flash_name);
  # define PERIDOT_SPI_MASTER_STATE_INIT(name, state) \
  peridot_spi_master_init(&state, &state##_flash, name##_NAME "_flash")
#else
extern void peridot_spi_master_init(peridot_spi_master_state *state);
# define PERIDOT_SPI_MASTER_STATE_INIT(name, state) \
  peridot_spi_master_init(&state)
#endif

#ifdef __PERIDOT_PFC_INTERFACE
extern int peridot_spi_master_configure_pins(const peridot_spi_master_pfc_map *map,
                                             alt_u32 sclk, alt_32 mosi, alt_32 miso, int dry_run);
#endif  /* __PERIDOT_PFC_INTERFACE */

#ifdef PERIDOT_SPI_FLASH_ENABLE
extern int peridot_spi_flash_command(alt_u32 write_length, const alt_u8 *write_data,
                                     alt_u32 read_length, alt_u8 *read_data, alt_u32 flags);
#endif

extern int peridot_spi_master_get_clkdiv(peridot_spi_master_state *sp, alt_u32 bitrate, alt_u32 *clkdiv);

#define PERIDOT_SPI_MASTER_FILLER_MSK   (0x00ff)
#define PERIDOT_SPI_MASTER_FILLER_OFST  (0)
#define PERIDOT_SPI_MASTER_MODE_MSK     (0x0300)
#define PERIDOT_SPI_MASTER_MODE_OFST    (8)
#define PERIDOT_SPI_MASTER_MERGE        (0x0400)
#define PERIDOT_SPI_MASTER_LSBFIRST     (0x0800)

extern int peridot_spi_master_transfer(peridot_spi_master_state *sp,
                                       alt_8 slave, alt_u32 clkdiv,
                                       alt_u32 write_length, const alt_u8 *write_data,
                                       alt_u32 read_skip, alt_u32 read_length, alt_u8 *read_data,
                                       alt_u32 flags);

#define PERIDOT_SPI_MASTER_INSTANCE(name, state) \
  PERIDOT_SPI_MASTER_STATE_INSTANCE(name, state)

#define PERIDOT_SPI_MASTER_INIT(name, state) \
  PERIDOT_SPI_MASTER_STATE_INIT(name, state)

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __PERIDOT_SPI_MASTER_H__ */
