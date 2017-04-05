#ifndef __PERIDOT_SWI_H__
#define __PERIDOT_SWI_H__

#include "alt_types.h"

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
  }

extern void peridot_swi_init(peridot_swi_state *sp,
                             alt_u32 irq_controller_id, alt_u32 irq);

#define PERIDOT_SWI_STATE_INIT(name, state) \
  peridot_swi_init(                         \
    &state,                                 \
    name##_IRQ_INTERRUPT_CONTROLLER_ID,     \
    name##_IRQ                              \
  )

extern int peridot_swi_set_handler(void (*isr)(void *), void *param);

extern int peridot_swi_write_message(alt_u32 value);

extern int peridot_swi_read_message(alt_u32 *value);

#define PERIDOT_SWI_FLASH_COMMAND_MERGE (0x01)

extern int peridot_swi_flash_command(alt_u32 write_length, const alt_u8 *write_data,
                                     alt_u32 read_length, alt_u8 *read_data,
                                     alt_u32 flags);

#define PERIDOT_SWI_INSTANCE(name, state) \
  PERIDOT_SWI_STATE_INSTANCE(name, state)

#define PERIDOT_SWI_INIT(name, state) \
  PERIDOT_SWI_STATE_INIT(name, state)

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __PERIDOT_SWI_H__ */
