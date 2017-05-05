#ifndef __PERIDOT_SWI_H__
#define __PERIDOT_SWI_H__

#include "alt_types.h"
#include "sys/alt_flash_dev.h"

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

typedef struct peridot_swi_flash_dev_s
{
  alt_flash_dev dev;
  alt_u8 erase_inst;
  alt_u8 four_bytes_mode;
  alt_u16 page_size;
}
peridot_swi_flash_dev;

#define PERIDOT_SWI_STATE_INSTANCE(name, state) \
  peridot_swi_state state =                     \
  {                                             \
    name##_BASE,                                \
  };                                            \
  peridot_swi_flash_dev state##_flash[          \
    name##_USE_EPCSBOOT ? 1 : 0                 \
  ]

extern void peridot_swi_init(peridot_swi_state *sp,
                             alt_u32 irq_controller_id, alt_u32 irq,
                             peridot_swi_flash_dev *flash_dev,
                             const char *flash_name);

extern void peridot_swi_flash_init(peridot_swi_flash_dev *dev,
                                   const char *name);

#define PERIDOT_SWI_STATE_INIT(name, state)        \
  peridot_swi_init(                                \
    &state,                                        \
    name##_IRQ_INTERRUPT_CONTROLLER_ID,            \
    name##_IRQ,                                    \
    name##_USE_EPCSBOOT ? state##_flash : 0,       \
    name##_USE_EPCSBOOT ? name##_NAME "_flash" : 0 \
  )

extern int peridot_swi_set_led(alt_u32 value);
extern int peridot_swi_get_led(alt_u32 *ptr);

extern int peridot_swi_reset_cpu(alt_u32 key);

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
