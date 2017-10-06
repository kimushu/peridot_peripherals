#ifndef __PERIDOT_SWI_H__
#define __PERIDOT_SWI_H__

#include "alt_types.h"
#include "system.h"
#include "peridot_spi_flash.h"

#if !defined(PERIDOT_HOSTBRIDGE_USE_EPCSBOOT) || (PERIDOT_HOSTBRIDGE_USE_EPCSBOOT != 0)
# define PERIDOT_SWI_USE_EPCS 1
#else
# if defined(PERIDOT_SWI_FLASH_ENABLE) || defined(PERIDOT_SWI_FLASH_BOOT_ENABLE)
#  error "SPI flash and SPI flast boot feature requires requires peridot_hostbridge with EPCS boot enabled!"
# endif
#endif

#if !defined(PERIDOT_HOSTBRIDGE_USE_MESSAGE) || (PERIDOT_HOSTBRIDGE_USE_MESSAGE != 0)
# define PERIDOT_SWI_USE_MESSAGE 1
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct peridot_swi_state_s
{
  alt_u32 base;
  void (*isr)(void *);
  void *param;
}
peridot_swi_state;

#define PERIDOT_SWI_STATE_INSTANCE(name, state) \
  peridot_swi_state state =                     \
  {                                             \
    name##_BASE,                                \
  }                                             \
  PERIDOT_SPI_FLASH_INSTANCE(name, state)       \
  PERIDOT_SPI_FLASH_BOOT_INSTANCE(name, state)
  
extern void peridot_swi_init(peridot_swi_state *sp,
                             alt_u32 irq_controller_id, alt_u32 irq
                             PERIDOT_SPI_FLASH_INIT_ARGS);

#define PERIDOT_SWI_STATE_INIT(name, state)                   \
  peridot_swi_init(                                           \
    &state,                                                   \
    name##_IRQ_INTERRUPT_CONTROLLER_ID,                       \
    name##_IRQ                                                \
    PERIDOT_SPI_FLASH_INIT_PASS(name, state)                  \
  )

extern int peridot_swi_set_led(alt_u32 value);
extern int peridot_swi_get_led(alt_u32 *ptr);

extern int peridot_swi_reset_cpu(alt_u32 key);

#if (PERIDOT_SWI_USE_EPCS)
extern int peridot_swi_flash_command(alt_u32 write_length, const alt_u8 *write_data,
                                     alt_u32 read_length, alt_u8 *read_data, alt_u32 flags);

# define PERIDOT_SWI_FLASH_MERGE    (0x0400)

#endif  /* PERIDOT_SWI_USE_EPCS */

#if (PERIDOT_SWI_USE_MESSAGE)
extern int peridot_swi_set_handler(void (*isr)(void *), void *param);
extern int peridot_swi_write_message(alt_u32 value);
extern int peridot_swi_read_message(alt_u32 *value);
#endif  /* PERIDOT_SWI_USE_MESSAGE */

#define PERIDOT_SWI_INSTANCE(name, state) \
  PERIDOT_SWI_STATE_INSTANCE(name, state)

#define PERIDOT_SWI_INIT(name, state) \
  PERIDOT_SWI_STATE_INIT(name, state)

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __PERIDOT_SWI_H__ */
