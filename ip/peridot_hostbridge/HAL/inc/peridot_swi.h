#ifndef __PERIDOT_SWI_H__
#define __PERIDOT_SWI_H__

#include "alt_types.h"
#include "system.h"

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
  };                                            \

extern void peridot_swi_init(peridot_swi_state *sp,
                             alt_u32 irq_controller_id, alt_u32 irq);

#define PERIDOT_SWI_STATE_INIT(name, state)                   \
  peridot_swi_init(                                           \
    &state,                                                   \
    name##_IRQ_INTERRUPT_CONTROLLER_ID,                       \
    name##_IRQ,                                               \
  )

extern int peridot_swi_set_led(alt_u32 value);
extern int peridot_swi_get_led(alt_u32 *ptr);

extern int peridot_swi_reset_cpu(alt_u32 key);

extern int peridot_swi_set_handler(void (*isr)(void *), void *param);

extern int peridot_swi_write_message(alt_u32 value);
extern int peridot_swi_read_message(alt_u32 *value);

#define PERIDOT_SWI_INSTANCE(name, state) \
  PERIDOT_SWI_STATE_INSTANCE(name, state)

#define PERIDOT_SWI_INIT(name, state) \
  PERIDOT_SWI_STATE_INIT(name, state)

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __PERIDOT_SWI_H__ */
