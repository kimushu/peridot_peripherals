#ifndef __PERIDOT_SERVO_H__
#define __PERIDOT_SERVO_H__

#include "alt_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct peridot_servo_state_s
{
  alt_u32 base;
  const struct peridot_pfc_map_out_ch_s *pwm_pfc_map;
  const struct peridot_pfc_map_out_ch_s *dsm_pfc_map;
}
peridot_servo_state;

#define PERIDOT_SERVO_STATE_INSTANCE(name, state) \
  extern const struct peridot_pfc_map_out_ch_s state##_pwm_pfc_map;\
  extern const struct peridot_pfc_map_out_ch_s state##_dsm_pfc_map;\
  peridot_servo_state state = \
  {                           \
    name##_BASE,              \
    &state##_pwm_pfc_map,     \
    &state##_dsm_pfc_map,     \
  }

extern void peridot_servo_init(peridot_servo_state *state);

#define PERIDOT_SERVO_STATE_INIT(name, state) \
  peridot_servo_init(&state)

extern int peridot_servo_enable_all(void);
extern int peridot_servo_disable_all(void);

extern int peridot_servo_configure_pwm(alt_u32 pin, int dry_run);
extern int peridot_servo_configure_dsm(alt_u32 pin, int dry_run);

extern int peridot_servo_set_value(alt_u32 pin, alt_u8 value);
extern int peridot_servo_get_value(alt_u32 pin);

#define PERIDOT_SERVO_INSTANCE(name, state) \
  PERIDOT_SERVO_STATE_INSTANCE(name, state)

#define PERIDOT_SERVO_INIT(name, state) \
  PERIDOT_SERVO_STATE_INIT(name, state)

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __PERIDOT_SERVO_H__ */
