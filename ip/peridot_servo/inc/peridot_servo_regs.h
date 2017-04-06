#ifndef __PERIDOT_SERVO_REGS_H__
#define __PERIDOT_SERVO_REGS_H__

#include <io.h>

/* Enable register */
#define PERIDOT_SERVO_ENABLE_REG            0
#define IOADDR_PERIDOT_SERVO_ENABLE(base) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SERVO_ENABLE_REG)
#define IORD_PERIDOT_SERVO_ENABLE(base)\
  IORD(base, PERIDOT_SERVO_ENABLE_REG)
#define IOWR_PERIDOT_SERVO_ENABLE(base, data) \
  IOWR(base, PERIDOT_SERVO_ENABLE_REG, data)
#define PERIDOT_SERVO_ENABLE_ENA_MSK        (0x1)
#define PERIDOT_SERVO_ENABLE_ENA_OFST       (0)

/* PWM registers */
#define PERIDOT_SERVO_PWM0_REG              2
#define IOADDR_PERIDOT_SERVO_PWM(base, ch) \
  __IO_CALC_ADDRESS_NATIVE(base, PERIDOT_SERVO_PWM0_REG+(ch))
#define IORD_PERIDOT_SERVO_PWM(base, ch)\
  IORD(base, PERIDOT_SERVO_PWM0_REG+(ch))
#define IOWR_PERIDOT_SERVO_PWM(base, ch, data) \
  IOWR(base, PERIDOT_SERVO_PWM0_REG+(ch), data)
#define PERIDOT_SERVO_PWM_DATA_MSK          (0xff)
#define PERIDOT_SERVO_PWM_DATA_OFST         (0)

#endif /* __PERIDOT_SERVO_REGS_H__ */
