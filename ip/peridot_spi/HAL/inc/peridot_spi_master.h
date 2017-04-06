#ifndef __PERIDOT_SPI_MASTER_H__
#define __PERIDOT_SPI_MASTER_H__

#include "alt_types.h"
#ifdef __tinythreads__
# include <pthread.h>
# include <semaphore.h>
#endif
#include "system.h"

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
#ifdef __PERIDOT_PFC_INTERFACE
  const struct peridot_pfc_map_out_s *ss_n_pfc_map;
  const struct peridot_pfc_map_out_s *sclk_pfc_map;
  const struct peridot_pfc_map_out_s *mosi_pfc_map;
  const struct peridot_pfc_map_in_s  *miso_pfc_map;
#endif  /* __PERIDOT_PFC_INTERFACE */
  alt_8 slave_locked;
#ifdef __tinythreads__
  pthread_mutex_t lock;
  sem_t done;
#else
  volatile alt_u8 lock;
  volatile alt_u8 done;
#endif
}
peridot_spi_master_state;

#define PERIDOT_SPI_MASTER_STATE_INSTANCE_HEADER(name, state, ...) \
  peridot_spi_master_state state =      \
  {                                     \
    #name,                              \
    name##_BASE,                        \
    name##_FREQ,                        \
    name##_IRQ_INTERRUPT_CONTROLLER_ID, \
    name##_IRQ,                         \
    __VA_ARGS__                         \
  }

#ifdef __PERIDOT_PFC_INTERFACE
#define PERIDOT_SPI_MASTER_STATE_INSTANCE(name, state) \
  extern const struct peridot_pfc_map_out_s state##_ss_n_pfc_map;\
  extern const struct peridot_pfc_map_out_s state##_sclk_pfc_map;\
  extern const struct peridot_pfc_map_out_s state##_mosi_pfc_map;\
  extern const struct peridot_pfc_map_in_s  state##_miso_pfc_map;\
  PERIDOT_SPI_MASTER_STATE_INSTANCE_HEADER(name, state,\
    &state##_ss_n_pfc_map,\
    &state##_sclk_pfc_map,\
    &state##_mosi_pfc_map,\
    &state##_miso_pfc_map,\
  )
#else   /* !__PERIDOT_PFC_INTERFACE */
#define PERIDOT_SPI_MASTER_STATE_INSTANCE(name, state) \
  PERIDOT_SPI_MASTER_STATE_INSTANCE_HEADER(name, state)
#endif  /* !__PERIDOT_PFC_INTERFACE */

extern void peridot_spi_master_init(peridot_spi_master_state *state);

#define PERIDOT_SPI_MASTER_STATE_INIT(name, state) \
  peridot_spi_master_init(&state)

#ifdef __PERIDOT_PFC_INTERFACE
extern int peridot_spi_master_configure_pins(peridot_spi_master_state *sp,
                                             alt_u32 sclk, alt_32 mosi, alt_32 miso, int dry_run);
#endif  /* __PERIDOT_PFC_INTERFACE */

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
