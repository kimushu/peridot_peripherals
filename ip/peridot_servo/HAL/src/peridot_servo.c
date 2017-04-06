#include <errno.h>
#include <string.h>
#include "alt_types.h"
#include "peridot_servo.h"
#include "peridot_servo_regs.h"
#include "system.h"
#ifdef __PERIDOT_PFC_INTERFACE
#include "peridot_pfc_interface.h"
#endif  /* __PERIDOT_PFC_INTERFACE */

static peridot_servo_state *servo_sp;

void peridot_servo_init(peridot_servo_state *sp)
{
  servo_sp = sp;
}

int peridot_servo_enable_all(void)
{
  if (!servo_sp)
  {
    return -ENODEV;
  }
  IOWR_PERIDOT_SERVO_ENABLE(servo_sp->base, PERIDOT_SERVO_ENABLE_ENA_MSK);
  return 0;
}

int peridot_servo_disable_all(void)
{
  if (!servo_sp)
  {
    return -ENODEV;
  }
  IOWR_PERIDOT_SERVO_ENABLE(servo_sp->base, 0);
  return 0;
}

#ifdef __PERIDOT_PFC_INTERFACE
static int peridot_servo_configure(const peridot_pfc_map_out_ch *pfc_map,
                                   alt_u32 pin, int dry_run)
{
  if (pin < sizeof(pfc_map->out_funcs))
  {
    alt_8 func = pfc_map->out_funcs[pin];
    if (func >= 0)
    {
      if (!dry_run)
      {
        peridot_pfc_interface_select_output(pin, func);
      }
      return 0;
    }
  }
  return -ENOTSUP;
}

int peridot_servo_configure_pwm(alt_u32 pin, int dry_run)
{
  if (!servo_sp)
  {
    return -ENODEV;
  }
  return peridot_servo_configure(servo_sp->pwm_pfc_map, pin, dry_run);
}

int peridot_servo_configure_dsm(alt_u32 pin, int dry_run)
{
  if (!servo_sp)
  {
    return -ENODEV;
  }
  return peridot_servo_configure(servo_sp->dsm_pfc_map, pin, dry_run);
}
#endif  /* __PERIDOT_PFC_INTERFACE */

int peridot_servo_set_value(alt_u32 pin, alt_u8 value)
{
  alt_8 ch;
  if (!servo_sp)
  {
    return -ENODEV;
  }
  if (pin >= sizeof(servo_sp->pwm_pfc_map->out_channels))
  {
    return -EINVAL;
  }
  ch = servo_sp->pwm_pfc_map->out_channels[pin];
  IOWR_PERIDOT_SERVO_PWM(servo_sp->base, ch,
                         (value << PERIDOT_SERVO_PWM_DATA_OFST) &
                         PERIDOT_SERVO_PWM_DATA_MSK);
  return 0;
}

int peridot_servo_get_value(alt_u32 pin)
{
  alt_u32 ch;
  if (!servo_sp)
  {
    return -ENODEV;
  }
  if (pin >= sizeof(servo_sp->pwm_pfc_map->out_channels))
  {
    return -EINVAL;
  }
  ch = servo_sp->pwm_pfc_map->out_channels[pin];
  return (IORD_PERIDOT_SERVO_PWM(servo_sp->base, ch) &
          PERIDOT_SERVO_PWM_DATA_MSK) >>
         PERIDOT_SERVO_PWM_DATA_OFST;
}

